defmodule Mudan.Resolver do
  @behaviour Oban.Web.Resolver
  import Plug.Conn

  @impl true
  def resolve_user(conn) do
    user_id = get_session(conn, :user_id)

    case user_id do
      nil ->
        nil

      user_id ->
        %{id: user_id, role: get_role(user_id)}
    end
  end

  @impl true
  def resolve_access(user) do
    case user do
      %{role: :admin} -> :all
      %{role: :viewer} -> :read_only
      _ -> {:forbidden, "/"}
    end
  end

  defp get_role(172_634_814), do: :admin
  defp get_role(_), do: :unauthorized
end
