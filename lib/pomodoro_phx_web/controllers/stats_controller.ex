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
