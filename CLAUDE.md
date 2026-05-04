# CLAUDE.md - PomodoroPhx

## What This Is

Phoenix 1.7 web frontend for a Pomodoro timer. Core timer logic and database layer live in the `:pomodoro` dependency (github: axelson/pomodoro) — this app is the web/UI layer.

## Quick Reference

```bash
mix setup              # deps.get + install tailwind/esbuild + build assets
mix phx.server         # start dev server at localhost:4000
mix test.setup         # create + migrate test database (run once)
mix test               # run tests
mix format             # format code (Phoenix + LiveView HTML plugins)
```

## Architecture

- **Timer logic**: `Pomodoro.PomodoroTimer` GenServer in the `:pomodoro` dep — not in this repo
- **Schema**: `Pomodoro.Schemas.PomodoroLog` (started_at, finished_at, rest_started/finished_at, total_seconds) — also in the dep
- **Repo**: `Pomodoro.Repo` — SQLite, pool size 1, WAL mode, binary_id primary keys
- **Database file**: `priv/database.db` (test: `test/database.db`)
- **Migrations**: inherited from `:pomodoro` dep (`deps/pomodoro/priv/repo/migrations/`)

## Routes

| Path | Handler | Purpose |
|---|---|---|
| `/` | `PomodoroLive` (LiveView) | Real-time timer UI |
| `/admin/pomodoro_logs` | `Admin.PomodoroLogController` | Torch CRUD admin |
| `/api/stats.csv` | `StatsController` | CSV export (JSON pipeline) |
| `/logs` | `LogViz` | Log visualization (from dep) |
| `/home` | `PageController` | Default Phoenix page (unused) |

## Key Patterns

- LiveView at `/` registers with the PomodoroTimer GenServer and receives `{:pomodoro_timer, timer}` broadcasts
- Admin uses Torch scaffolding — templates in `controllers/admin/pomodoro_log_html/`
- Stats controller hardcodes `Pacific/Honolulu` timezone
- Formatter: Phoenix plugin + `Phoenix.LiveView.HTMLFormatter`
- Tailwind for CSS, esbuild for JS, both configured in `config/config.exs`
- Verified routes with `~p` sigil

## Dependencies to Know

- `:pomodoro` — core timer + DB logic (can swap to `path: "~/dev/pomodoro"` for local dev)
- `:torch` — admin CRUD generator
- `:nimble_csv` — CSV generation in StatsController
- `:log_viz` — log viewer at `/logs`
- `:machete` — pattern-matching test assertions (test only)

## Testing

- `ConnCase` for controller tests, `DataCase` for Ecto tests
- Ecto SQL Sandbox for test isolation
- No LiveView tests currently — timer is tested in the `:pomodoro` dep
- Stats tests verify incomplete-pomodoro extension logic
