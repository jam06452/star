defmodule MudanWeb.Plugs.AuthenticateUser do
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2, put_flash: 3]

  alias Mudan.User
  alias Mudan.Repo

  def init(opts), do: opts

  def call(conn, _opts) do
    get_session(conn, :user_id)
    |> case do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: "/")
        |> halt()

      user_id ->
        case Repo.get(User, user_id) do
          nil ->
            conn
            |> configure_session(drop: true)
            |> redirect(to: "/")
            |> halt()

          user ->
            assign(conn, :current_user, user)
        end
    end
  end
end
