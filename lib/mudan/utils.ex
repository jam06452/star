defmodule Mudan.Utils do
  import Ecto.Query

  def get_user_profile(user_id) do
    Mudan.Repo.one(
      from u in Mudan.User,
        where: u.uid == ^user_id,
        select: %{
          uid: u.uid,
          display_name: u.display_name,
          avatar_url: u.avatar_url,
          github_token: u.github_token,
          debt: u.debt
        }
    )
  end

  def get_repo(repo_id) do
    Mudan.Repo.one(
      from r in Mudan.User,
        where: r.repo_id == ^repo_id,
        select: %{
          user_id: r.user_uid,
          status: r.status,
          needed_likes: r.needed_likes
        }
    )
  end
end
