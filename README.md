# Codex Desktop Theme Builder

[English](README.md) | [简体中文](README.zh-CN.md)

A reusable Skill for designing, implementing, validating, and safely releasing custom Codex Desktop themes.

This repository is centered on the `codex-desktop-theme-builder` Skill. It teaches Codex how to build reversible themes around an isolated desktop instance, verify real conversation states, keep auxiliary windows transparent, and remove private artifacts before release.

## What is included

- A reusable Codex Skill with implementation and release guidance.
- A deterministic repository privacy-audit script.
- An original-character Inori Frost theme bundled only as a worked template example.
- No real Codex screenshots, task transcripts, logs, credentials, or local profile paths.

## Repository layout

```text
skills/codex-desktop-theme-builder/
├── SKILL.md
├── agents/openai.yaml
├── references/
├── scripts/audit-theme-repo.ps1
└── assets/templates/inori-frost-theme/
```

The repository subject is the Skill. The Inori Frost package under `assets/templates/` demonstrates one implementation with the original character 凛晶 / Inori and is not the repository's primary product.

## Install the Skill

Clone the repository, then copy `skills/codex-desktop-theme-builder` into the `skills` directory under your Codex home. If `CODEX_HOME` is not set, Codex commonly uses `.codex` under the current user profile.

Restart Codex after installation. Invoke the Skill with a request such as:

```text
Use $codex-desktop-theme-builder to design and validate a reversible Codex Desktop theme.
```

When using the bundled example, copy the entire `inori-frost-theme` template to a separate working directory before editing or running it. Do not modify the installed Skill in place.

## Safety model

The workflow does not patch the signed Codex installation. A theme is launched with an isolated user-data directory and applied through a separate runtime injector. The Skill requires semantic DOM inspection, idempotent ownership, reduced-motion support, task-state validation, and explicit pet-overlay isolation.

Before publishing a derived theme, run:

```powershell
& .\skills\codex-desktop-theme-builder\scripts\audit-theme-repo.ps1 -FailOnFinding
& .\skills\codex-desktop-theme-builder\scripts\audit-theme-repo.ps1 -IncludeHistory -FailOnFinding
```

## Privacy and public-release status

This repository was initialized from a clean Git history. Real UI captures and the earlier theme repository history were intentionally not imported.

No open-source license has been selected yet. Until a license is added, default copyright rules apply; source availability alone does not grant permission to reuse, modify, or redistribute the project.

## Licensing and asset boundary

The repository contains two different rights categories:

- Skill instructions, scripts, and theme source code written for this project.
- AI-generated visual assets for the original ice-crystal character 凛晶 / Inori, created for this template.

In this repository, “Inori” refers only to this original silver-blue ice-crystal character. The current artwork intentionally avoids the names, costume, color combination, and other distinctive expression of existing fictional characters.

AI generation describes how an image was produced; it is not by itself a guarantee of copyrightability, exclusivity, or freedom from all third-party claims. Any future software license should state whether it covers the visual assets. Until a repository and asset license is added, default copyright rules apply to both code and artwork.

This notice describes the project's intended rights boundary and is not legal advice.

## Documentation languages

User-facing repository and template guides are available in English and Simplified Chinese. `SKILL.md` and its agent-facing references remain a single canonical English instruction set to prevent behavioral drift between duplicated Skill definitions.
