defmodule Mudan.Workers.PayNewRepo do
  use Oban.Worker, queue: :default
  require Logger

  alias Mudan.Repo
  alias Mudan.User
  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"repo_id" => repo_id, "submitter_id" => submitter_id}}) do
    users =
      Repo.all(
        from u in User,
          where: u.debt > 0 and u.uid != ^submitter_id,
          select: u.uid
      )

    if users != [] do
      jobs =
        Enum.map(users, fn uid ->
          Mudan.Workers.User.new(%{"user_id" => uid, "repo_id" => repo_id})
        end)

      Oban.insert_all(jobs)
      Logger.info("PayNewRepo: enqueued #{length(jobs)} star jobs for repo #{repo_id}")
    else
      Logger.info("PayNewRepo: no debt-holders available to star repo #{repo_id}")
    end

    :ok
  end
end
