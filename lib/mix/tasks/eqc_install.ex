defmodule Mix.Tasks.Eqc.Install do
  use Mix.Task

  @shortdoc "Install Quviq QuickCheck as local archive"

  @moduledoc """
  A Mix task for installing QuickCheck as a local archive. Note that you need a QuickCheck licence to be able to run the full version of QuickCheck (mailto: support@quviq.com to purchase one).
  QuickCheck Mini is Quviq's free version of QuickCheck.

  ## Options

      * `--mini` - Install QuickCheck Mini. Default is to install full version.
      * `--version version` - Provide version number for specific QuickCheck to install

  ## Examples

      mix eqc.install --mini
      mix eqc.install --version 1.38.1

  """
  @switches [mini: :boolean, version: :string]

  @spec run(OptionParser.argv) :: boolean
  def run(argv) do
    IO.inspect argv
    {opts, _, _} = OptionParser.parse(argv, switches: @switches)
    version = if opts[:version] do
                "-" <> opts[:version]
              else
                ""
              end
    {uri, dst} = if opts[:mini] do
                   {"http://quviq.com/downloads/", "eqcmini#{version}"}
                 else
                   {"http://quviq-licencer.com/downloads/", "eqcR#{:erlang.system_info(:otp_release)}#{version}"}
                 end
    src = Path.join(uri,"#{dst}.zip")

    # Mix.Local.name_for and Mix.Local.path_for hardcode that only :escript and :archive can be used.
    # Need to fix this in Elixir.
    
    Mix.shell.info [:green, "* downloading ", :reset, src]
    case Mix.Utils.read_path(src, []) do
      {:ok, binary} ->
        dir_dst = Path.join(Mix.Local.path_for(:archive), dst)
        File.mkdir_p!(dir_dst)
        {:ok, files} = :zip.extract(binary, [cwd: dir_dst])
        eqc_version =
          Enum.reduce(files, nil, 
                      fn(f, acc) ->
                        acc || Regex.named_captures(~r/(?<prefix>.*)\/(?<app>eqc)-(?<version>[^\/]*)/, f)
                      end)
        if eqc_version do
          archives = if opts[:mini] do
                       [ Path.join(eqc_version["prefix"], "eqc-#{eqc_version["version"]}") ]
                     else
                       [ Path.join(eqc_version["prefix"], "eqc-#{eqc_version["version"]}"),
                         Path.join(eqc_version["prefix"], "pulse-#{eqc_version["version"]}"),
                         Path.join(eqc_version["prefix"], "pulse_otp-#{eqc_version["version"]}") ]
                     end
          build_archives(archives)  
        else
          Mix.shell.info [:red, "Error! Failed to find eqc in downloaded zip", :reset]
        end
                                      
                                        
      :badpath ->
          Mix.raise "Expected #{inspect src} to be a URL or a local file path"

      {:local, message} ->
        Mix.raise message

      {kind, message} when kind in [:remote, :checksum] ->
        Mix.raise """
          #{message}

          Could not fetch QuickCheck at:   
             #{src}
          """
    end
  end

  defp build_archives(archives) do
    Mix.shell.info [:green, "* creating archive(s)", :reset]

    for a<-archives, do: Mix.Tasks.Archive.Build.run(["--no-compile", "--input", a, "--output", a<>".ez"])

    for a<-archives do
      Mix.shell.info [:green, "* installing archive ", :reset, a]
      Mix.Tasks.Archive.Install.run([a<>".ez"])
    end
    
  end

end
