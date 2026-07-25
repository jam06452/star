defmodule Mudan.Workers.PayAllDebt do
  use Oban.Worker, queue: :default
  require Logger

  alias Mudan.Repo
  alias Mudan.User
  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    users = Repo.all(from u in User, where: u.debt > 0, select: u.uid)

    jobs =
      Enum.map(users, fn uid ->
        Mudan.Workers.PayDebt.new(%{"user_id" => uid})
      end)

    if jobs != [] do
      Oban.insert_all(jobs)
      Logger.info("PayAllDebt: enqueued #{length(jobs)} PayDebt jobs for users with debt")
    else
      Logger.info("PayAllDebt: no users with debt found")
    end

    :ok
  end
end
