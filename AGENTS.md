# Repository Guidelines

## Project Structure & Module Organization
- `src/` — Gleam sources for the library:
  - `mcp_toolkit.gleam` (public re-exports)
  - `mcp_toolkit/` with `core/`, `transport/`, and `transport_optional/` modules
  - `mcp_ffi.erl` and `mcp_ffi.mjs` power the cross-platform stdio transport
- `test/` — mirrors `src/` layout; unit, integration, and snapshot tests
- `birdie_snapshots/` — snapshot data used by Birdie tests
- Key configs: `gleam.toml`, `manifest.toml`, `.editorconfig`

## Build, Test, and Development Commands
- Install deps: `gleam deps download`
- Type check only: `gleam check`
- Format: `gleam format`
- Test: `gleam test` (runs gleeunit + Birdie snapshots)

## Coding Style & Naming Conventions
- Language: Gleam (2‑space indentation, no tabs).
- Modules/files: snake_case (e.g., `json_schema_decode.gleam`).
- Functions/constants: snake_case; types/constructors: PascalCase.
- Keep modules focused; colocate tests under `test/` with similar paths.
- Use `gleam format` before committing; avoid trailing whitespace.

## Testing Guidelines
- Frameworks: gleeunit for unit/integration; Birdie for snapshots.
- Name tests `*_test.gleam`; mirror source paths (e.g., `test/mcp_toolkit/core/...`).
- Run all tests with `gleam test`; update snapshots intentionally and review diffs.
- Aim for high coverage across core protocol and transports.

## Commit & Pull Request Guidelines
- Commits: imperative, concise subject (≤72 chars), descriptive body when needed.
- Reference scope when helpful (e.g., "core: ...", "transport: ...").
- PRs: include summary, rationale, linked issues, and screenshots/logs when relevant.
- Ensure CI passes (build + tests) and code is formatted.

## Security & Environment Notes
- Requires Erlang/OTP ≥27 and Gleam ≥1.12.0 (see `DEVELOPMENT.md`).
- Do not commit secrets; review demo scripts and examples before sharing.

## Agent-Specific Instructions
- Follow these guidelines for any edits within this repository scope.
- Keep changes minimal and focused; do not reformat unrelated files.
- Match existing file layout and naming; prefer small, composable modules.
