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
