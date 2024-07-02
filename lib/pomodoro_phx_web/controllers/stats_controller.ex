defmodule PomodoroPhxWeb.StatsController do
  use PomodoroPhxWeb, :controller
  alias NimbleCSV.RFC4180, as: CSV

  # Returns the stats for today
  def stats(conn, _params) do
    logs =
      fetch_logs()
      |> mark_in_progress_pomodoro()

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
        [
          "started_at",
          "finished_at",
          "rest_started_at",
          "rest_finished_at",
          "total_seconds"
        ]
        | rows
      ])

    text(conn, csv)
  end

  @doc "Mark the last pomodoro as currently in progress if it isn't finished"
  def mark_in_progress_pomodoro([]), do: []

  def mark_in_progress_pomodoro(logs) do
    {head, [tail]} = Enum.split(logs, -1)
    tail = %{tail | finished_at: tail.finished_at || NaiveDateTime.utc_now()}
    Enum.concat(head, [tail])
  end

  def fetch_logs do
    import Ecto.Query

    now = DateTime.now!("Pacific/Honolulu")

    begin =
      Timex.beginning_of_day(now)
      |> DateTime.shift_zone!("Etc/UTC")

    query =
      from(p in Pomodoro.Schemas.PomodoroLog,
        where: p.started_at >= ^begin,
        order_by: {:asc, p.started_at}
      )

    Pomodoro.Repo.all(query)
  end
end
