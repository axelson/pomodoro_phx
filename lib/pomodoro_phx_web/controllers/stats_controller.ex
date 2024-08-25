defmodule PomodoroPhxWeb.StatsController do
  use PomodoroPhxWeb, :controller
  alias NimbleCSV.RFC4180, as: CSV
  alias Pomodoro.Schemas.PomodoroLog

  # Returns the stats for today
  def stats(conn, _params) do
    logs =
      fetch_logs()
      |> mark_last_pomodoro_as_in_progress()

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
  def mark_last_pomodoro_as_in_progress([]), do: []

  def mark_last_pomodoro_as_in_progress(logs) do
    {head, [tail]} = Enum.split(logs, -1)
    tail = mark_as_in_progress(tail)
    Enum.concat(head, [tail])
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
