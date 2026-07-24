defmodule MudanWeb.AuthController do
  use MudanWeb, :controller
  alias Mudan.User

  def on_success(conn, user) do
    attrs = %{
      uid: user.uid,
      display_name: user.name,
      email: user.email,
      avatar_url: user.avatar
    }

    changeset = Mudan.User.changeset(%User{}, attrs)

    case Mudan.Repo.insert(changeset) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Logged in as #{user[:email]}")
        |> redirect(to: "/")
        |> halt()

      {:error, _} ->
        conn
        |> put_flash(:error, "Saving details failed, make sure it is a unique email")
        |> redirect(to: "/")
        |> halt()
    end
  end

  def on_failure(conn, _reason) do
    conn
    |> put_flash(:error, "Authentication failed")
    |> redirect(to: "/")
    |> halt()
  end
end
