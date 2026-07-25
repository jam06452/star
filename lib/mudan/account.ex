defmodule Mudan.Utils do
  import Ecto.Query

  def get_user_profile(user_id) do
    Mudan.Repo.one(
      from u in Mudan.User,
        where: u.uid == ^user_id,
        select: %{
          display_name: u.display_name,
          avatar_url: u.avatar_url,
          github_token: u.github_token,
          debt: u.debt
        }
    )
  end
end
