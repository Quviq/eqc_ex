defmodule EQC.StateM do

  defmacro __using__(_opts) do
    quote do
      import :eqc_statem, only: [commands: 1, commands: 2,
                                 parallel_commands: 1, parallel_commands: 2,
                                 eq: 2, command_names: 1]
      import EQC.StateM

      @file "eqc_statem.hrl"
      @compile {:parse_transform, :eqc_group_commands}
    end
  end

  def run_commands(mod, cmds) do
    run_commands(mod, cmds, []) end

  def run_commands(mod, cmds, env) do
    {history, state, result} = :eqc_statem.run_commands(mod, cmds, env)
    [history: history, state: state, result: result]
  end

  def run_parallel_commands(mod, cmds) do
    run_parallel_commands(mod, cmds, []) end

  def run_parallel_commands(mod, cmds, env) do
    {history, state, result} = :eqc_statem.run_parallel_commands(mod, cmds, env)
    [history: history, state: state, result: result]
  end

  def pretty_commands(mod, cmds, res, bool) do
    :eqc_statem.pretty_commands(mod, cmds,
                                {res[:history], res[:state], res[:result]},
                                bool)
  end

  def check_commands(mod, cmds, run_result) do
    check_commands(mod, cmds, run_result, []) end

  def check_commands(mod, cmds, res, env) do
    :eqc_statem.check_commands(mod, cmds,
                               {res[:history], res[:state], res[:result]},
                               env)
  end

  defmacro weight(state, cmds) do
    for {cmd, w} <- cmds do
      quote do
        def weight(unquote(state), unquote(cmd)) do unquote(w) end
      end
    end ++
      [ quote do
          def weight(unquote(state), _) do 1 end
        end ]
  end

  defmacro symcall({{:., _, [mod, fun]}, _, args}) do
    quote do
      {:call, unquote(mod), unquote(fun), unquote(args)}
    end
  end

  defmacro symcall({fun, _, args}) do
    quote do
      {:call, __MODULE__, unquote(fun), unquote(args)}
    end
  end
end
