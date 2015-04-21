defmodule EQC.Mixfile do
  use Mix.Project

  def project do
    [ app: :eqc_ex,
      version: "1.2.2",
      elixir: "~> 1.0",
      deps: deps,
      package: [ contributors: ["Quviq AB"],
                 licenses: ["BSD"],
                 files: ["lib", "mix.exs", "LICENSE", "README.md"],
                 links: %{"quviq.com" => "http://www.quviq.com"}
               ],
      docs: [readme: "README.md", main: "EQC"],
      description: "Wrappers to facilitate using Quviq QuickCheck with Elixir."
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [] 
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:ex_doc, github: "elixir-lang/ex_doc", only: :dev}]
  end
end
