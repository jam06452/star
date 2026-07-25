defmodule MudanWeb.PageController do
  use MudanWeb, :controller

  def home(conn, _params) do
    if get_session(conn, :user_id) do
      redirect(conn, to: ~p"/dash")
    else
      render(conn, :lander)
    end
  end
end
