defmodule Mix.Tasks.Eqc do
  use Mix.Task

  @shortdoc "Test QuickCheck properties"

  @moduledoc """
  A Mix task for running QuickCheck properties. At the moment, this basically calls `mix test` with the given options. 

  ## Options

    * `--only property` - Default is to run all tests, also ExUnit tests,
      but this flag picks only the properties to run
    * `--only check` - Runs specific test cases annotated by @check and does not generate new QuickCheck values for properties.
    * `--numtests n` - Runs `n` tests for each property.
    * `--morebugs` - Activates more_bugs where appropriate. 
    * `--showstates` - Show intermediate states in failing State Machine properties. 


  ## Examples

      mix eqc

  """
  @switches [ numtests: :integer,
              morebugs: :boolean,
              showstates: :boolean
            ]

  def run(argv) do
    {opts, files} = OptionParser.parse!(argv, switches: @switches)

    opts_to_env(opts)    

    test_opts = Enum.filter(opts, fn({k,_}) -> not k in Keyword.keys(@switches) end)
    new_argv = OptionParser.to_argv([max_cases: 1] ++ test_opts) ++ files
    
    Mix.env(:test)
    Mix.Task.run(:test, new_argv)
  end

  defp opts_to_env(opts) do
    for key <- Keyword.keys(@switches) do
      if opts[key] != nil do
        Application.put_env(:eqc, key, opts[key], [])
      end
    end
  end
  
end
