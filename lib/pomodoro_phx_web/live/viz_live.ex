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

  def hour_to_pct(hour) do
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
    |> Kernel./(1)
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
end
