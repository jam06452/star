defmodule MudanWeb.AuthController do
  use MudanWeb, :controller
  alias Mudan.User

  def on_success(conn, %{user: user, token: token}) do
    attrs = %{
      uid: user.uid,
      display_name: user.name,
      email: user.email,
      avatar_url: user.avatar,
      github_token: token["access_token"]
    }

    changeset = Mudan.User.changeset(%User{}, attrs)

    case Mudan.Repo.insert(
           changeset,
           on_conflict: {:replace, [:github_token, :avatar_url, :display_name]},
           conflict_target: :uid
         ) do
      {:ok, user} ->
        conn
        |> configure_session(renew: true)
        |> put_session(:user_id, user.uid)
        |> put_flash(:info, "Logged in as #{user.email}")
        |> redirect(to: ~p"/dash")

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

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end
end
