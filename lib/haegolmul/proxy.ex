defmodule Haegolmul.Proxy do
  @moduledoc """
  Responsible for forwarding incoming HTTP requests to the configured upstream.

  At this stage, Haegolmul forwards:

  - the HTTP method
  - the request path
  - the raw query string
  - end-to-end request headers

  Request bodies and response headers will be added in later iterations.

  Hop-by-hop headers are deliberately removed because they describe the
  connection between two HTTP peers rather than the request itself.
  """

  @upstream "http://localhost:4000"

  # These headers describe properties of a single transport connection.
  #
  # A reverse proxy terminates one HTTP connection and creates another:
  #
  #   client <---- connection A ----> Haegolmul
  #   Haegolmul <-- connection B ----> upstream
  #
  # Therefore values that describe connection A must not simply be copied
  # onto connection B.
  #
  # Note that the `connection` header is special: it may name additional
  # headers that are hop-by-hop for this particular request. We handle
  # those dynamically below.
  @hop_by_hop_headers [
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailer",
    "transfer-encoding",
    "upgrade"
  ]

  @doc """
  Forwards an incoming Plug connection to the configured upstream.

  Haegolmul receives an HTTP request through Bandit and Plug, translates
  it into a new Finch request, sends that request to the upstream, and
  finally translates the upstream response back into the original
  Plug connection.
  """
  def forward(conn) do
    url = build_upstream_url(conn)

    # Prepare request headers for the new connection between Haegolmul
    # and the upstream server.
    #
    # We do not pass `conn.req_headers` directly because some headers
    # describe only the client -> Haegolmul connection.
    headers = build_upstream_headers(conn)

    request =
      Finch.build(
        conn.method,
        url,
        headers
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

  # Build the complete URL used for the outgoing request.
  #
  # Plug stores the request path and raw query string separately.
  # We preserve the query string exactly instead of decoding and
  # rebuilding it.
  defp build_upstream_url(conn) do
    base_url = @upstream <> conn.request_path

    case conn.query_string do
      "" ->
        base_url

      query_string ->
        base_url <> "?" <> query_string
    end
  end

  # Prepare request headers for forwarding to the upstream.
  #
  # Most request headers are end-to-end information and should survive
  # the proxy boundary:
  #
  #   accept
  #   accept-language
  #   authorization
  #   cookie
  #   user-agent
  #   ...
  #
  # Hop-by-hop headers are different. They control a specific connection
  # and must not be blindly forwarded to the next HTTP peer.
  defp build_upstream_headers(conn) do
    # The `Connection` header can declare arbitrary additional headers
    # as hop-by-hop.
    #
    # For example:
    #
    #   Connection: keep-alive, x-internal-connection-option
    #
    # means that both of those named headers apply only to the current
    # connection and should not be propagated through the proxy.
    connection_headers =
      conn.req_headers
      |> header_values("connection")
      |> Enum.flat_map(&split_header_names/1)

    blocked_headers =
      MapSet.new(@hop_by_hop_headers ++ connection_headers)

    conn.req_headers
    |> Enum.reject(fn {name, _value} ->
      MapSet.member?(blocked_headers, name)
    end)
    |> Enum.reject(fn {name, _value} ->
      # `Host` identifies the target authority of the incoming request.
      #
      # The outgoing request has a different target:
      #
      #   incoming: localhost:8080
      #   outgoing: localhost:4000
      #
      # Finch should therefore construct the appropriate Host header for
      # the upstream URL rather than forwarding the original one.
      name == "host"
    end)
  end

  # Return all values for a given request header.
  #
  # HTTP permits multiple fields with the same name, so we deliberately
  # return a list instead of assuming that only one value exists.
  defp header_values(headers, name) do
    for {header_name, value} <- headers,
        header_name == name,
        do: value
  end

  # Header names listed inside `Connection` are comma-separated.
  #
  # Example:
  #
  #   "keep-alive, X-Custom-Hop"
  #
  # becomes:
  #
  #   ["keep-alive", "x-custom-hop"]
  #
  # Lowercasing is important because Plug normalizes incoming header names
  # to lowercase as well.
  defp split_header_names(value) do
    value
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.downcase/1)
  end
end
