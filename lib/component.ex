defmodule EQC.Component do
  @copyright "Quviq AB, 2014-2015"

  @moduledoc """
  This module contains macros to be used with [Quviq
  QuickCheck](http://www.quviq.com). It defines Elixir versions of the Erlang
  macros found in `eqc/include/eqc_component.hrl`. For detailed documentation of the
  macros, please refer to the QuickCheck documentation.

  `Copyright (C) Quviq AB, 2014-2015.`
  """

  defmacro __using__(_opts) do
    quote do
      import :eqc_component, only: [commands: 1, commands: 2]
      import :eqc_statem, only: [eq: 2, command_names: 1]
      import EQC.Component
      import EQC.Component.Callouts

      @file "eqc_component.hrl"
      @compile {:parse_transform, :eqc_group_commands}
      @compile {:parse_transform, :eqc_transform_callouts}
    end
  end

  # -- Wrapper functions ------------------------------------------------------

  @doc """
  Same as `:eqc_component.run_commands/2` but returns a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple.
  """
  def run_commands(mod, cmds) do
    run_commands(mod, cmds, []) end

  @doc """
  Same as `:eqc_component.run_commands/3` but returns a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple.
  """
  def run_commands(mod, cmds, env) do
    {history, state, result} = :eqc_component.run_commands(mod, cmds, env)
    [history: history, state: state, result: result]
  end

  @doc """
  Same as `:eqc_component.pretty_commands/4` but takes a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple as the third argument.
  """
  def pretty_commands(mod, cmds, res, bool) do
    :eqc_component.pretty_commands(mod, cmds,
                                {res[:history], res[:state], res[:result]},
                                bool)
  end

  @doc """
  Generate a weight function given a keyword list of command names and weights.

  Usage:

      weight state,
        cmd1: weight1,
        cmd2: weight2

  Commands not in the list get weight 1.
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
end
