# notify

> Copilot CLI extension — Windows TTS and system tray notifications.

Exposes two tools that agents can call at the end of long tasks to alert the user without requiring them to watch the screen.

**Platform:** Windows only.

---

## Tools

### `notify_speak(text, language?)`

Reads `text` aloud via Windows SAPI (`System.Speech.Synthesis.SpeechSynthesizer`).

| Parameter | Type   | Required | Description |
|-----------|--------|----------|-------------|
| `text`    | string | ✅       | Text to be spoken (max 500 characters). |
| `language` | string | ❌      | BCP-47 language tag (e.g. `it-IT`, `en-US`, `fr-FR`). Selects the matching SAPI voice. If omitted, the system default voice is used. |

The LLM already knows the language of the text it generates and should always pass `language` explicitly. This is more accurate and more flexible than any heuristic — it supports any installed SAPI voice, not just Italian and English.

### `notify_toast(title, message)`

Shows a balloon notification in the Windows system tray via `System.Windows.Forms.NotifyIcon`. Stays visible for ~5 seconds, then disposes itself.

| Parameter | Type   | Required | Description                      |
|-----------|--------|----------|----------------------------------|
| `title`   | string | ✅       | Notification title.              |
| `message` | string | ✅       | Notification body.               |

---

## Requirements

- **Windows** — uses `System.Speech` and `System.Windows.Forms` (.NET assemblies, built-in on Windows).
- **Node.js ≥ 18** — the extension uses top-level `await` (ESM).
- **`@github/copilot-sdk`** — installed automatically when the extension is loaded by Copilot CLI.
- **SAPI voices** — the default Windows voices (`Microsoft David` for en-US, `Microsoft Zira` for en-US) are always available. For higher-quality output install:
  - **it-IT**: `Microsoft Elsa` (Windows 10/11 natural voice) or any third-party Italian SAPI5 voice.
  - **en-US**: `Microsoft Mark` / `Microsoft Aria` (Windows 11 neural voices).

> Voices can be installed from **Settings → Time & language → Speech → Add voices**.

---

## How it works

All user-supplied values are passed to PowerShell via **environment variables**, never interpolated into the script body. The script template is 100% static — there is no string construction from user input.

```
agent calls notify_speak("Operazione completata!", "it-IT")
  └─► length check: 23 chars ≤ 500 ✓
  └─► language validation: "it-IT" matches /^[a-z]{2,3}-[A-Z]{2,4}$/ ✓
  └─► static PS script → base64-encode → execFile("powershell", ["-EncodedCommand", ...], { timeout: 30000 })
      env: { NOTIFY_TEXT: "Operazione completata!", NOTIFY_LANG: "it-IT" }
  └─► PowerShell reads $env:NOTIFY_LANG → selects Italian SAPI voice
  └─► PowerShell reads $env:NOTIFY_TEXT → speaks the text
```

`execFile` (not `exec`) is used — no shell process, no shell parsing. The 30-second timeout kills any runaway TTS process automatically.

---

## Installation

### How discovery works

Copilot CLI scans for extensions in two locations, in order:

1. **Project-level** — `.github/extensions/<name>/extension.mjs` relative to the git root of the current project. Active only when working inside that repo.
2. **User-level** — `~/.copilot/extensions/<name>/extension.mjs` (macOS/Linux) or `%USERPROFILE%\.copilot\extensions\<name>\extension.mjs` (Windows). Always available regardless of the current project.

### Project-level install

```bash
mkdir -p .github/extensions/notify
cp extension.mjs .github/extensions/notify/
```

Then reload inside a Copilot CLI session (see [Reloading](#reloading)).

### User-level install (global)

Copy `extension.mjs` to the user extensions folder:

```
# Windows
%USERPROFILE%\.copilot\extensions\notify\extension.mjs

# macOS / Linux
~/.copilot/extensions/notify/extension.mjs
```

The extension will be available in every project without any per-repo setup.

### Reloading

Extensions are loaded at session start. To pick up a newly added extension without restarting the terminal:

- Type `/clear` inside an active Copilot CLI session.
- Or exit and restart Copilot CLI.

### Prerequisites

- **Windows** — `notify_speak` and `notify_toast` both depend on Windows-only .NET assemblies (`System.Speech`, `System.Windows.Forms`). The extension loads on other platforms but the tools will fail at runtime.
- **Node.js in PATH** — already required by Copilot CLI itself; no separate install needed.
- **TTS voices** — built-in voices (`Microsoft David`, `Microsoft Zira`) are always present. For better quality, install additional voices from **Settings → Time & Language → Speech → Add voices**.

### Verifying the install

After reloading, the extension injects this context at session start:

> *"L'extension 'notify' è attiva. Hai a disposizione i tool notify_speak e notify_toast per avvisare l'utente al termine di operazioni lunghe."*

To test manually, ask the agent:

```
usa notify_speak per dirmi ciao
```

