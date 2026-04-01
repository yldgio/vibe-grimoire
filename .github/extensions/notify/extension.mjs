/**
 * notify — Copilot CLI Extension
 *
 * Espone due tool che Olly usa al termine di task lunghi:
 *   • notify_speak(testo)         — legge un testo ad alta voce via Windows TTS
 *   • notify_toast(titolo, msg)   — mostra una notifica balloon di sistema Windows
 *
 * Discovery path: .github/extensions/notify/extension.mjs
 * Docs: @github/copilot-sdk/extension
 */

import { execFile } from "node:child_process";
import { joinSession } from "@github/copilot-sdk/extension";

// ─── helpers ────────────────────────────────────────────────────────────────

/**
 * Esegue uno script PowerShell via -EncodedCommand (base64 UTF-16LE).
 * I dati utente vengono passati come variabili d'ambiente (env), mai interpolati
 * nel corpo dello script → elimina qualsiasi rischio di injection/RCE.
 * Timeout di 30 s per evitare blocchi indefiniti (es. TTS su testo molto lungo).
 */
function runPowerShell(script, env = {}) {
    const encoded = Buffer.from(script, "utf16le").toString("base64");
    return new Promise((resolve) => {
        execFile(
            "powershell",
            ["-NoProfile", "-NonInteractive", "-EncodedCommand", encoded],
            { env: { ...process.env, ...env }, timeout: 30_000 },
            (err, stdout, stderr) => {
                if (err) {
                    // Non esporre stderr raw all'LLM: può contenere path, versioni CLR, stack trace.
                    const msg = err.killed
                        ? "TTS timeout — operation took too long and was terminated."
                        : "PowerShell error — check that Windows TTS / notification assemblies are available.";
                    resolve(`Error: ${msg}`);
                } else {
                    resolve(stdout.trim() || "OK");
                }
            }
        );
    });
}

// ─── session ────────────────────────────────────────────────────────────────

const session = await joinSession({
    tools: [
        // ── 1. TTS ──────────────────────────────────────────────────────────
        {
            name: "notify_speak",
            description:
                "Legge un testo ad alta voce via Windows Text-To-Speech (SAPI). " +
                "Usalo al termine di task lunghi per avvisare l'utente senza che stia guardando lo schermo. " +
                "Passa sempre il parametro 'language' con il tag BCP-47 della lingua del testo (es. 'it-IT', 'en-US').",
            parameters: {
                type: "object",
                properties: {
                    text: {
                        type: "string",
                        description: "Il testo da leggere ad alta voce (max 500 caratteri).",
                    },
                    language: {
                        type: "string",
                        description:
                            "Tag BCP-47 della lingua del testo, es. 'it-IT', 'en-US', 'fr-FR'. " +
                            "Determina quale voce SAPI viene selezionata. Se omesso, viene usata la voce predefinita del sistema.",
                    },
                },
                required: ["text"],
            },
            handler: async (args) => {
                if (String(args.text).length > 500) {
                    return { textResultForLlm: "Testo troppo lungo (max 500 caratteri).", resultType: "failure" };
                }
                // Valida il tag lingua: accetta solo BCP-47 nel formato xx-XX (es. it-IT, en-US).
                const lang = args.language ?? "";
                if (lang && !/^[a-z]{2,3}-[A-Z]{2,4}$/.test(lang)) {
                    return { textResultForLlm: `Lingua non valida: '${lang}'. Usa un tag BCP-47 (es. 'it-IT', 'en-US').`, resultType: "failure" };
                }
                // SICURO: corpo dello script completamente statico.
                // NOTIFY_TEXT e NOTIFY_LANG passano come env var — mai interpolati nel body.
                const script = `
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
if ($env:NOTIFY_LANG) {
    try { $synth.SelectVoiceByHints([System.Speech.Synthesis.VoiceGender]::NotSet, [System.Speech.Synthesis.VoiceAge]::NotSet, 0, [System.Globalization.CultureInfo]::new($env:NOTIFY_LANG)) } catch {}
}
$synth.Speak($env:NOTIFY_TEXT)
$synth.Dispose()
`.trim();

                const result = await runPowerShell(script, { NOTIFY_TEXT: args.text, NOTIFY_LANG: lang });
                await session.log(`🔊 TTS [${lang || "default"}]: "${args.text}"`);
                return result.startsWith("Error:")
                    ? { textResultForLlm: result, resultType: "failure" }
                    : { textResultForLlm: `Detto ad alta voce: "${args.text}"`, resultType: "success" };
            },
        },

        // ── 2. Toast notification ────────────────────────────────────────────
        {
            name: "notify_toast",
            description:
                "Mostra una notifica balloon (system tray) su Windows. " +
                "Usala al termine di task lunghi per attirare l'attenzione dell'utente.",
            parameters: {
                type: "object",
                properties: {
                    title: {
                        type: "string",
                        description: "Titolo della notifica (es. 'Task completato').",
                    },
                    message: {
                        type: "string",
                        description: "Corpo della notifica (es. 'Il build è terminato con successo').",
                    },
                },
                required: ["title", "message"],
            },
            handler: async (args) => {
                if (String(args.title).length > 100) {
                    return { textResultForLlm: "Titolo troppo lungo (max 100 caratteri).", resultType: "failure" };
                }
                if (String(args.message).length > 100) {
                    return { textResultForLlm: "Messaggio troppo lungo (max 100 caratteri).", resultType: "failure" };
                }
                // SICURO: corpo dello script completamente statico.
                // NOTIFY_TITLE e NOTIFY_MESSAGE passano come env var — mai interpolati nel body.
                const script = `
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Icon    = [System.Drawing.SystemIcons]::Information
$notify.Visible = $true
$notify.ShowBalloonTip(5000, $env:NOTIFY_TITLE, $env:NOTIFY_MESSAGE, [System.Windows.Forms.ToolTipIcon]::Info)
Start-Sleep -Seconds 2
$notify.Dispose()
`.trim();

                const result = await runPowerShell(script, { NOTIFY_TITLE: args.title, NOTIFY_MESSAGE: args.message });
                await session.log(`🔔 Notifica: "${args.title}" — ${args.message}`);
                return result.startsWith("Error:")
                    ? { textResultForLlm: result, resultType: "failure" }
                    : { textResultForLlm: `Notifica mostrata: "${args.title}"`, resultType: "success" };
            },
        },
    ],

    hooks: {
        onSessionStart: async () => ({
            additionalContext:
                "L'extension 'notify' è attiva. " +
                "Hai a disposizione i tool notify_speak(text, language?) e notify_toast(title, message) " +
                "per avvisare l'utente al termine di operazioni lunghe. " +
                "Per notify_speak, passa sempre il parametro 'language' con il tag BCP-47 della lingua (es. 'it-IT', 'en-US').",
        }),
    },
});

await session.log("✅ Extension notify caricata (speak + toast)");
