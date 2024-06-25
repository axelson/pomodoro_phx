defmodule PomodoroPhxWeb.PomodoroLive do
  use PomodoroPhxWeb, :live_view
  require Logger
  alias Pomodoro.PomodoroTimer

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PomodoroTimer.register(self())
    end

    socket = assign(socket, timer: PomodoroTimer.get_timer())

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("next", _value, socket) do
    result = PomodoroTimer.next()
    Logger.debug("Next: #{inspect(result)}")
    {:noreply, socket}
  end

  def handle_event("start", _value, socket) do
    result = PomodoroTimer.start_ticking()
    Logger.debug("Starting: #{inspect(result)}")
    {:noreply, socket}
  end

  def handle_event("reset", _value, socket) do
    result = PomodoroTimer.reset()
    Logger.debug("Resetting: #{inspect(result)}")
    {:noreply, socket}
  end

  def handle_event("pause", _value, socket) do
    result = PomodoroTimer.pause()
    Logger.debug("Pausing: #{inspect(result)}")
    {:noreply, socket}
  end

  def handle_event("rest", _value, socket) do
    result = PomodoroTimer.rest()
    Logger.debug("Resting: #{inspect(result)}")
    {:noreply, socket}
  end

  def handle_event(event, _value, socket) do
    Logger.warning("Unhandled event: #{inspect(event)}")
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:pomodoro_timer, pomodoro_timer}, socket) do
    socket = assign(socket, timer: pomodoro_timer)

    {:noreply, socket}
  end

  def handle_info(msg, state) do
    Logger.warning("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end

  def human_readable_timer_status(%Pomodoro.PomodoroTimer{status: status}) do
    case status do
      :initial -> "Not started"
      :running -> "Working"
      :running_paused -> "Working (paused)"
      :limbo -> "Limbo"
      :limbo_finished -> "Limbo finished"
      :resting -> "Resting"
      :resting_paused -> "Resting (paused)"
      :finished -> "Resting finished"
      other_status -> "Unrecognized status (#{inspect(other_status)})"
    end
  end

  def status_style(%Pomodoro.PomodoroTimer{status: status}) do
    case status do
      :initial -> ""
      :running -> "color: #7F1616;"
      :running_paused -> "color: #D66E6E;"
      :limbo -> "color: #5A0F4E;"
      :limbo_finished -> "color: #3E0134;"
      :resting -> "color: #090E3D;"
      :resting_paused -> "color: #191F58;"
      :finished -> "color: #080D3B;"
      _other_status -> "color: #7F5416;"
    end
  end
end
