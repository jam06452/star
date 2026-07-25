defmodule Mudan.Workers.User do
  use Oban.Worker, queue: :default
  import Ecto.Query
  alias Mudan.Star
  alias Mudan.User

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "repo_id" => repo_id}}) do
    profile = Mudan.Utils.get_user_profile(user_id)

    case star(profile.github_token, repo_id) do
      :ok ->
        Mudan.Repo.update_all(
          from(
            u in User,
            where: u.user_uid == ^user_id
          ),
          inc: [debt: -1]
        )

        Mudan.Repo.update_all(
          from(
            r in Star,
            where: r.repo_id == ^repo_id
          ),
          inc: [needed_likes: -1]
        )

        :ok

      :error ->
        :error
    end
  end

  def star(github_token, repo_id) do
    url = "https://api.github.com/user/starred/#{repo_id}"

    headers = [
      "Authorization",
      "Bearer #{github_token}"
    ]

    case Req.put(url, headers: headers) do
      {:ok, %Req.Response{status: 200}} -> :ok
      {:ok, %Req.Response{status: 204}} -> :ok
      _ -> :error
    end
  end
end
