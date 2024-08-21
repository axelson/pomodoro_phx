# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :pomodoro_phx, ecto_repos: [Pomodoro.Repo]

config :pomodoro, Pomodoro.Repo,
  database: "priv/database.db",
  migration_primary_key: [type: :binary_id],
  journal_mode: :wal,
  cache_size: -64000,
  temp_store: :memory,
  pool_size: 1

# config :pomodoro, :viewport,
#   name: :main_viewport,
#   size: {800, 480},
#   default_scene: {PomodoroUi.Scene.Main, []},
#   # default_scene:
#   #   {PomodoroUi.Scene.MiniComponent, t: {595, 69}, pomodoro_timer_pid: Pomodoro.PomodoroTimer},
#   drivers: [
#     [
#       module: Scenic.Driver.Local,
#       window: [
#         title: "Pomodoro Timer"
#       ],
#       on_close: :stop_system
#     ]
#   ]

config :scenic, :assets, module: PomodoroUi.Assets

config :tzdata, :autoupdate, :disabled

config :torch, otp_app: :pomodoro_phx

# Configures the endpoint
config :pomodoro_phx, PomodoroPhxWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: PomodoroPhxWeb.ErrorHTML, json: PomodoroPhxWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PomodoroPhx.PubSub,
  live_view: [signing_salt: "63Bjta55"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :pomodoro_phx, PomodoroPhx.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.41",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.4",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
