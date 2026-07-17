# QA and release checklist

## Real UI matrix

Validate each state in the isolated theme instance:

- Home: character/background present, no chat-only map, cards and composer readable.
- Running: native stop action detected, status marker correct, edge/central motion split matches the design.
- Complete: all transfer pulses stop, completion marker remains visible, no perpetual animation.
- Task switch: root state and composer state change together without a reload.
- Model menu: horizontal overflow hidden, vertical scrolling and keyboard navigation retained.
- Reduced motion: every repeated animation resolves to `none`, static state identity remains.
- Pet overlay: transparent window receives no theme style, background, or decorative SVG.
- Narrow window: text labels may hide, but controls and reading width remain usable.

Use computed styles and DOM counts to verify behavior that a still image cannot prove. Keep QA screenshots outside Git or delete them before publishing.

## Static validation

Run checks proportional to the implementation:

- JavaScript/Node syntax check;
- PowerShell AST parsing for every launcher/install script;
- CSS brace and selector review;
- documentation asset-link check;
- pet manifest/atlas validation when pet files changed;
- `git diff --check`;
- injector error-log size and process/port state.

## Privacy classification

Remove before publishing:

- screenshots or recordings of real Codex tasks;
- clipboard captures and temporary images;
- UI mockups containing account names, project names, task text, terminal output, or local filenames;
- literal user-profile, temp, application-data, or cloud-sync paths;
- logs, state files, cookies, preferences, credentials, tokens, private keys, and environment files;
- personal email addresses, private network addresses, and command histories;
- generated summaries that quote the user's work.

Usually safe after manual review:

- standalone theme art with no UI, account, task, or metadata payload;
- pet spritesheets and manifests with relative paths;
- environment-variable paths such as `%APPDATA%` or `%CODEX_HOME%`;
- generic usage documentation and synthetic examples.

## Repository audit

From the repository root, run:

```powershell
& .\skills\codex-desktop-theme-builder\scripts\audit-theme-repo.ps1
& .\skills\codex-desktop-theme-builder\scripts\audit-theme-repo.ps1 -IncludeHistory
```

The first command evaluates the current working tree. The second also reports risky filenames and sensitive text paths that remain in reachable commits.

Deleting a file in a new commit does not erase its old blob. Report this clearly. Do not rewrite or force-push history as an incidental cleanup step; require a separate, explicit history-sanitization decision and a backup/coordination plan.

## Commit review

Before staging, group changes into:

- theme/injector source;
- launch and audit scripts;
- skill instructions/references;
- safe art or pet assets;
- documentation;
- deletions of private artifacts.

Review added lines for secrets and review binary inclusion by purpose. Stage only the agreed release scope, then verify the remote repository remains private after pushing.
