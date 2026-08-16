defmodule Haegolmul.HTTP do
  @moduledoc """
  Entry point for incoming HTTP requests.

  Bandit passes each incoming request to this Plug router.

  At the moment, every request is forwarded directly to the upstream
  through Haegolmul.Proxy.

  Later, this module will become the point where requests enter the
  Haegolmul decision pipeline:

      request
        -> observation
        -> policy evaluation
        -> verdict
        -> allow / challenge / deny
  """

  use Plug.Router

  # `:match` determines which route matches the current request.
  plug :match

  # `:dispatch` executes the handler belonging to the matched route.
  plug :dispatch

  # Match every HTTP method and every path.
  #
  # For now, Haegolmul behaves as a transparent forwarding layer.
  match _ do
    Haegolmul.Proxy.forward(conn)
  end
end
