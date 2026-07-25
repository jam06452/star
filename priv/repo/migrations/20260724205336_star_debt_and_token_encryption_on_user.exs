defmodule Mudan.Repo.Migrations.StarDebtAndTokenEncryptionOnUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :debt, :integer
      add :github_token, :binary
    end
  end
end
