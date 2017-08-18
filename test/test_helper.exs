defmodule Ancestry.TestCase do
  use ExUnit.CaseTemplate

  using(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      import Ecto.Query
    end
  end

  setup do
    Ecto.Adapters.SQL.Sandbox.mode(Ancestry.Repo, :manual)

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ancestry.Repo)
  end
end

Ancestry.Repo.start_link
ExUnit.start()
