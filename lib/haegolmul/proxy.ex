defmodule Haegolmul.Proxy do
  @moduledoc """
  Responsible for forwarding incoming HTTP requests to the configured upstream.

  At this stage, Haegolmul forwards:

  - the HTTP method
  - the request path
  - the raw query string

  Request headers, request bodies, and response headers will be added
  in later iterations.
  """

  @upstream "http://localhost:4000"

  @doc """
  Forwards an incoming Plug connection to the configured upstream.

  The incoming request is translated into a new Finch request.
  Haegolmul therefore acts in two roles:

  - as an HTTP server towards the original client
  - as an HTTP client towards the upstream
  """
  def forward(conn) do
    # Construct the complete upstream URL before creating the
    # outgoing Finch request.
    #
    # Example:
    #
    #   Incoming:
    #   GET /search?q=wonhyo
    #
    #   Upstream:
    #   http://localhost:4000/search?q=wonhyo
    url = build_upstream_url(conn)

    request =
      Finch.build(
        conn.method,
        url
      )

    case Finch.request(request, Haegolmul.Finch) do
      {:ok, response} ->
        Plug.Conn.send_resp(
          conn,
          response.status,
          response.body
        )

      {:error, reason} ->
        Plug.Conn.send_resp(
          conn,
          502,
          "upstream error: #{inspect(reason)}"
        )
    end
  end

  # Build the URL used for the outgoing request.
  #
  # Plug keeps the path and query string separate:
  #
  #   conn.request_path
  #   # => "/search"
  #
  #   conn.query_string
  #   # => "q=wonhyo&page=2"
  #
  # Keeping these values separate is useful because applications often
  # want to inspect or manipulate the path independently of the query.
  #
  # For proxying, however, we need to reconstruct the complete target URL.
  defp build_upstream_url(conn) do
    base_url = @upstream <> conn.request_path

    # An empty query string must not add a trailing "?".
    #
    # We want:
    #
    #   http://localhost:4000/foo
    #
    # rather than:
    #
    #   http://localhost:4000/foo?
    #
    # We deliberately forward the raw query string instead of decoding
    # and re-encoding it. At this layer Haegolmul does not need to know
    # what the parameters mean; it only needs to preserve them.
    case conn.query_string do
      "" ->
        base_url

      query_string ->
        base_url <> "?" <> query_string
    end
  end
end
