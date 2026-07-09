// Minimal tool pattern for a Copilot CLI extension.
// Provenance:
// - .github/extensions/notify/extension.mjs
// - copilot-kaizen/extension.mjs
// To use this as the real entry point, rename the file to extension.mjs.

import { joinSession } from "@github/copilot-sdk/extension";

const session = await joinSession({
    tools: [
        {
            name: "echo_text",
            description: "Echo text back to the agent.",
            parameters: {
                type: "object",
                properties: {
                    text: {
                        type: "string",
                        description: "Text to echo.",
                    },
                },
                required: ["text"],
            },
            handler: async (args) => {
                // Example return shape. Confirm the exact SDK result schema in
                // extensions_manage({ operation: "guide" }) before copying it
                // into a production extension.
                if (!args?.text) {
                    return {
                        textResultForLlm: "Missing required field: text.",
                        resultType: "failure",
                    };
                }

                return {
                    textResultForLlm: `Echo: ${args.text}`,
                    resultType: "success",
                };
            },
        },
    ],
});

await session.log("echo_text loaded");
