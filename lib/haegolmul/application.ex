defmodule Haegolmul.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Finch is our HTTP client.
      #
      # It manages reusable connection pools to upstream servers.
      # Instead of opening a completely new TCP/TLS connection for
      # every proxied request, Finch can reuse existing connections.
      #
      # `name: Haegolmul.Finch` registers this Finch process under a
      # stable name that we can reference from Haegolmul.Proxy.
      {Finch, name: Haegolmul.Finch},

      # Bandit is the HTTP server that accepts incoming client requests.
      #
      # Each incoming request is passed to Haegolmul.HTTP, our Plug router.
      #
      # At this stage the port is hard-coded to 8080.
      # We will move this into configuration later.
      {Bandit, plug: Haegolmul.HTTP, port: 8080}
    ]

    opts = [
      # `:one_for_one` means that if one child process crashes,
      # only that child will be restarted.
      #
      # For example:
      # - If Bandit crashes, Finch does not need to restart.
      # - If Finch crashes, Bandit does not need to restart.
      strategy: :one_for_one,

      # Give the supervisor a stable registered name.
      name: Haegolmul.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
