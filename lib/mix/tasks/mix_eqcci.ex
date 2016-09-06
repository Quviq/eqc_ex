defmodule Mix.Tasks.EqcCI do
  use Mix.Task

  @shortdoc "Create a project's properties for QuickCheck-CI"
  @recursive true

  @moduledoc """
  Create the properties for a project.

  This task mimics `mix test` but compiles the test files to beam instead of in
  memory and does not execute the tests or properties.

  Switches are ignored for the moment.

  """

  @switches [force: :boolean, color: :boolean, cover: :boolean,
             max_cases: :integer, include: :keep,
             exclude: :keep, only: :keep, compile: :boolean,
             timeout: :integer]

  @spec run(OptionParser.argv) :: :ok
  def run(args) do
    Mix.shell.info "Building properties for QuickCheck-CI"
    {opts, files, _} = OptionParser.parse(args, switches: @switches)

    unless System.get_env("MIX_ENV") || Mix.env == :test do
      Mix.raise "mix eqcci is running on environment #{Mix.env}. Please set MIX_ENV=test explicitly"
    end

    Mix.Task.run "loadpaths", args

    if Keyword.get(opts, :compile, true) do
      Mix.Task.run "compile", args
    end

    project = Mix.Project.config

    # Start the app and configure exunit with command line options
    # before requiring test_helper.exs so that the configuration is
    # available in test_helper.exs. Then configure exunit again so
    # that command line options override test_helper.exs
    Mix.shell.print_app
    Mix.Task.run "app.start", args

    # Ensure ex_unit is loaded.
    case Application.load(:ex_unit) do
      :ok -> :ok
      {:error, {:already_loaded, :ex_unit}} -> :ok
    end

    opts = ex_unit_opts(opts)
    ExUnit.configure(opts)

    test_paths = project[:test_paths] || ["test"]
    Enum.each(test_paths, &require_test_helper(&1))
    ExUnit.configure(opts)

    # Finally parse, require and load the files
    test_files   = parse_files(files, test_paths)
    test_pattern = project[:test_pattern] || "*_test.exs"

    test_files = Mix.Utils.extract_files(test_files, test_pattern)
    _ = Kernel.ParallelCompiler.files_to_path(test_files, Mix.Project.compile_path(project))

  end

  @doc false
  def ex_unit_opts(opts) do
    opts = opts
           |> filter_opts(:include)
           |> filter_opts(:exclude)
           |> filter_only_opts()

    default_opts(opts) ++
      Keyword.take(opts, [:trace, :max_cases, :include, :exclude, :seed, :timeout])
  end

  defp default_opts(opts) do
    # Set autorun to false because Mix
    # automatically runs the test suite for us.
    case Keyword.get(opts, :color) do
      nil -> [autorun: false]
      enabled? -> [autorun: false, colors: [enabled: enabled?]]
    end
  end

  defp parse_files([], test_paths) do
    test_paths
  end

  defp parse_files([single_file], _test_paths) do
    # Check if the single file path matches test/path/to_test.exs:123, if it does
    # apply `--only line:123` and trim the trailing :123 part.
    {single_file, opts} = ExUnit.Filters.parse_path(single_file)
    ExUnit.configure(opts)
    [single_file]
  end

  defp parse_files(files, _test_paths) do
    files
  end

  defp parse_filters(opts, key) do
    if Keyword.has_key?(opts, key) do
      ExUnit.Filters.parse(Keyword.get_values(opts, key))
    end
  end

  defp filter_opts(opts, key) do
    if filters = parse_filters(opts, key) do
      Keyword.put(opts, key, filters)
    else
      opts
    end
  end

  defp filter_only_opts(opts) do
    if filters = parse_filters(opts, :only) do
      opts
      |> Keyword.put_new(:include, [])
      |> Keyword.put_new(:exclude, [])
      |> Keyword.update!(:include, &(filters ++ &1))
      |> Keyword.update!(:exclude, &[:test|&1])
    else
      opts
    end
  end

  defp require_test_helper(dir) do
    file = Path.join(dir, "test_helper.exs")

    if File.exists?(file) do
      Code.require_file file
    else
      Mix.raise "Cannot run tests because test helper file #{inspect file} does not exist"
    end
  end
  

end
