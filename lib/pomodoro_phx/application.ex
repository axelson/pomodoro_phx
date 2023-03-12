defmodule PomodoroPhx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PomodoroPhxWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PomodoroPhx.PubSub},
      # Start Finch
      {Finch, name: PomodoroPhx.Finch},
      # Start the Endpoint (http/https)
      PomodoroPhxWeb.Endpoint
      # Start a worker by calling: PomodoroPhx.Worker.start_link(arg)
      # {PomodoroPhx.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PomodoroPhx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PomodoroPhxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
