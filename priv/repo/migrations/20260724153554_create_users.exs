defmodule Mudan.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :uid, :integer, primary_key: true
      add :display_name, :string
      add :email, :string
      add :avatar_url, :string

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
