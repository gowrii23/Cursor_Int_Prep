# AGENTS.md

Guidance for AI agents working in this repository.

## Repository overview

**Cursor_Int_Prep** is currently an empty starter repository. It contains only `README.md` with a project title. There is no application code, package manifests, Docker configuration, CI workflows, or test suites yet.

## Development commands

| Task | Command | Notes |
|------|---------|-------|
| Check repo status | `git status` | Working tree should be clean after setup |
| View project files | `ls -la` | Expect `README.md` and `AGENTS.md` |
| Lint | — | Not configured |
| Test | — | Not configured |
| Build | — | Not configured |
| Run app | — | No application to run |

Once application code is added (e.g. `package.json`, `pyproject.toml`, `Makefile`, or `docker-compose.yml`), update this table with the real commands.

## Cursor Cloud specific instructions

- **No dependency install step is required** for the current codebase. The VM update script is a no-op (`true`).
- **No services need to be started.** There are no databases, caches, or dev servers defined in the repo.
- **Git is the only toolchain in use today.** Verify the environment by confirming `git status` succeeds and `README.md` is present.
- When code is added to this repo, also add:
  - A package manager lockfile or equivalent dependency manifest
  - Documented lint/test/build/run commands in `README.md`
  - Updates to this file (especially the development commands table and the VM update script)
