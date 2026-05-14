# AdamAI Release

Public installer for AdamAI local beta.

Recommended install:

```bash
npm install -g adamai-cli
adamai install
```

Direct installer:

```bash
curl -fsSL "https://raw.githubusercontent.com/KingMinerThailand/adamai-release/main/install.sh" | bash
```

SHA-256:

```text
32cb134afd3b90a8c33bc8292532356a1731ef044388cdbcd13221e4df296d99  adamai-local-beta.tgz
```

This public repository contains only installer files. AdamAI runtime packages are
published as GitHub Release assets, not committed to git, so package size can
grow past GitHub's 50 MiB repository warning threshold.

The packaged runtime is protected after install with an integrity manifest. If a
protected file is edited, `adamai doctor` / `adamai start` will fail and
`adamai update` will restore the official release package.

If the archive grows beyond GitHub Release asset limits (currently under 2 GiB
per file), publish it to object storage/CDN instead and run the installer with
`ADAMAI_RELEASE_URL=<package-url>`.
