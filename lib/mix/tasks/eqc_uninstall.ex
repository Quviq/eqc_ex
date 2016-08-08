defmodule Mix.Tasks.Eqc.Uninstall do
  use Mix.Task

  @shortdoc "Uninstall Quviq QuickCheck from local archive"

  @moduledoc """
  A Mix task for deleting QuickCheck as a local archive.

  ## Examples

      mix eqc.uninstall

  """

  @spec run(OptionParser.argv) :: boolean
  def run(_argv) do
    case :code.which(:eqc) do
      :non_existing ->
        Mix.raise """
          Error: no QuickCheck version found
          """
      path ->
        eqc_version = Regex.named_captures(~r/(?<prefix>.*)\/(?<app>eqc)-(?<version>[^\/]*)/, List.to_string(path))
        eqc_dir = eqc_version["prefix"]        
                    
        delete_dirs =
          [ eqc_dir ] ++
          if :code.which(:pulse) == :non_existing do
            []
          else
            [ Path.join(Path.dirname(eqc_dir), "pulse-" <> eqc_version["version"]),
              Path.join(Path.dirname(eqc_dir), "pulse_otp-" <> eqc_version["version"]) ]
          end
        if Mix.shell.yes?("Are you sure you want to delete#{for d<-delete_dirs, do: "\n  "<> d }?") do
          for d <- delete_dirs, do: File.rm_rf!(d)
        else
          Mix.shell.info( [:yellow, "Uninstall aborted", :reset])
        end

    end
  end

end
