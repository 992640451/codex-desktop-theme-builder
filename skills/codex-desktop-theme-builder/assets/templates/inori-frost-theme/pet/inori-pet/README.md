# 凛晶 / Inori Codex Desktop pet

[English](README.md) | [简体中文](README.zh-CN.md)

This directory contains the Codex Desktop pet runtime package and reviewable atlas material.

## Runtime files

- `pet.json`: pet identifier, display name, and atlas path.
- `spritesheet.webp`: transparent 1536×1872 animation atlas with 8 columns, 9 rows, and 192×208 cells.
- `validation.json`: records deterministic atlas validation and final visual-QA status.

## Production material

The pet was rebuilt with the `hatch-pet` workflow from a canonical original-character reference. Nine state strips were generated, extracted with stable slots, validated for alpha residue and atlas dimensions, and reviewed through a contact sheet plus per-state motion previews. Intermediate prompts, generated strips, absolute local paths, and QA media are intentionally omitted from the distributable template.

## Installation

Run `install-inori-pet.cmd` from the template root, or manually copy `pet.json`, `spritesheet.webp`, and `validation.json` to:

```text
%USERPROFILE%\.codex\pets\inori-pet
```

If `CODEX_HOME` is set, use `%CODEX_HOME%\pets\inori-pet` instead.

## Asset notice

The sprites were AI-generated for 凛晶 / Inori, the template's original silver-blue ice-crystal character. The design uses cyan eyes, a centered faceted crystal crown, and a white-blue asymmetric dress, while intentionally avoiding the distinctive color and costume combinations of existing fictional characters.

AI generation is not by itself a guarantee of copyrightability or exclusivity. Any future repository license should state explicitly whether it covers this spritesheet. See the [template asset notice](../../README.md#asset-notice).
