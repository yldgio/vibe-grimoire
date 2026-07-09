// Minimal Copilot CLI extension skeleton.
// Provenance: derived from the installed create-canvas skill's extension shape
// plus loading/debugging patterns used in this repository.
// To use this as the real entry point, rename the file to extension.mjs.

import { joinSession } from "@github/copilot-sdk/extension";

const session = await joinSession({
    tools: [],
    commands: [],
    hooks: {},
});

session.on("session.shutdown", async () => {
    await session.log("my-extension shutting down", { ephemeral: true });
});

await session.log("my-extension loaded");
