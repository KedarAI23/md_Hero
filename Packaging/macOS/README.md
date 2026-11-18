# macOS packaging

The current packaging scripts are in `scripts/make_app.sh` and `scripts/make_dmg.sh`. Keep one authoritative packaging path.

Before a public 2.0 release:
- Set version/build numbers from one source of truth.
- Use a Developer ID signature where distribution outside a controlled beta requires it.
- Notarise and staple the distributable app/DMG.
- Verify Gatekeeper installation on a clean macOS account.
- Ensure no test fixtures or conversion artefacts are included in the app bundle.
- Record supported macOS and processor architectures.

Ad-hoc signing is suitable for development tests but should not be represented as notarised distribution.
