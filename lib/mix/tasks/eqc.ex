defmodule Mix.Tasks.Eqc do
  use Mix.Task

  @shortdoc "Test QuickCheck properties"

  @moduledoc """
  A Mix task for running QuickCheck properties. At the moment, this basically calls `mix test with the given options. 

  ## Options

    * `--only property` - Default is to run all tests, also ExUnit tests,
      but this flag picks only the properties to run
    * `--only check` - Runs specific test cases annotated by @check and does not generate new QuickCheck values for properties. 

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
