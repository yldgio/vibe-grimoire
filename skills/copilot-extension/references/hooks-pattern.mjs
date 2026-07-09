// Minimal hook pattern for a Copilot CLI extension.
// Provenance:
// - copilot-compress/extension.mjs
// - copilot-kaizen/extension.mjs
// To use this as the real entry point, rename the file to extension.mjs.

import { joinSession } from "@github/copilot-sdk/extension";

let session;

session = await joinSession({
    hooks: {
        onSessionStart: async () => ({
            additionalContext: "This extension is active.",
        }),

        onPreToolUse: async (data) => {
            if (data?.toolName === "target_tool") {
                return { additionalContext: "Be careful with target_tool." };
            }

            return {};
        },

        onPostToolUse: async (data) => {
            // Example return shape. Confirm the exact SDK result schema in
            // extensions_manage({ operation: "guide" }) before copying it
            // into a production extension.
            if (typeof data?.toolResult?.textResultForLlm === "string") {
                return {
                    modifiedResult: {
                        ...data.toolResult,
                        textResultForLlm: data.toolResult.textResultForLlm.trim(),
                    },
                };
            }

            return {};
        },

        onUserPromptSubmitted: async (input) => {
            const prompt = input?.prompt ?? "";
            return { modifiedPrompt: prompt };
        },

        onErrorOccurred: async (data) => {
            const message = typeof data?.error === "string"
                ? data.error
                : data?.error?.message ?? "unknown";
            await session.log(`hook error observed: ${message}`, { level: "warning" });
        },
    },
});

session.on("session.shutdown", async () => {
    await session.log("hook-pattern shutting down", { ephemeral: true });
});

await session.log("hook-pattern loaded");
