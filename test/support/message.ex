defmodule Ancestry.Message do
  use Ecto.Schema
  use Ancestry

  schema "messages" do
    field :title, :string
    ancestry_schema
    timestamps(usec: true)
  end

end
