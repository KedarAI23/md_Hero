# Repository structure and migration

## Verified source baseline
The application source currently lives in PR #1, branch `vibe/initial-app-936aa4`, based on commit `27502cf2ed1aa26705a4488c8c9853673daa795d`. It includes `Package.swift`, `Sources/Pare`, `Sources/PareCore`, `Tests/PareTests`, fixture files, scripts and a DMG workflow. PR #1 remains a draft. The 2.0 branch was created from that source commit, preserving the draft branch.

## Target layout
```text
md_Hero/
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── Package.swift
├── Sources/Pare/
├── Sources/PareCore/
├── Tests/PareTests/Fixtures/{pdf,docx,xlsx,pptx,html}/
├── docs/
│   ├── architecture/
│   ├── testing/
│   └── roadmap/
├── scripts/
├── Packaging/
└── .github/
    ├── PULL_REQUEST_TEMPLATE.md
    └── workflows/
```

## Migration sequence
1. Capture branch, commit, package manifest and working-tree state.
2. Preserve existing source branch and PR #1.
3. Create dedicated 2.0 branch from the reviewed source commit.
4. Add architecture, source spec, QA plan and backlog.
5. Establish safe fixture policy.
6. Preserve and improve the existing DMG workflow; do not add a competing workflow until the Swift package layout is verified.
7. Add PR template, contributing guide, security policy and changelog.
8. Keep README accurate: distinguish shipped features from planned features.
9. Tag 2.0 only after acceptance criteria pass.

## Repository hygiene
Do not commit DMGs, app bundles, archives, DerivedData, .build, temporary conversions or user documents. Use synthetic/licensed fixtures only. Never commit credentials or signing material. Separate source, fixtures, generated output and release assets. Keep PRs focused.

## CI
The project already has `.github/workflows/dmg.yml`, which runs `swift test` and packages the app/DMG. Preserve it and improve it rather than adding a second workflow that assumes a different package layout.
