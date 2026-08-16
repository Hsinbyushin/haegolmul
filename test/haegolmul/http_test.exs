defmodule Haegolmul.HTTPTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts Haegolmul.HTTP.init([])

  test "GET / returns haegolmul" do
    conn =
      :get
      |> conn("/")
      |> Haegolmul.HTTP.call(@opts)

    assert conn.status == 200
    assert conn.resp_body == "haegolmul"
  end

  test "unknown routes return 404" do
    conn =
      :get
      |> conn("/does-not-exist")
      |> Haegolmul.HTTP.call(@opts)

    assert conn.status == 404
    assert conn.resp_body == "not found"
  end
end
