# AdamAI Release

Public installer for AdamAI local beta.

Install:

```bash
curl -fsSL "https://raw.githubusercontent.com/KingMinerThailand/adamai-release/main/install.sh" | bash
```

SHA-256:

```text
da8a86451d347f4d799d3e5c152a066e349f091a7d1bb74bc59914fba893ad8f  adamai-local-beta.tgz
```

Release packages are published as GitHub Release assets, not committed to git,
so package size can grow past GitHub's 50 MiB repository warning threshold.
If the archive grows beyond GitHub Release asset limits (currently under 2 GiB
per file), publish it to object storage/CDN instead and run the installer with
`ADAMAI_RELEASE_URL=<package-url>`.
