defmodule Mudan.Repo.Migrations.CreateRepos do
  use Ecto.Migration

  def change do
    create table(:repos, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_uid, references(:users, column: :uid, type: :integer)
      add :repo_id, :string
      add :status, :string
      add :needed_likes, :integer

      timestamps()
    end
  end
end
