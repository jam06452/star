defmodule Mudan.Workers.PayDebt do
  use Oban.Worker, queue: :default
  require Logger

  alias Mudan.Repo
  alias Mudan.User
  alias Mudan.Star
  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    user = Repo.get(User, user_id)

    if user && user.debt > 0 do
      batch_size = min(user.debt, 10)

      {:ok, stars} =
        Repo.transaction(fn ->
          stars =
            from(s in Star,
              where: s.status == "pending" and s.user_uid != ^user.uid and s.needed_likes > 0,
              limit: ^batch_size,
              lock: "FOR UPDATE SKIP LOCKED"
            )
            |> Repo.all()

          star_ids = Enum.map(stars, & &1.id)

          if length(star_ids) > 0 do
            Repo.update_all(
              from(s in Star, where: s.id in ^star_ids),
              set: [status: "processing"]
            )
          end

          stars
        end)

      if length(stars) > 0 do
        jobs =
          Enum.map(stars, fn star ->
            Mudan.Workers.User.new(%{
              "user_id" => user_id,
              "repo_id" => star.repo_id
            })
          end)

        Oban.insert_all(jobs)
        Logger.info("Enqueued #{length(jobs)} star jobs for user #{user.uid}")
      else
        Logger.info("No pending repos available for user #{user.uid} to star right now.")
      end
    end

    :ok
  end
end
