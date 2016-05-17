defmodule Mix.Tasks.Eqc do
  use Mix.Task

  @shortdoc "Test QuickCheck properties"

  @moduledoc """
  A Mix task for running QuickCheck properties.

  ## Options

    * `--only properties` - Default is to run all tests, also ExUnit tests,
      but this flag picks only the properties to run

    * `--module` - run only....

  ## Examples

      mix eqc

  """
  @switches [only_properties: :boolean]

  def run(argv) do
    # {opts, argv, _} = OptionParser.parse(argv, switches: @switches)
    Mix.env(:test)
    Mix.Task.run(:test, argv)
  end

end
