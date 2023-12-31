import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :synthetic_manager, SyntheticManager.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "synthetic_manager_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :synthetic_manager, SyntheticManagerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "M7DPSUZU1ED7wBd+pA3yAJG5nBt7gJ88i54RHprK+nHpH2oXilZBbgn1zwDlwcjr",
  server: false,
  migration_primary_key: [name: :id, type: :uuid]

# In test we don't send emails.
config :synthetic_manager, SyntheticManager.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
