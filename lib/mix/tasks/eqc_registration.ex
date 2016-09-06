defmodule Mix.Tasks.Eqc.Registration do
  use Mix.Task

  @shortdoc "Register Quviq QuickCheck full version"

  @moduledoc """
  A Mix task for registration of QuickCheck when registration key has been provided. Only needed for commercial version.

  ONLY register your QuickCheck licence once. After first registration you should install and uninstall versions without using registration again. 

  ## Examples

      mix eqc.registration MyRegistrationID

  """

  @spec run(OptionParser.argv) :: boolean
  def run(argv) do
    {_opts, args, _} = OptionParser.parse(argv)
    case args do
      [key|_] ->
        if :code.which(:eqc) == :non_existing do
          Mix.raise """
            Error: QuickCheck not found
            Use mix eqc.install to install QuickCheck
          """
        else
          :eqc.registration(to_char_list key)
        end
      [] ->
        Mix.raise """
          Error: provide registration key
        """
    end
  end

end
