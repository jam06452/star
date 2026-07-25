defmodule Mudan.Repo.Migrations.UniqueIndexRepos do
  use Ecto.Migration

  def change do
    create unique_index(:repos, [:user_uid])
  end
end
