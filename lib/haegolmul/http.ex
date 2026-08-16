defmodule Haegolmul.HTTP do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "haegolmul")
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end
