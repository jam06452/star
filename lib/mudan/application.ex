defmodule Mudan.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Mudan.Vault,
      MudanWeb.Telemetry,
      Mudan.Repo,
      {DNSCluster, query: Application.get_env(:mudan, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:mudan, Oban)},
      {Phoenix.PubSub, name: Mudan.PubSub},
      # Start a worker by calling: Mudan.Worker.start_link(arg)
      # {Mudan.Worker, arg},
      # Start to serve requests, typically the last entry
      MudanWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mudan.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MudanWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
