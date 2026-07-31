# markdown-reformatter

English | [Tiếng Việt](README.vi.md)

Runs `markdownlint` (via `markdownlint-cli2`) inside Docker to automatically
reformat/fix every `.md` file in a local folder, with no need to install
Node.js on your machine.

## Prerequisites

- **Docker must be installed and running**, on any OS:
  - Windows / macOS: [Docker Desktop](https://docs.docker.com/get-docker/)
  - Linux: [Docker Engine](https://docs.docker.com/engine/install/)
- **Bash**: available by default on macOS/Linux; on Windows use **Git Bash**
  (bundled with [Git for Windows](https://git-scm.com/downloads/win)) —
  `md-lint.cmd`/`run.ps1` also call `bash` under the hood, so this is required
  even if you only ever use PowerShell.
- Every script checks for Docker itself and prints a clear error if it's missing.

## Layout

- `Dockerfile` — Node.js image with `markdownlint-cli2` installed.
- `entrypoint.sh` — runs `--fix` repeatedly until it converges (some rules
  only become fixable after another rule has already been fixed), then prints
  a report of any remaining issues it couldn't auto-fix.
- `.markdownlint-cli2.jsonc.example` — the sample rule config (everything
  enabled by default, with `MD013` line-length, `MD033` inline HTML,
  `MD040` fenced-code-language, `MD025` multiple-headings, and `MD036`
  emphasis-as-heading turned off, and `MD060` pinned to the `compact` style).
  **The real `.markdownlint-cli2.jsonc` is gitignored** — every clone gets its
  own local copy to customize, which in turn becomes the *default* used to
  seed each linted folder's own config (see [Customizing rules](#customizing-rules)).
- `run.ps1` / `run.sh` — run directly from the cloned folder (**Option 1** below).
- `install.sh` / `install.ps1` — install the global `md-lint` command (**Option 2** below).
- `uninstall.sh` / `uninstall.ps1` — undo whatever `install.sh`/`install.ps1`
  set up (see [Uninstalling](#uninstalling)).
- `md-lint/md-lint` (+ `md-lint/md-lint.cmd`) — the source of the `md-lint`
  command, copied by `install.sh`/`install.ps1` into each user's own install location.

## Option 1 — Run directly from the cloned folder

No extra install step — just `git clone` and run.

### Option 1 — Bash (Git Bash on Windows / macOS / Linux)

```bash
git clone <repo-url> markdown-reformatter
cd markdown-reformatter
chmod +x run.sh

# Auto-fix
./run.sh /absolute/path/to/markdown/folder

# Check only, don't fix
./run.sh /absolute/path/to/markdown/folder --check
```

### Option 1 — PowerShell (Windows)

```powershell
git clone <repo-url> markdown-reformatter
cd markdown-reformatter

# Auto-fix
.\run.ps1 -Path "C:\path\to\markdown\folder"

# Check only, don't fix
.\run.ps1 -Path "C:\path\to\markdown\folder" -Check
```

`run.sh`/`run.ps1` use their own directory as the Docker build context, so
you can call them by relative or absolute path from anywhere — no need to
`cd` into the exact clone directory first.

## Option 2 — Install `md-lint` globally

Run this once to install the `md-lint` command, then call it from **any
directory**, even after deleting the cloned folder.

### Option 2 — Bash (Git Bash on Windows / macOS / Linux)

```bash
git clone <repo-url> markdown-reformatter
cd markdown-reformatter
chmod +x install.sh
./install.sh
```

### Option 2 — PowerShell (Windows)

```powershell
git clone <repo-url> markdown-reformatter
cd markdown-reformatter
.\install.ps1
```

The installer will:

1. Copy the files Docker needs (`Dockerfile`, `entrypoint.sh`, `package.json`,
   `.markdownlint-cli2.jsonc.example`) to `~/.md-lint`
   (`%USERPROFILE%\.md-lint` on Windows) — this becomes a standalone Docker
   build context, independent of the cloned folder. If there's no real config
   yet, it creates `~/.md-lint/.markdownlint-cli2.jsonc` from the example
   (never overwriting a customized config on re-install).
2. Copy `md-lint` (+ `md-lint.cmd` on Windows) into a `bin` directory —
   preferring one already on `PATH` (`~/bin` or `~/.local/bin`); if none
   qualifies, it creates `~/bin` and prints instructions for adding it to
   `PATH` (bash/zsh/Windows-specific, auto-detected).

After installing (open a new terminal if `PATH` was just updated):

```bash
# Git Bash / macOS / Linux — fix the current directory
md-lint ./

# Target another directory, or check only
md-lint /path/to/other/folder
md-lint ./ --check
```

```powershell
# PowerShell — same idea (md-lint.cmd calls bash under the hood)
md-lint .\
md-lint .\ --check
```

If no path is given, it defaults to the current directory (`.`).

## Customizing rules

**Every folder you lint gets its own `.markdownlint-cli2.jsonc`**, right
inside that folder:

- If the folder being linted (the path you pass to `run.sh`/`run.ps1`/`md-lint`)
  already has a `.markdownlint-cli2.jsonc`, it's used as-is — never overwritten.
- If it doesn't, one is copied in automatically on first run, from the tool's
  own default config:
  - **Option 1** (running from the clone): the default lives at the repo
    root. The first time you run `run.sh`/`run.ps1`, that root config is
    itself created from `.markdownlint-cli2.jsonc.example` if missing.
  - **Option 2** (global `md-lint`): the default lives at
    `~/.md-lint/.markdownlint-cli2.jsonc` (`%USERPROFILE%\.md-lint\.markdownlint-cli2.jsonc` on Windows).

So different markdown folders can each have their own rules, and editing a
folder's config after that first run only affects that folder. To change the
*default* used for folders that don't have a config yet, edit the repo-root
(Option 1) or `~/.md-lint` (Option 2) config instead — see the paths above.

Full rule list: [markdownlint rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md).
No manual rebuild needed — `run.sh`/`run.ps1`/`md-lint` all run `docker build`
(cached, ~1s if nothing changed) before every run.

## Uninstalling

- **Option 1** (running from the clone): nothing is installed outside the
  Docker image, so just delete the cloned folder. To also remove the built image:

  ```bash
  docker rmi markdown-reformatter
  ```

- **Option 2** (global `md-lint`): run `uninstall.sh`/`uninstall.ps1` from the
  cloned folder (or download just these two files if you already deleted the
  clone) — it removes exactly what `install.sh`/`install.ps1` created:
  deletes `~/.md-lint`, removes `md-lint`/`md-lint.cmd` from the `bin`
  directory, removes it from `PATH` if the installer added it, and removes
  the Docker image. Safe to run more than once (it just reports there's
  nothing to do).

  ```bash
  ./uninstall.sh
  ```

  ```powershell
  .\uninstall.ps1
  ```

  If you manually added an `export PATH=...` line to `~/.bashrc`/`~/.zshrc`
  following the install instructions, the script won't remove that line —
  you'll need to remove it yourself.

## Notes

- The container only touches files inside the folder you're linting — nothing
  else is touched. That includes writing a `.markdownlint-cli2.jsonc` into
  that folder on first run if it doesn't have one yet (see
  [Customizing rules](#customizing-rules)).
- Run with `--check` first before fixing for real if the markdown folder isn't backed up/committed yet.
- Some issues (e.g. `MD040` fenced-code-language, if not disabled) can't be
  auto-fixed because the tool can't guess the code block's language — these
  are printed at the end for you to fix by hand.
- On Windows/Git Bash: the scripts convert paths to `C:/...` form (via
  `cygpath -m`) before mounting into Docker — MSYS-style paths (`/c/...`)
  cause Docker Desktop to silently mount an empty directory instead.
