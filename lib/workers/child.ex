defmodule Mudan.Workers.User do
  use Oban.Worker, queue: :default
  import Ecto.Query
  alias Mudan.Star
  alias Mudan.User

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id, "repo_id" => repo_id}}) do
    profile = Mudan.Utils.get_user_profile(user_id)

    case starred(profile.github_token, repo_id) do
      false -> start(profile.github_token, profile.uid, repo_id)
      _ -> {:cancel, :already_starred}
    end
  end

  def start(github_token, user_id, repo_id) do
    case star(github_token, repo_id) do
      :ok ->
        Mudan.Repo.update_all(
          from(
            u in User,
            where: u.uid == ^user_id
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

        new_status =
          case Mudan.Repo.one(from(r in Star, where: r.repo_id == ^repo_id)) do
            %{needed_likes: n} when n > 0 -> "pending"
            _ -> "completed"
          end

        Mudan.Repo.update_all(
          from(
            r in Star,
            where: r.repo_id == ^repo_id
          ),
          set: [status: new_status]
        )

        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  def star(github_token, repo_id) do
    url = "https://api.github.com/user/starred/#{repo_id}"

    headers = [
      {"Accept", "application/vnd.github+json"},
      {"Authorization", "Bearer #{github_token}"},
      {"X-GitHub-Api-Version", "2026-03-10"}
    ]

    case Req.put(url, headers: headers) do
      {:ok, %Req.Response{status: 200}} ->
        :ok

      {:ok, %Req.Response{status: 204}} ->
        :ok

      {:ok, %Req.Response{status: status, body: body}} ->
        reason = {:http_error, status, body}
        {:error, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def starred(github_token, repo_id) do
    url = "https://api.github.com/user/starred/#{repo_id}"

    headers = [
      {"Authorization", "Bearer #{github_token}"},
      {"Accept", "application/vnd.github+json"}
    ]

    case Req.put(url, headers: headers) do
      {:ok, %Req.Response{status: 204}} -> true
      {:ok, %Req.Response{status: 404}} -> false
    end
  end
end
