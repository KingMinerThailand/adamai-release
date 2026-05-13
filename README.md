# AdamAI Release

Public installer for AdamAI local beta.

Install:

```bash
curl -fsSL "https://raw.githubusercontent.com/KingMinerThailand/adamai-release/main/install.sh" | bash
```

SHA-256:

```text
f9ece6e07c2f847b454a6422da53fba9a713c8660a1df9625344d025e2a0c1fb  adamai-local-beta.tgz
```

Release packages are published as GitHub Release assets, not committed to git,
so package size can grow past GitHub's 50 MiB repository warning threshold.
If the archive grows beyond GitHub Release asset limits (currently under 2 GiB
per file), publish it to object storage/CDN instead and run the installer with
`ADAMAI_RELEASE_URL=<package-url>`.
