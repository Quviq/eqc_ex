defmodule OptionParserEqc do
  use ExUnit.Case
  use EQC.ExUnit

  @switches [b1: :boolean, b2: :boolean, count1: :count, count2: :count,
             b3: [:boolean, :keep], b4: [:keep, :boolean],
             int1: :integer, int2: :integer, int3: [:integer, :keep], int4: [:keep, :integer],
             f1: :float, f2: :float, f3: [:float, :keep], f4: [:keep, :float],
             str1: :string, str2: :string, str3: [:string, :keep], str4: [:keep, :string],
             str5: :keep
            ]
  
  defp pos do
    let n <- nat(), do: n+1
  end
  
  defp option({key, type}) do
      case type do
        :boolean   -> {key, bool()}
        :count     -> {key, pos()}
        [:keep, t] -> option({key, t})
        [t, :keep] -> option({key, t})
        :keep      -> option({key, :string})
        :string    -> {key, string()}
        :float     -> {key, real()}
        :integer   -> {key, int()}
      end
  end

  defp keep(t) do (t == :keep) || (is_list(t) && :keep in t) end
  
  defp options do
    let {base_opts, keep_opts} <- {sublist(Enum.filter(@switches, fn({k,t}) -> not keep(t) end)),
                                    list(elements(Enum.filter(@switches, fn({k,t}) -> keep(t) end)))} do
      let opts<- shuffle(base_opts ++ keep_opts) do
        for opt<-opts, do: option(opt)
      end
    end
  end

  defp string do
    such_that str <- non_empty(utf8()), do: String.first(str) != "-"
  end
  
  defp args do
    list(string())
  end
  
  property "OptionParser.to_argv as I like to have it" do
    forall {opts, arguments} <- {options(), args()} do
      argv = to_argv(opts ++ arguments, [switches: @switches])
      when_fail IO.puts "Argv #{inspect argv}" do
        {new_opts, new_arguments, errors} = OptionParser.parse(argv, [switches: @switches])
        conjunction(errors: (ensure errors == []),
                    extra_arguments: (ensure new_arguments -- arguments == []),
                    missing_arguments: (ensure arguments -- new_arguments == []),
                    extra_options: (ensure new_opts -- opts == []),
                    missing_options: (ensure opts -- new_opts == []))
      end      
    end
  end

  def to_argv(elements, options) do
    switches = options[:switches]
    {opts, args} =
      Enum.reduce(elements, {[], []},
        fn({k,v}, {os, as}) ->
          if {k, :count} in switches do
            { os ++ List.duplicate({k, true}, v), as}
          else
            {os ++ [{k,v}], as}
          end
          (arg, {os, as}) ->
            {os, as ++ [arg]}
        end)
    OptionParser.to_argv(opts) ++ args
  end

  test "Counts cannot be translated back" do
    original = ["--count1", "--count1"]
    {opts, [], []} = OptionParser.parse(original,  [switches: @switches])
    assert original == OptionParser.to_argv(opts)
  end

  test "No real symmetry in operations" do
    argv = ["--b1", "--no-b2", "filename"]
    {opts, args, []} = OptionParser.parse(argv,  [switches: @switches])
    #assert argv == OptionParser.to_argv(opts) ++ args
    # assert argv == to_argv(opts ++ args, [switches: @switches])
    assert argv == OptionParser.to_argv(opts ++ args)
  end


end
