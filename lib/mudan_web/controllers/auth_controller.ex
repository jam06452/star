defmodule MudanWeb.AuthController do
  use MudanWeb, :controller

  def on_success(conn, user) do
    conn
    |> put_flash(:info, "Logged in as #{user[:email]}")
    |> redirect(to: "/")
    |> halt()
  end

  def on_failure(conn, _reason) do
    conn
    |> put_flash(:error, "Authentication failed")
    |> redirect(to: "/")
    |> halt()
  end
end
