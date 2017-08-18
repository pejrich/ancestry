defmodule Ancestry.Mixfile do
  use Mix.Project

  def project do
    [app: :ancestry,
     description: "A materialized-path based ancestry tree library for Elixir / Phoenix / Ecto projects",
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package
   ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Peter Richards"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/pejrich/ancestry"}
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [
      :ecto
    ]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
     {:ex_doc, ">= 0.0.0", only: :dev},
     {:ecto, "~> 2.0"}
    ]
  end
end
