defmodule MudanWeb.PageController do
  use MudanWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
