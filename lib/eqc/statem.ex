defmodule EQC.StateM do
  @moduledoc """
  This module contains macros to be used with [Quviq
  QuickCheck](http://www.quviq.com). It defines Elixir versions of Erlang
  functions found in `eqc/include/eqc_statem.hrl`. For detailed documentation of the
  functions, please refer to the QuickCheck documentation.

  `Copyright (C) Quviq AB, 2014-2016.`
  """
  
  defmacro __using__(_opts) do
    quote do
      import :eqc_statem, only: [commands: 1, commands: 2,
                                 parallel_commands: 1, parallel_commands: 2,
                                 more_commands: 2,
                                 commands_length: 1]
      import EQC.StateM

      @file "eqc_statem.hrl"
      @compile {:parse_transform, :eqc_group_commands}
      @tag eqc_callback: :eqc_statem
      
    end
  end

  @doc """
  Runs a state machine generated command sequence and returns a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple.
  """
  def run_commands(cmds) do
    run_commands(cmds, [])
  end
  
  @doc """
  Runs a state machine generated command sequence where vairables in this
  sequence are substituted by a Keyword list defined context.
  Returns a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple.
  """
  def run_commands(cmds, env) do
    {history, state, result} = :eqc_statem.run_commands(cmds, env)
    [history: history, state: state, result: result]
  end

  @doc false
  # deprecated
  def run_commands(mod, cmds, env) do
    {history, state, result} = :eqc_statem.run_commands(mod, cmds, env)
    [history: history, state: state, result: result]
  end


  @doc """
  Runs a state machine generated parallel command sequenceand returns a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple. Note that there is no
  actual final state in this case.
  """
  def run_parallel_commands(cmds) do
    {history, state, result} = :eqc_statem.run_parallel_commands(cmds)
    [history: history, state: state, result: result]
  end
  
  @doc """
  Runs a state machine generated parallel command sequence where vairables in this
  sequence are substituted by a Keyword list defined context.
  Returns a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple. Note that there is no
  actual final state in this case.
  """
  def run_parallel_commands(cmds, env) do
    {history, state, result} = :eqc_statem.run_parallel_commands(cmds, env)
    [history: history, state: state, result: result]
  end

  @doc false
  # deprecated
  def run_parallel_commands(mod, cmds, env) do
    {history, state, result} = :eqc_statem.run_parallel_commands(mod, cmds, env)
    [history: history, state: state, result: result]
  end

  @doc """
  When a test case fails, this pretty prints the failing test case.
  """
  def pretty_commands(cmds, res, bool)
  def pretty_commands([{:model, m} | cmds], res, bool) do
    :eqc_gen.with_parameter(:elixir, :true,
    :eqc_statem.pretty_commands(m, [{:model, m} | cmds],
                                {res[:history], res[:state], res[:result]},
                                bool))
  end


  @doc false
  # deprecated
  def pretty_commands(mod, cmds, res, bool) do
    :eqc_gen.with_parameter(:elixir, :true,
    :eqc_statem.pretty_commands(mod, cmds,
                                {res[:history], res[:state], res[:result]},
                                bool))
  end

  @doc false
  # deprecated
  def check_commands(mod, cmds, run_result) do
    check_commands(mod, cmds, run_result, []) end

  @doc false
  # deprecated
  def check_commands(mod, cmds, res, env) do
    :eqc_gen.with_parameter(:elixir, :true,
    :eqc_statem.check_commands(mod, cmds,
                               {res[:history], res[:state], res[:result]},
                               env))
  end

  @doc """
  Add weights to the commands in a statem specification

  ## Example

      weight _, take: 10, reset: 1
      # Choose 10 times more 'take' than 'reset'

      weight s, take: 10, reset: s
      # The more tickets taken, the more likely reset becomes
  """
  defmacro weight(state, cmds) do
    for {cmd, w} <- cmds do
      quote do
        def weight(unquote(state), unquote(cmd)) do unquote(w) end
      end
    end ++
      [ quote do
          def weight(_, _) do 1 end
        end ]
  end

  @doc """
  Same as `:eqc_statem.command_names/1` but replaces the module name to Elixir style.
  """
  def command_names(cmds) do
    for {m, f, as} <- :eqc_statem.command_names(cmds) do
      {String.to_atom(Enum.join(Module.split(m), ".")), f, as}
    end
  end

  
  @doc """
  Converts the given call expression into a symbolic call.

  ## Examples

      symcall extract_pid(result)
      # {:call, __MODULE__, :extract_pid, [result]}

      symcall OtherModule.do_something(result, args)
      # {:call, OtherModule, :do_something, [result, args]}
  """
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
  
  defp replace_var([], binding, seq) do
    {Enum.reverse(seq), binding}
  end
  defp replace_var([{:=, _, [{var, _, _}, {{:., _, [mod, fun]}, _, args}]} | cmds], binding, seq) do
    freshvar = {:var, length(seq) + 1}
    {callargs, _} = Code.eval_quoted(args, binding, __ENV__)
    symbcmd = quote do {:set, unquote(freshvar),
                        {:call, unquote(mod), unquote(fun), unquote(callargs)}} end
    replace_var(cmds, [{var, freshvar}|binding], [symbcmd|seq])
  end
  defp replace_var([{{:., _, [mod, fun]}, _, args} | cmds], binding, seq) do
    freshvar = {:var, length(seq) + 1}
    {callargs, _} = Code.eval_quoted(args, binding, __ENV__)
    symbcmd = quote do {:set, unquote(freshvar),
                        {:call, unquote(mod), unquote(fun), unquote(callargs)}} end
    replace_var(cmds, binding, [symbcmd|seq])
  end
  defp replace_var([{:=, _, [{var, _, _}, {fun, _, args}]} | cmds], binding, seq) do
    freshvar = {:var, length(seq) + 1}
    {callargs, _} = Code.eval_quoted(args, binding, __ENV__)
    symbcmd = quote do {:set, unquote(freshvar),
                        {:call, Macro.escape(__MODULE__), unquote(fun), unquote(callargs)}} end
    replace_var(cmds, [{var, freshvar}|binding], [symbcmd|seq])
  end
   defp replace_var([{fun, _, args} | cmds], binding, seq) when is_atom(fun) do
    freshvar = {:var, length(seq) + 1}
    {callargs, _} = Code.eval_quoted(args, binding, __ENV__)
    symbcmd = quote do {:set, unquote(freshvar),
                        {:call, Macro.escape(__MODULE__), unquote(fun), unquote(callargs)}} end
    replace_var(cmds, binding, [symbcmd|seq])
  end

    

  @doc """
  Translates test cases of a specific format into a list of commands that is compatible with 
  `EQC.StateM`.

  ## Examples

        @check same_seat: [
                   eqc_test do
                      v1 = book("business")
                      book("economy")
                      checkin(2, v1)
                      bookings()
                   end ]

  """
  defmacro eqc_test([do: cmds]) do
    commands = case cmds do
                 {:__block__, _, block} -> block
                 nil -> []
                 cmd -> [cmd]
               end
    {new_commands, _binding} =
      replace_var(commands, [], [])
    quote do
      [ {:model, __MODULE__} | unquote(new_commands) ]
    end
  end
    
    
    

  
end
