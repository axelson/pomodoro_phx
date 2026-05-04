# Pomodoro Bar Visualization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a `/viz` LiveView page that renders today's pomodoros as a horizontal bar timeline, matching the Scenic `PomodoroBarVizComponent` design.

**Architecture:** A new LiveView fetches today's pomodoro logs (reusing the query pattern from `StatsController`), converts timestamps to percentage positions on a 6:30 AM–8:30 PM timeline, and renders colored segments with pure CSS (absolute positioning inside a relative container). A 60-second timer keeps the current-time marker and in-progress pomodoro fresh.

**Tech Stack:** Phoenix LiveView, Tailwind CSS, Ecto queries, `Pacific/Honolulu` timezone.

---

### Task 1: Extract shared data-fetching into a context module

The `StatsController` has `fetch_logs/0` and `mark_last_pomodoro_as_in_progress/1` that we need in the new LiveView too. Extract them so both can use them.

**Files:**
- Create: `lib/pomodoro_phx/pomodoro_stats.ex`
- Modify: `lib/pomodoro_phx_web/controllers/stats_controller.ex`

**Step 1: Create the context module**

Create `lib/pomodoro_phx/pomodoro_stats.ex`:

```elixir
defmodule PomodoroPhx.PomodoroStats do
  import Ecto.Query
  alias Pomodoro.Schemas.PomodoroLog

  @timezone "Pacific/Honolulu"

  def fetch_todays_logs do
    now = DateTime.now!(@timezone)

    begin =
      Timex.beginning_of_day(now)
      |> DateTime.shift_zone!("Etc/UTC")

    from(p in PomodoroLog,
      where: p.started_at >= ^begin,
      order_by: {:asc, p.started_at}
    )
    |> Pomodoro.Repo.all()
  end

  def mark_last_pomodoro_as_in_progress([]), do: []

  def mark_last_pomodoro_as_in_progress(logs) do
    {head, [tail]} = Enum.split(logs, -1)
    tail = mark_as_in_progress(tail)
    head ++ [tail]
  end

  defp mark_as_in_progress(%PomodoroLog{finished_at: nil} = log) do
    %PomodoroLog{log | finished_at: NaiveDateTime.utc_now()}
  end

  defp mark_as_in_progress(%PomodoroLog{rest_started_at: nil} = log) do
    %PomodoroLog{log | rest_started_at: NaiveDateTime.utc_now()}
  end

  defp mark_as_in_progress(%PomodoroLog{rest_finished_at: nil} = log) do
    %PomodoroLog{rest_started_at: rest_started_at} = log
    fifteen_minutes_after = NaiveDateTime.shift(rest_started_at, minute: 15)
    now = NaiveDateTime.utc_now()

    rest_finished_at =
      if NaiveDateTime.diff(now, fifteen_minutes_after) < 0 do
        now
      else
        fifteen_minutes_after
      end

    %PomodoroLog{log | rest_finished_at: rest_finished_at}
  end

  defp mark_as_in_progress(%PomodoroLog{} = log), do: log
end
```

**Step 2: Update StatsController to delegate**

In `lib/pomodoro_phx_web/controllers/stats_controller.ex`, replace the body of `stats/2` and remove `fetch_logs/0`, `mark_last_pomodoro_as_in_progress/1`, and all `mark_as_in_progress/1` clauses. The controller becomes:

```elixir
defmodule PomodoroPhxWeb.StatsController do
  use PomodoroPhxWeb, :controller
  alias NimbleCSV.RFC4180, as: CSV

  def stats(conn, _params) do
    logs =
      PomodoroPhx.PomodoroStats.fetch_todays_logs()
      |> PomodoroPhx.PomodoroStats.mark_last_pomodoro_as_in_progress()

    rows =
      Enum.map(logs, fn log ->
        [
          log.started_at,
          log.finished_at,
          log.rest_started_at,
          log.rest_finished_at,
          log.total_seconds
        ]
      end)

    csv =
      CSV.dump_to_iodata([
        ["started_at", "finished_at", "rest_started_at", "rest_finished_at", "total_seconds"]
        | rows
      ])

    text(conn, csv)
  end
end
```

**Step 3: Run existing tests to verify the refactor**

Run: `mix test test/pomodoro_phx_web/controllers/stats_controller_test.exs`
Expected: All 5 tests pass (behavior unchanged).

**Step 4: Commit**

```bash
git add lib/pomodoro_phx/pomodoro_stats.ex lib/pomodoro_phx_web/controllers/stats_controller.ex
git commit -m "refactor: extract PomodoroStats context from StatsController"
```

---

### Task 2: Add the VizLive LiveView with data loading

**Files:**
- Create: `lib/pomodoro_phx_web/live/viz_live.ex`
- Create: `lib/pomodoro_phx_web/live/viz_live.html.heex`
- Modify: `lib/pomodoro_phx_web/router.ex`

**Step 1: Create the LiveView module**

Create `lib/pomodoro_phx_web/live/viz_live.ex`:

```elixir
defmodule PomodoroPhxWeb.VizLive do
  use PomodoroPhxWeb, :live_view

  alias PomodoroPhx.PomodoroStats

  @domain_start 6.5
  @domain_end 20.5
  @domain_range @domain_end - @domain_start
  @timezone "Pacific/Honolulu"
  @refresh_interval :timer.seconds(60)

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Process.send_after(self(), :refresh, @refresh_interval)
    end

    {:ok, load_data(socket)}
  end

  @impl Phoenix.LiveView
  def handle_info(:refresh, socket) do
    Process.send_after(self(), :refresh, @refresh_interval)
    {:noreply, load_data(socket)}
  end

  defp load_data(socket) do
    logs =
      PomodoroStats.fetch_todays_logs()
      |> PomodoroStats.mark_last_pomodoro_as_in_progress()

    now = DateTime.now!(@timezone)

    segments =
      Enum.flat_map(logs, fn log ->
        [
          segment(log.started_at, log.finished_at, "work"),
          segment(log.finished_at, log.rest_started_at, "limbo"),
          segment(log.rest_started_at, log.rest_finished_at, "rest")
        ]
      end)
      |> Enum.reject(&is_nil/1)

    total_hours = total_hours(logs)
    now_pct = hour_to_pct(hour_min(now))

    assign(socket,
      segments: segments,
      total_hours: total_hours,
      now_pct: now_pct
    )
  end

  defp segment(nil, _, _type), do: nil
  defp segment(_, nil, _type), do: nil

  defp segment(start_time, end_time, type) do
    start_h = hour_min(to_local(start_time))
    end_h = hour_min(to_local(end_time))

    %{
      left: hour_to_pct(start_h),
      width: hour_to_pct(end_h) - hour_to_pct(start_h),
      type: type
    }
  end

  defp hour_to_pct(hour) do
    (hour - @domain_start) / @domain_range * 100
  end

  defp hour_min(%DateTime{} = time) do
    time.hour + time.minute / 60
  end

  defp to_local(%NaiveDateTime{} = ndt) do
    ndt
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!(@timezone)
  end

  defp total_hours(logs) do
    logs
    |> Enum.map(&pomodoro_length/1)
    |> Enum.sum()
    |> Float.round(1)
  end

  defp pomodoro_length(log) do
    start_h = hour_min(to_local(log.started_at))

    end_time =
      cond do
        log.rest_finished_at -> log.rest_finished_at
        log.rest_started_at -> log.rest_started_at
        log.finished_at -> log.finished_at
        true -> log.started_at
      end

    hour_min(to_local(end_time)) - start_h
  end
end
```

**Step 2: Create the template**

Create `lib/pomodoro_phx_web/live/viz_live.html.heex`:

```heex
<div class="p-4">
  <h1 class="text-xl font-bold mb-4">Today's Pomodoros</h1>

  <div class="flex items-center gap-3">
    <div class="relative h-5 flex-1 bg-gray-100 border border-gray-300 rounded">
      <%!-- Pomodoro segments --%>
      <div :for={seg <- @segments} class={segment_class(seg.type)} style={"left: #{seg.left}%; width: #{seg.width}%;"}>
      </div>

      <%!-- Noon marker --%>
      <div class="absolute top-0 h-full w-0.5 bg-black" style={"left: #{noon_pct()}%;"}>
      </div>

      <%!-- Current time marker --%>
      <div class="absolute top-0 h-full w-0.5 bg-red-600" style={"left: #{@now_pct}%;"}>
      </div>
    </div>

    <span class="text-sm font-mono w-12 text-right"><%= @total_hours %>h</span>
  </div>

  <%!-- Time labels --%>
  <div class="flex justify-between mt-1 text-xs text-gray-500 flex-1 mr-15">
    <span>6:30a</span>
    <span>12p</span>
    <span>8:30p</span>
  </div>

  <%!-- Legend --%>
  <div class="flex gap-4 mt-3 text-sm">
    <div class="flex items-center gap-1">
      <div class="w-3 h-3 bg-red-600 rounded-sm"></div>
      <span>Work</span>
    </div>
    <div class="flex items-center gap-1">
      <div class="w-3 h-3 bg-orange-400 rounded-sm"></div>
      <span>Limbo</span>
    </div>
    <div class="flex items-center gap-1">
      <div class="w-3 h-3 bg-blue-600 rounded-sm"></div>
      <span>Rest</span>
    </div>
  </div>
</div>
```

Note: `segment_class/1` and `noon_pct/0` are helper functions. Add them to `viz_live.ex`:

```elixir
  def segment_class(type) do
    base = "absolute top-0 h-full"

    color =
      case type do
        "work" -> "bg-red-600"
        "limbo" -> "bg-orange-400"
        "rest" -> "bg-blue-600"
      end

    "#{base} #{color}"
  end

  def noon_pct do
    hour_to_pct(12)
  end
```

Make `hour_to_pct/1` and `noon_pct/0` public (remove `defp`) so the template can call them.

**Step 3: Add the route**

In `lib/pomodoro_phx_web/router.ex`, add to the `"/"` browser scope:

```elixir
live "/viz", VizLive, :show
```

Add it right after the existing `live "/", PomodoroLive, :show` line.

**Step 4: Verify it compiles**

Run: `mix compile --warnings-as-errors`
Expected: Compiles without errors.

**Step 5: Commit**

```bash
git add lib/pomodoro_phx_web/live/viz_live.ex lib/pomodoro_phx_web/live/viz_live.html.heex lib/pomodoro_phx_web/router.ex
git commit -m "feat: add /viz pomodoro bar visualization LiveView"
```

---

### Task 3: Add LiveView test

**Files:**
- Create: `test/pomodoro_phx_web/live/viz_live_test.exs`

**Step 1: Write the test**

Create `test/pomodoro_phx_web/live/viz_live_test.exs`:

```elixir
defmodule PomodoroPhxWeb.VizLiveTest do
  use PomodoroPhxWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "renders the viz page with no data", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/viz")
    assert html =~ "Today's Pomodoros"
    assert html =~ "0.0h"
  end

  test "renders pomodoro segments", %{conn: conn} do
    now = NaiveDateTime.utc_now()
    started_at = NaiveDateTime.shift(now, minute: -60)
    finished_at = NaiveDateTime.shift(now, minute: -35)
    rest_started_at = NaiveDateTime.shift(now, minute: -34)
    rest_finished_at = NaiveDateTime.shift(now, minute: -19)

    pomodoro_log_fixture(%{
      "started_at" => started_at,
      "finished_at" => finished_at,
      "rest_started_at" => rest_started_at,
      "rest_finished_at" => rest_finished_at
    })

    {:ok, _view, html} = live(conn, ~p"/viz")

    # Should have work, limbo, and rest segments
    assert html =~ "bg-red-600"
    assert html =~ "bg-orange-400"
    assert html =~ "bg-blue-600"
  end

  @valid_pomodoro_log_attrs %{"started_at" => ~N[2020-01-01 00:00:00]}

  defp pomodoro_log_fixture(attrs \\ %{}) do
    attrs = Map.merge(@valid_pomodoro_log_attrs, attrs)
    {:ok, log} = Pomodoro.create_pomodoro_log(attrs)
    log
  end
end
```

**Step 2: Run tests**

Run: `mix test test/pomodoro_phx_web/live/viz_live_test.exs`
Expected: Both tests pass.

**Step 3: Run full test suite**

Run: `mix test`
Expected: All tests pass.

**Step 4: Commit**

```bash
git add test/pomodoro_phx_web/live/viz_live_test.exs
git commit -m "test: add VizLive tests"
```

---

### Task 4: Manual verification

**Step 1: Start the dev server**

Run: `mix phx.server`

**Step 2: Visit `http://localhost:4000/viz`**

Verify:
- The page renders with the title "Today's Pomodoros"
- The timeline bar is visible with time labels (6:30a, 12p, 8:30p)
- The current-time red marker is positioned correctly
- The noon black marker is at the center-ish position
- Any existing pomodoro data shows colored segments
- The total hours label appears to the right
- The legend shows Work (red), Limbo (orange), Rest (blue)
