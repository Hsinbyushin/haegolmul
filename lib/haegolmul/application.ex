defmodule Haegolmul.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Bandit, plug: Haegolmul.HTTP, port: 8080}
    ]

    opts = [
      strategy: :one_for_one,
      name: Haegolmul.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
