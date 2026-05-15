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
66d54521507f74b5787e7bf2899e5925251b240553ca08082aeb2679017927ff  adamai-local-beta.tgz
```

The Start Agent page checks the latest release asset and shows a status banner.
If an update is available, users should open Terminal and run `adamai update`.
After updating, the banner turns green and reports the installed version as
current.

This public repository contains only installer files. AdamAI runtime packages are
published as GitHub Release assets, not committed to git, so package size can
grow past GitHub's 50 MiB repository warning threshold.

The packaged runtime is protected after install with an Ed25519-signed integrity
manifest. If a protected file is edited, `adamai doctor` / `adamai start` will
fail and `adamai update` will restore the official release package.

If the archive grows beyond GitHub Release asset limits (currently under 2 GiB
per file), publish it to object storage/CDN instead and run the installer with
`ADAMAI_RELEASE_URL=<package-url>`.
