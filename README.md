# SkillSuite

A macOS menu bar app that indexes and browses AI instruction files across your machine and projects — Claude, Copilot, Codex, and Gemini, all in one place.

---

## Why It Exists

Every major AI coding tool stores its instructions and prompts differently: Claude uses `CLAUDE.md` and `.claude/` directories, Copilot uses `.github/copilot-instructions.md`, Codex and Gemini have their own conventions. When you work across multiple projects and multiple tools, finding the right file means digging through the filesystem manually or remembering which project has what.

SkillSuite sits in your menu bar and gives you instant, searchable access to every AI instruction file on your machine — both the global provider files and the project-specific ones in any codebase you register.

---

## What It Does

- **Indexes global provider files** from standardized system paths for Claude, Copilot, Codex, and Gemini
- **Scans registered codebases** for provider-specific instruction files in each project
- **Full-text search** across file names and file contents
- **Live file watching** via FSEvents — detects new or changed files and highlights them in the UI
- **Two-panel reader** — sidebar for navigation, content pane to read files in place
- **Menu bar only** — no dock icon, no app switcher clutter

---

## Requirements

> **macOS 26.0 or later is required.** This is a hard constraint — the app will not run on earlier versions.

- macOS 26.0+
- Swift 6.2+ (ships with Xcode 26 or via [swift.org](https://swift.org/download/))
- No other dependencies — the app uses only Swift and native macOS frameworks

---

## Build and Run

```sh
git clone https://github.com/ImRuliad/skillsuite.git
cd skillsuite
./build-app.sh release
open SkillSuite.app
```

The build script compiles the app, assembles the `.app` bundle, and ad-hoc signs it for local execution. No Apple Developer account required.

To build a debug binary instead:

```sh
./build-app.sh debug
```

To run the test suite:

```sh
swift test
```

---

## How It Works

```
                     launch
                        │
                        ▼
                    AppModel
                        │
          ┌─────────────┴──────────────┐
          │                            │
 GlobalScannerService       CodebaseScannerService
          │                            │
  ┌───────┼───────┐           scans each registered
  │       │       │           project folder for
Claude Copilot Codex          provider files
  └───────┼───────┘
        Gemini
          │                            │
          └─────────────┬──────────────┘
                        │
                   SearchIndex
                  (in-memory, full-text)
                        │
                        ▼
             ┌──────────────────────┐
             │  Menu Bar Popover    │
             │  ┌────────┬────────┐ │
             │  │Sidebar │Content │ │
             │  │(nav)   │(reader)│ │
             │  └────────┴────────┘ │
             └──────────────────────┘
                        │
                   FSEvents
              watches all indexed paths
              → triggers rescan on change
              → highlights updated files
```

Global and codebase scanners run concurrently. All UI updates happen on the main actor. File watching is debounced at 250ms via FSEvents.

---

## License

MIT. Free to use, modify, and distribute.

> A `LICENSE` file has not yet been added to this repository. To formally apply the MIT license, create a `LICENSE` file at the repo root with the standard MIT license text and your name/year.
