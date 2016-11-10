defmodule Mix.Tasks.Eqc.Template do
  use Mix.Task

  @shortdoc "Create template for Quviq QuickCheck models"

  @moduledoc """
  A Mix task for creating a template for a specific QuickCheck model.

  ## Options

     * `--model model` - creates a QuickCheck model (default eqc_statem).
     * `--dir directory` - puts the created file into directory (default first path in :test_paths project parameter). 

  ## Examples

      mix eqc.template --model eqc_statem model_eqc.exs
      mix eqc.template --model eqc_component eqc/comp_eqc.exs
      mix eqc.template --dir test model_eqc.exs

  """
  @switches [dir: :string, model: :atom]

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


    model = opts[:model] || :eqc_statem
    content = template(model, name)
    
    case file do
      "" ->
        ## on screen
        IO.inspect content
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


  defp template(:eqc_statem, name) do
   """
    defmodule #{name} do
      use ExUnit.Case
      use EQC.ExUnit
      use EQC.StateM

      def initial_state() do
        %{}
      end

      ## operation --- op ------------------------------------------------------------

      ## precondition for including op in the test sequence for present state
      def op_pre(_state) do
        true
      end
      
      ## argument generators
      def op_args(_state) do
        [ int() ]
      end

      ## precondition on generated and shrunk arguments
      def op_pre(_state, [_n]) do
        true
      end
      
      ## implementation of the opertion under test
      def op(n) do
        n
      end

      ## the state update after the operation has been performed
      def op_next(state, _res, [_n]) do
        state
      end
      
      ## the postconditions that should hold if operation op is performed in state state
      def op_post(state, [_n]) do
        true
      end
      
      weight _state, op: 1
      
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
  defp template(other, _) do
    Mix.raise "Error: template for #{other} not yet available"
  end

end
