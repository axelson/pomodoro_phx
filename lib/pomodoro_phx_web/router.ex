defmodule PomodoroPhxWeb.Router do
  use PomodoroPhxWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PomodoroPhxWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/admin", PomodoroPhxWeb.Admin, as: :admin do
    pipe_through :browser
    resources "/pomodoro_logs", PomodoroLogController
  end

  scope "/", PomodoroPhxWeb do
    pipe_through :browser
    import LogViz.Router

    live "/", PomodoroLive, :show
    get "/home", PageController, :home
    log_viz "/logs"
  end

  # Other scopes may use custom stacks.
  scope "/api", PomodoroPhxWeb do
    pipe_through :api
    get "/stats.csv", StatsController, :stats
  end

  # Other scopes may use custom stacks.
  # scope "/api", PomodoroPhxWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:pomodoro_phx, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PomodoroPhxWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
