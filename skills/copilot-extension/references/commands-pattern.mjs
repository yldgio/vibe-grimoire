// Minimal slash-command pattern for a Copilot CLI extension.
// Provenance:
// - copilot-ledger/extension/extension.mjs
// - copilot-compress/extension.mjs
// To use this as the real entry point, rename the file to extension.mjs.

import { joinSession } from "@github/copilot-sdk/extension";

let session;

async function handleStatusCommand(context) {
    const raw = (context.args ?? "").trim().toLowerCase();

    if (raw === "" || raw === "status") {
        await session.log("Status: ready");
        return;
    }

    await session.log(`Unknown subcommand: ${raw}`);
}

session = await joinSession({
    commands: [
        {
            name: "statusx",
            description: "Example slash command with subcommand parsing.",
            handler: handleStatusCommand,
        },
    ],
});

await session.log("statusx loaded");
