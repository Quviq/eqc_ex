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
                                 eq: 2, # use EQC.satisfy instead
                                 more_commands: 2,
                                 commands_length: 1]
      import EQC.StateM

      @file "eqc_statem.hrl"
      @compile {:parse_transform, :eqc_group_commands}
    end
  end

  @doc """
  Same as `:eqc_statem.run_commands/2` but returns a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple.
  """
  def run_commands(mod, cmds) do
    run_commands(mod, cmds, []) end

  @doc """
  Same as `:eqc_statem.run_commands/3` but returns a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple.
  """
  def run_commands(mod, cmds, env) do
    {history, state, result} = :eqc_statem.run_commands(mod, cmds, env)
    [history: history, state: state, result: result]
  end

  @doc """
  Same as `:eqc_statem.run_parallel_commands/2` but returns a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple. Note that there is no
  actual final state in this case.
  """
  def run_parallel_commands(mod, cmds) do
    run_parallel_commands(mod, cmds, []) end

  @doc """
  Same as `:eqc_statem.run_parallel_commands/3` but returns a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple. Note that there is no
  actual final state in this case.
  """
  def run_parallel_commands(mod, cmds, env) do
    {history, state, result} = :eqc_statem.run_parallel_commands(mod, cmds, env)
    [history: history, state: state, result: result]
  end

  @doc """
  Same as `:eqc_statem.pretty_commands/4` but uses a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple.
  """
  def pretty_commands(mod, cmds, res, bool) do
    :eqc_statem.pretty_commands(mod, cmds,
                                {res[:history], res[:state], res[:result]},
                                bool)
  end

  @doc """
  Same as `:eqc_statem.check_commands/3` but uses a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple.
  """
  def check_commands(mod, cmds, run_result) do
    check_commands(mod, cmds, run_result, []) end

  @doc """
  Same as `:eqc_statem.check_commands/4` but uses a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple.
  """
  def check_commands(mod, cmds, res, env) do
    :eqc_statem.check_commands(mod, cmds,
                               {res[:history], res[:state], res[:result]},
                               env)
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
          def weight(unquote(state), _) do 1 end
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
end
