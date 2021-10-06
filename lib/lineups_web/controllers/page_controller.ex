defmodule LineupsWeb.PageController do
  use LineupsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
