defmodule PomodoroPhxWeb.VizLiveTest do
  use PomodoroPhxWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "renders the viz page with no data", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/viz")
    assert html =~ "Today" <> "&#39;" <> "s Pomodoros"
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
