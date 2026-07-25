defmodule Mudan.Repo.Migrations.DefaultDebtAmount do
  use Ecto.Migration

  def up do
    execute "UPDATE users SET debt = 0 WHERE debt IS NULL"

    alter table(:users) do
      modify :debt, :integer, default: 0, null: false
    end
  end

  def down do
    alter table(:users) do
      modify :debt, :integer, default: nil, null: true
    end
  end
end
