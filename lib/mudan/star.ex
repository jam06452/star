defmodule Mudan.Star do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :integer

  schema "repos" do
    belongs_to :user, Mudan.User, foreign_key: :user_uid, references: :uid
    field :repo_id, :string
    field :status, :string, default: "pending"
    field :needed_likes, :integer

    timestamps()
  end

  def changeset(star, attrs) do
    star
    |> cast(attrs, [:user_uid, :repo_id, :status, :needed_likes])
    |> validate_required([:user_uid, :repo_id, :needed_likes])
    |> unique_constraint(:user_uid)
  end
end
