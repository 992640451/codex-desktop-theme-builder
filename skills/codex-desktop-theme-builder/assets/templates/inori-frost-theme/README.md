# Inori Frost theme template

[English](README.md) | [简体中文](README.zh-CN.md)

This directory is a worked example bundled with the `codex-desktop-theme-builder` Skill. It is not the main subject of the repository.

The template demonstrates a pale-blue ice-crystal theme with a home-only character background, a star-field relay canvas, distinct running/completed task states, isolated launch/stop scripts, a shortcut creator, and an optional pet package.

## Use as a template

1. Copy this entire directory to a separate project.
2. Replace the artwork and rename the example-specific IDs, classes, labels, filenames, profile names, and package names when creating a different theme.
3. Inspect the current Codex DOM before relying on any bundled selector.
4. Keep runtime paths relative to the copied project.
5. Validate home, running, completed, task switching, menus, reduced motion, narrow layout, and pet transparency.
6. Run the Skill privacy audit before staging or publishing.

Do not edit or run the copy stored inside an installed Skill.

## Example controls

On Windows, run `start-inori-theme.cmd` to launch the isolated themed instance and `stop-inori-theme.cmd` to stop it. The launcher discovers the installed Codex app at runtime and keeps theme state outside this directory.

Optional helpers:

- `create-inori-shortcut.cmd` creates a Windows shortcut using the installed Codex application icon.
- `install-inori-pet.cmd` installs the example pet package independently from the main theme.

These scripts are examples to rename and review, not fixed public APIs.

## Architecture notes

- `theme.css` contains the visual token overrides and state styles.
- `injector.mjs` owns versioned styles, task-state markers, the decorative signal map, and pet-overlay cleanup.
- `assets/inori-original-crystal-hero.png` is the home background for the original character 凛晶 / Inori.
- `pet/inori-pet/` contains the optional pet manifest and spritesheets.

The injector must never style the `avatar-overlay` target. Decorative layers use `pointer-events: none`, and repeated motion is disabled under `prefers-reduced-motion: reduce`.

## Original character contract

凛晶 / Inori is the original character created for this template. Keep the defining system consistent across the home art and pet: silver-blue long hair, cyan eyes, a centered faceted crystal crown, a white and ice-blue asymmetric layered dress, and a snow-crystal chest core. Do not reintroduce pink hair, red eyes, red-black stage clothing, or side hair clips when extending the example.

## Asset notice

The bitmap assets were generated with AI tools for 凛晶 / Inori, an original silver-blue ice-crystal character created for this template. “Inori” in this package refers only to that original character.

The design intentionally avoids pink hair, red eyes, red-black stage clothing, side hair clips, and other distinctive combinations associated with existing fictional characters. AI generation is not itself a guarantee of copyrightability or exclusivity, so any future license should state its coverage of these assets explicitly.

See the [repository licensing and asset boundary](../../../../../README.md#licensing-and-asset-boundary).

No real Codex UI screenshots are included in this template.
