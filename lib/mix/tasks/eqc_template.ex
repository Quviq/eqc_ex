defmodule Mix.Tasks.Eqc.Template do
  use Mix.Task

  @shortdoc "Create template for Quviq QuickCheck models"
  
  @moduledoc """
  A Mix task for creating a template for a specific QuickCheck model.

  ## Options

     * `--model model` - creates a QuickCheck model (default eqc_statem).
     * `--dir directory` - puts the created file into directory (default first path in :test_paths project parameter).
     * `--api api_description` - uses @spec notiation type declarations to create a template. 

  ## Examples

      mix eqc.template --model eqc_statem model_eqc.exs
      mix eqc.template --model eqc_component eqc/comp_eqc.exs
      mix eqc.template --dir test model_eqc.exs
      mix eqc.template --api "Process.register(pid(), name()) :: true" process_eqc.exs
      mix eqc.template --api "[ Process.register(pid(), name()) :: true, Process.unregister(name()) :: true ]" process_eqc.exs


  """

  @switches [dir: :string, model: :atom, api: :string]

  @spec run(OptionParser.argv) :: boolean
  def run(argv) do
    {opts, filename, _} = OptionParser.parse(argv, switches: @switches)

    file = Path.basename(filename, ".exs") 
    name = case file do
             "" -> "ModelEqc"
             other ->
               Macro.camelize(other)
           end
    
    dir = Path.expand(opts[:dir] ||
      case Path.split(filename) do
        [_] ->
          case  Mix.Project.config[:test_paths] do
            nil -> "test"
            paths -> hd(paths)
          end
        _ ->
          Path.dirname(filename)
      end)

    ## Analyze API if provided
    api = extract_api(opts[:api])

    model = opts[:model] || :eqc_statem
    content = template(model, name, api)
    
    case file do
      "" ->
        ## on screen
        IO.write content
      _ ->
        dest = Path.join(dir, file <> ".exs")
        if File.exists?(dest) do
          Mix.raise "Error: file already exists #{dest}"
        end
        if not File.exists?(dir) do
          Mix.raise "Error: no directory #{dir}"
        end
        Mix.shell.info [:green, "creating #{model} model as ", :reset, dest ]
        File.write!(dest, content)
    end

  end
  
  defp extract_api(nil) do
    [cmd: {:cmd, quote do [int()] end, quote do int() end}]
  end
  defp extract_api(string) do
    quoted_api = 
      try do Code.eval_string("quote do\n" <> string <> "\nend")
      rescue
        _ -> Mix.raise "Error in API description"
      end
    api_defs = 
      case quoted_api do
        {list, _} when is_list(list) -> list
        {single, _} -> [single]
      end

    for {:::, _, [{f, _, args}, return]} <-api_defs do
      name =
        case f do
          _ when is_atom(f) -> f
          {:., _, [_, atom]} -> atom
        end
      {name, {f, args, return}}
    end
  end
    

  ## Use strings not Macro.to_string of quoted expression
  ## to have the comments in the template file.
  defp template(:eqc_statem, name, operators) do
  """
  defmodule #{name} do
    use ExUnit.Case
    use EQC.ExUnit
    use EQC.StateM

    ## -- Data generators -------------------------------------------------------


    ## -- State generation ------------------------------------------------------

    def initial_state() do
      %{}
    end

  #{Enum.map(operators, fn(op) -> operator(:eqc_statem, op) end)}
      
    weight _state, #{Enum.join(for {op,_}<-operators do "#{op}: 1" end, ", ")}
      
    @tag :show_states
    property "Registery" do
      forall cmds <- commands(__MODULE__) do
        cleanup()
        res = run_commands(cmds)
        pretty_commands(cmds, res,
          collect len: commands_length(cmds) do
            aggregate commands: command_names(cmds) do
              res[:result] == :ok
            end
          end)
      end
    end

    defp cleanup() do
      :ok
    end
  end
  """
  end
  defp template(other, _, _) do
    Mix.raise "Error: template for #{other} not yet available"
  end

  defp operator(_, {op, {f, args, return}}) do
    arity = length(args)
    argument_vars = for i<-:lists.seq(1,arity) do {String.to_atom("x#{i}"), [], Elixir} end
    argument_string = Macro.to_string(argument_vars)
    sutf =
      if f == op do
        ":ok"
      else
        Macro.to_string({f, [], argument_vars})
      end
    ## special case for atoms to be sure parenthesis are used if needed
    post =
    if is_atom(return) do
      """
      def #{op}_post(state, #{argument_string}, res) do
          satisfy res == #{return}
        end
      """
    else
      """
      def #{op}_post(state, #{argument_string}, _res) do
          true
        end
      """
    end
    
  """
    ## operation --- #{op} -------------------------------------------------------

    ## precondition for including op in the test sequence for present state
    def #{op}_pre(_state) do
      true
    end
      
    ## argument generators
    def #{op}_args(_state) do
      #{Macro.to_string(args)}
    end

    ## precondition on generated and shrunk arguments
    def #{op}_pre(_state, #{argument_string}) do
      true
    end
      
    ## implementation of the command under test
    def #{op}(#{Enum.join(for i<-:lists.seq(1,arity) do "x#{i}" end, ", ")}) do
      #{sutf}
    end

    ## the state update after the command has been performed
    def #{op}_next(state, _res, #{argument_string}) do
      state
    end
      
    ## the postconditions that should hold if command is performed in state state
    #{post}
   
  """
  end

end
