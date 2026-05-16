# AdamAI Release

Public installer for AdamAI local beta.

Recommended install when Node.js/npm is already installed:

```bash
npm install -g adamai-cli
adamai install
adamai start
```

Bootstrap install for users without Node.js/npm:

```bash
curl -fsSL "https://raw.githubusercontent.com/KingMinerThailand/adamai-release/main/install.sh" | bash
```

Windows PowerShell:

```powershell
irm "https://raw.githubusercontent.com/KingMinerThailand/adamai-release/main/install.ps1" | iex
```

The bootstrap installers install portable Node.js 24 LTS under the user's home
folder when Node.js 18+ and npm are not already available.

SHA-256:

```text
86bf95fa79f854bab5db06bae746acf8ed7445a088abe2cdd360982141298e54  adamai-local-beta.tgz
```

The Start Agent page checks the latest release asset and shows a status banner.
If an update is available, users should open Terminal and run `adamai update`.
After updating, the banner turns green and reports the installed version as
current.

Start Agent now opens at the hub root (`/`), an AdamAI-native prompt-to-artifact
home inspired by OpenDesign and Claude-style composer patterns. The root URL is
always the primary entry, including strict auth mode. `/adamai.html` remains
available as a compatibility URL.

Anonymous strict-auth sessions now see login-required live dispatch badges
without protected API console noise. After login, the same page connects to the
live AdamAI agent APIs for planning, tool context, and cascade dispatch.

Live cascade monitoring fixes discovered from the root workspace are included:
WorkspaceWrite agents auto-run only allowlisted tools, while DangerFullAccess
still requires explicit autonomous mode before bypassing prompts. ReportWatch
now waits for boss terminals to be idle before sending report notifications, so
status updates do not interrupt active Claude/Codex tool calls.

The legacy AdamAI side menu has moved into the prompt workspace itself. It starts
collapsed by default, expands in-place when needed, includes Navigate, Account,
and Utility entries, and keeps the legacy dashboard available through
`/index.html`.

AdamAI shared navigation now points Start Agent links to `/`, and the shared
layout colors match the prompt workspace dark theme: warm dark background,
AdamAI orange accent, muted parchment text, and dark as the default theme.

The page does not require `projects/opendesign` at runtime: it plans through
`/api/agent-packs/plan`, loads agent tool context, and dispatches through
AdamAI Cascade.

The prompt-to-artifact flow builds a run packet with owner, deliverable,
checkpoint, preferred Claude/Codex CLI guidance, target artifact workspace,
briefing/worktree rules, and memory/report expectations before starting work.

After dispatch, `/adamai.html` now switches into an AdamAI artifact workspace:
left-side conversation with user prompt, Adam working status, checkpoint
question, and reply composer; right-side Design Files canvas with ownership,
deliverable, briefing, worktree/file-scope cards, and drop-zone context.

Start Agent planning now applies a Smart Agent Budget before dispatch. AdamAI
keeps the full candidate team as standby context, but launches only the active
budget for the job size. Small web/design briefs now stay focused, for example
`product_mgr` + `uxlab`, while larger cross-system work can escalate to a
larger capped team when a blocker or review trigger appears.

The organization dispatch flow now validates the full 192-agent management
graph, routes Gaming work through the registry-defined `worldbuild` entry point,
and attaches coordination briefings/worktree isolation to multi-agent cascades.

AdamAI Hub now includes an OpenDesign project bridge at `/opendesign.html` and
`/api/opendesign/*`. When the local project exists at `projects/opendesign`,
AdamAI can install dependencies, start, stop, restart, inspect status, and embed
the OpenDesign web app while keeping the OpenDesign runtime under the AdamAI
namespace.

The OpenDesign control page now keeps the embedded iframe stable during status
polling by normalizing iframe URLs before comparison and avoiding unnecessary
log rewrites during background refreshes.

The OpenDesign control page now credits the upstream project as "Open Design by
nexu-io" and links to the Apache-2.0 license.

The Start Agent planner now recognizes game DevOps/CI readiness prompts as a
Gaming workflow. Adam selects CTO -> Game Director -> Technical Director ->
specialist/QA as the team, but dispatches the first runnable target to
`worldbuild` so the cascade follows the management chain instead of fanning out
directly to specialists.

This public repository contains only installer files. AdamAI runtime packages are
published as GitHub Release assets, not committed to git, so package size can
grow past GitHub's 50 MiB repository warning threshold.

The packaged runtime is protected after install with an Ed25519-signed integrity
manifest. If a protected file is edited, `adamai doctor` / `adamai start` will
fail and `adamai update` will restore the official release package.

If the archive grows beyond GitHub Release asset limits (currently under 2 GiB
per file), publish it to object storage/CDN instead and run the installer with
`ADAMAI_RELEASE_URL=<package-url>`.
