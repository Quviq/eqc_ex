defmodule EQC.Pulse.Mixfile do
  use Mix.Project

  def project do
    [ app: :pulse_libs,
      version: "1.0.0",
      elixir: "~> 1.0",
      deps: deps,
      package: [ contributors: ["Quviq AB"],
                 licenses: ["Apache 2.0"],
                 files: ["lib", "mix.exs", "LICENSE", "README.md"],
                 links: %{"quviq.com" => "http://www.quviq.com"}
               ],
      description: "Elixir standard libraries instrumented with PULSE."
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
    []
  end
end
