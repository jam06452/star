defmodule Mudan.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:uid, :integer, autogenerate: false}

  schema "users" do
    field :display_name, :string
    field :email, :string
    field :avatar_url, :string
    field :debt, :integer
    field :github_token, Mudan.Encrypted.Binary

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:uid, :display_name, :email, :avatar_url, :debt, :github_token])
    |> validate_required([:uid, :display_name, :email, :avatar_url])
    |> unique_constraint(:email)
  end
end
