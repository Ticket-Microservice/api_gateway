defmodule ApiGateway.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ApiGatewayWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:api_gateway, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ApiGateway.PubSub},
      ApiGateway.GRPCClient,
      # Start a worker by calling: ApiGateway.Worker.start_link(arg)
      # {ApiGateway.Worker, arg},
      # Start to serve requests, typically the last entry
      ApiGatewayWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ApiGateway.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ApiGatewayWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
