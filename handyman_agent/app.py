"""Handyman Agent: a Windows window that edits the Flutter app and builds an APK."""

from __future__ import annotations

import os
import queue
import shutil
import subprocess
import sys
import threading
import time
import tkinter as tk
from datetime import datetime
from pathlib import Path
from tkinter import messagebox, ttk

APP_DIR = Path(__file__).resolve().parent
FLUTTER_ROOT = APP_DIR.parent
APK_DIR = APP_DIR / "apks"
ENV_FILE = APP_DIR / ".env"
SOURCE_APK = FLUTTER_ROOT / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"

INK = "#1B1B1F"
INK_SOFT = "#2B2B31"
CANVAS = "#F7F6F2"
AMBER = "#F5B21B"
AMBER_DEEP = "#D99100"
MUTED = "#6F6B63"
WHITE = "#FFFFFF"
DANGER = "#D64545"


def load_env_file(path: Path) -> None:
    if not path.is_file():
        return
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


def save_api_key(key: str) -> None:
    os.environ["CURSOR_API_KEY"] = key
    lines: list[str] = []
    if ENV_FILE.is_file():
        lines = [
            line
            for line in ENV_FILE.read_text(encoding="utf-8").splitlines()
            if not line.strip().startswith("CURSOR_API_KEY=")
        ]
    lines.append(f"CURSOR_API_KEY={key}")
    ENV_FILE.write_text("\n".join(lines) + "\n", encoding="utf-8")


def flutter_executable() -> str:
    props = FLUTTER_ROOT / "android" / "local.properties"
    if props.is_file():
        for raw in props.read_text(encoding="utf-8").splitlines():
            if raw.startswith("flutter.sdk="):
                sdk = raw.split("=", 1)[1].strip().replace("\\\\", "\\")
                bat = Path(sdk) / "bin" / "flutter.bat"
                if bat.is_file():
                    return str(bat)
    found = shutil.which("flutter")
    return found or "flutter"


def install_windows_bridge_fix() -> None:
    """Windows select() only accepts sockets, and the SDK watches a pipe."""
    if sys.platform != "win32":
        return
    import cursor_sdk._bridge as bridge

    def _read_discovery(process: subprocess.Popen[str], timeout: float):
        if process.stderr is None:
            raise bridge.CursorSDKError("Bridge process stderr is unavailable")
        lines: queue.Queue[str | None] = queue.Queue()

        def _reader() -> None:
            try:
                assert process.stderr is not None
                for line in process.stderr:
                    lines.put(line)
            finally:
                lines.put(None)

        threading.Thread(target=_reader, daemon=True).start()
        stderr_lines: list[str] = []
        deadline = time.monotonic() + timeout
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise bridge.CursorSDKError("Timed out waiting for bridge discovery")
            try:
                line = lines.get(timeout=min(0.2, remaining))
            except queue.Empty:
                exit_code = process.poll()
                if exit_code is not None:
                    raise bridge.CursorSDKError(
                        "Bridge exited before discovery with status "
                        f"{exit_code}: " + "".join(stderr_lines)
                    )
                continue
            if line is None:
                exit_code = process.poll()
                raise bridge.CursorSDKError(
                    "Bridge exited before discovery with status "
                    f"{exit_code}: " + "".join(stderr_lines)
                )
            stderr_lines.append(line)
            discovery = bridge.parse_discovery_line(line)
            if discovery is not None:
                return discovery

    bridge._read_discovery = _read_discovery


def agent_instructions(request: str) -> str:
    return (
        "You edit the HandyMan Flutter customer app in this folder.\n"
        "Apply the team request below. Keep the existing app structure and visual language.\n"
        "Do not run flutter build, gradle, or produce an APK. "
        "The Handyman Agent window builds the APK after you finish.\n"
        "When you are done, reply with a short summary of what changed.\n\n"
        f"Team request:\n{request.strip()}\n"
    )


class HandymanAgentApp:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.events: queue.Queue[tuple[str, str]] = queue.Queue()
        self.busy = False
        self.latest_apk: Path | None = None
        APK_DIR.mkdir(parents=True, exist_ok=True)
        load_env_file(ENV_FILE)
        self._build()
        self._refresh_apks()
        self.root.after(100, self._drain)

    def _build(self) -> None:
        self.root.title("Handyman Agent")
        self.root.geometry("920x720")
        self.root.minsize(760, 620)
        self.root.configure(bg=CANVAS)

        header = tk.Frame(self.root, bg=INK, padx=28, pady=22)
        header.pack(fill="x")
        tk.Label(
            header,
            text="Handyman Agent",
            bg=INK,
            fg=AMBER,
            font=("Segoe UI", 26, "bold"),
        ).pack(anchor="w")
        tk.Label(
            header,
            text="Write what should change. Submit updates the app and builds an APK.",
            bg=INK,
            fg="#E6E1D6",
            font=("Segoe UI", 11),
        ).pack(anchor="w", pady=(6, 0))

        body = tk.Frame(self.root, bg=CANVAS, padx=28, pady=18)
        body.pack(fill="both", expand=True)

        key_row = tk.Frame(body, bg=CANVAS)
        key_row.pack(fill="x")
        tk.Label(key_row, text="Cursor API key", bg=CANVAS, fg=MUTED, font=("Segoe UI", 10)).pack(side="left")
        self.key_var = tk.StringVar(value=os.environ.get("CURSOR_API_KEY", ""))
        self.key_entry = tk.Entry(
            key_row,
            textvariable=self.key_var,
            show="•",
            font=("Segoe UI", 11),
            relief="flat",
            bg=WHITE,
        )
        self.key_entry.pack(side="left", fill="x", expand=True, padx=(12, 8), ipady=6)
        self._button(key_row, "Save key", self._save_key).pack(side="left")

        tk.Label(body, text="Prompt", bg=CANVAS, fg=INK, font=("Segoe UI", 12, "bold")).pack(anchor="w", pady=(16, 6))
        prompt_wrap = tk.Frame(body, bg=WHITE, highlightbackground="#E4DFD4", highlightthickness=1)
        prompt_wrap.pack(fill="x")
        self.prompt = tk.Text(
            prompt_wrap,
            height=6,
            wrap="word",
            font=("Segoe UI", 12),
            relief="flat",
            bg=WHITE,
            fg=INK,
            padx=12,
            pady=10,
        )
        self.prompt.pack(fill="x")

        actions = tk.Frame(body, bg=CANVAS)
        actions.pack(fill="x", pady=(12, 0))
        self.submit = self._button(actions, "Submit", self._submit, primary=True)
        self.submit.pack(side="left")
        self.open_btn = self._button(actions, "Open APK", self._open_apk)
        self.open_btn.pack(side="left", padx=(10, 0))
        self.open_btn.configure(state="disabled")
        self.status = tk.Label(actions, text="Ready", bg=CANVAS, fg=MUTED, font=("Segoe UI", 10))
        self.status.pack(side="left", padx=(16, 0))

        tk.Label(body, text="Activity", bg=CANVAS, fg=INK, font=("Segoe UI", 12, "bold")).pack(anchor="w", pady=(18, 6))
        log_wrap = tk.Frame(body, bg=INK_SOFT)
        log_wrap.pack(fill="both", expand=True)
        self.log = tk.Text(
            log_wrap,
            height=10,
            wrap="word",
            font=("Consolas", 10),
            relief="flat",
            bg=INK_SOFT,
            fg="#F3EFE6",
            padx=12,
            pady=10,
            state="disabled",
        )
        self.log.pack(fill="both", expand=True)

        tk.Label(body, text="APKs", bg=CANVAS, fg=INK, font=("Segoe UI", 12, "bold")).pack(anchor="w", pady=(14, 6))
        self.apk_list = tk.Listbox(
            body,
            height=4,
            font=("Segoe UI", 10),
            relief="flat",
            bg=WHITE,
            fg=INK,
            selectbackground=AMBER,
            selectforeground=INK,
            activestyle="none",
            highlightthickness=1,
            highlightbackground="#E4DFD4",
        )
        self.apk_list.pack(fill="x")
        self.apk_list.bind("<<ListboxSelect>>", self._select_apk)

    def _button(self, parent: tk.Widget, text: str, command, primary: bool = False) -> tk.Button:
        bg = AMBER if primary else INK
        fg = INK if primary else WHITE
        active = AMBER_DEEP if primary else INK_SOFT
        return tk.Button(
            parent,
            text=text,
            command=command,
            bg=bg,
            fg=fg,
            activebackground=active,
            activeforeground=fg,
            relief="flat",
            font=("Segoe UI", 11, "bold"),
            padx=16,
            pady=8,
            cursor="hand2",
        )

    def _save_key(self) -> None:
        key = self.key_var.get().strip()
        if not key:
            messagebox.showwarning("Handyman Agent", "Paste a Cursor API key first.")
            return
        save_api_key(key)
        self._set_status("API key saved on this PC.")

    def _submit(self) -> None:
        if self.busy:
            return
        request = self.prompt.get("1.0", "end").strip()
        if not request:
            messagebox.showwarning("Handyman Agent", "Write a prompt first.")
            return
        key = self.key_var.get().strip() or os.environ.get("CURSOR_API_KEY", "").strip()
        if not key:
            messagebox.showwarning(
                "Handyman Agent",
                "Add a Cursor API key. Create one under Cursor Dashboard, Integrations.",
            )
            return
        save_api_key(key)
        self.busy = True
        self.submit.configure(state="disabled")
        self._set_status("Sending the prompt…")
        self._append("\n---\n")
        threading.Thread(target=self._run, args=(request, key), daemon=True).start()

    def _run(self, request: str, api_key: str) -> None:
        try:
            install_windows_bridge_fix()
            from cursor_sdk import (
                Agent,
                CursorAgentError,
                LocalAgentOptions,
                SDKAssistantMessage,
                SDKStatusMessage,
                SDKToolUseMessage,
                TextBlock,
            )
        except Exception as exc:
            self._fail(f"Cursor SDK is not available: {exc}")
            return

        try:
            with Agent.create(
                model="composer-2.5",
                api_key=api_key,
                name="Handyman Agent",
                local=LocalAgentOptions(
                    cwd=str(FLUTTER_ROOT),
                    setting_sources=["project"],
                    auto_review=True,
                ),
            ) as agent:
                run = agent.send(agent_instructions(request))
                self._post("status", "The agent is updating the app…")
                self._post("log", f"Run {run.id}\n")
                for message in run.messages():
                    if isinstance(message, SDKAssistantMessage):
                        for block in message.message.content:
                            if isinstance(block, TextBlock) and block.text:
                                self._post("log", block.text)
                    elif isinstance(message, SDKToolUseMessage) and message.status == "running":
                        self._post("log", f"\nWorking: {message.name}\n")
                    elif isinstance(message, SDKStatusMessage) and message.message:
                        self._post("status", message.message)
                result = run.wait()
        except CursorAgentError as exc:
            self._fail(f"Could not start the agent: {exc.message}")
            return
        except Exception as exc:
            self._fail(f"The agent stopped: {exc}")
            return

        if result.status == "error":
            detail = result.error_message or result.result or result.id
            self._fail(f"The agent run failed ({result.id}): {detail}")
            return

        self._post("log", "\n")
        if result.result:
            self._post("log", result.result.strip() + "\n")
        self._post("status", "Building the APK…")
        self._post("log", "Building the release APK. This can take several minutes.\n")
        built = self._build_apk()
        if built is None:
            self._done("The app was updated, but the APK build failed.")
            return
        self._post("apk", str(built))
        self._done(f"APK ready: {built.name}")

    def _build_apk(self) -> Path | None:
        flutter = flutter_executable()
        process = subprocess.Popen(
            [flutter, "build", "apk", "--release"],
            cwd=FLUTTER_ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        assert process.stdout is not None
        for line in process.stdout:
            text = line.rstrip()
            if text:
                self._post("log", text + "\n")
        code = process.wait()
        if code != 0 or not SOURCE_APK.is_file():
            self._post("log", f"APK build failed (exit {code}).\n")
            return None
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        dest = APK_DIR / f"handyman-{stamp}.apk"
        shutil.copy2(SOURCE_APK, dest)
        return dest

    def _post(self, kind: str, text: str) -> None:
        self.events.put((kind, text))

    def _fail(self, text: str) -> None:
        self._post("log", text + "\n")
        self._done(text)

    def _done(self, status: str) -> None:
        self._post("status", status)
        self._post("idle", "")

    def _drain(self) -> None:
        while True:
            try:
                kind, text = self.events.get_nowait()
            except queue.Empty:
                break
            if kind == "log":
                self._append(text)
            elif kind == "status":
                self._set_status(text)
            elif kind == "apk":
                self.latest_apk = Path(text)
                self._refresh_apks()
                self.open_btn.configure(state="normal")
            elif kind == "idle":
                self.busy = False
                self.submit.configure(state="normal")
        self.root.after(100, self._drain)

    def _append(self, text: str) -> None:
        self.log.configure(state="normal")
        self.log.insert("end", text)
        self.log.see("end")
        self.log.configure(state="disabled")

    def _set_status(self, text: str) -> None:
        color = DANGER if "fail" in text.lower() or "could not" in text.lower() else MUTED
        self.status.configure(text=text, fg=color)

    def _refresh_apks(self) -> None:
        files = sorted(APK_DIR.glob("*.apk"), key=lambda path: path.stat().st_mtime, reverse=True)
        self.apk_list.delete(0, "end")
        for path in files:
            self.apk_list.insert("end", path.name)
        if files:
            self.latest_apk = files[0]
            self.apk_list.selection_set(0)
            self.open_btn.configure(state="normal")

    def _select_apk(self, _event=None) -> None:
        selection = self.apk_list.curselection()
        if not selection:
            return
        name = self.apk_list.get(selection[0])
        self.latest_apk = APK_DIR / name
        self.open_btn.configure(state="normal")

    def _open_apk(self) -> None:
        if self.latest_apk is None or not self.latest_apk.is_file():
            return
        os.startfile(self.latest_apk.parent)  # noqa: S606 - open the folder the user just built


def main() -> None:
    root = tk.Tk()
    try:
        root.tk.call("tk", "scaling", 1.25)
    except tk.TclError:
        pass
    style = ttk.Style(root)
    if "vista" in style.theme_names():
        style.theme_use("vista")
    HandymanAgentApp(root)
    if "--self-check" in sys.argv:
        root.update_idletasks()
        print("SELF_CHECK_OK")
        root.destroy()
        raise SystemExit(0)
    root.mainloop()


if __name__ == "__main__":
    main()
