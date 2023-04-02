defmodule PomodoroPhxWeb.PomodoroLive do
  use PomodoroPhxWeb, :live_view
  require Logger
  alias Pomodoro.PomodoroTimer

  def mount(_params, _session, socket) do
    if connected?(socket) do
      PomodoroTimer.register(self())
    end

    socket = assign(socket, seconds_remaining: 0)

    {:ok, socket}
  end

  def handle_info({:pomodoro_timer, pomodoro_timer}, socket) do
    socket = assign(socket, seconds_remaining: pomodoro_timer.seconds_remaining)

    {:noreply, socket}
  end

  def handle_info(msg, state) do
    Logger.warn("Unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end
end
