defmodule EQC.Cluster do
  @copyright "Quviq AB, 2014-2016"

  @moduledoc """
  This module contains macros to be used with [Quviq
  QuickCheck](http://www.quviq.com). It defines Elixir versions of the Erlang
  macros found in `eqc/include/eqc_cluster.hrl`. For detailed documentation of the
  macros, please refer to the QuickCheck documentation.

  `Copyright (C) Quviq AB, 2014-2016.`
  """

  defmacro __using__(_opts) do
    quote do
      import :eqc_cluster, only: [commands: 1, commands: 2, adapt_commands: 2, state_after: 2,
                                  api_spec: 1]     
      import :eqc_statem,  only: [eq: 2, command_names: 1, more_commands: 2]
      import :eqc_mocking, only: [start_mocking: 2, stop_mocking: 0]

      import EQC.Cluster
      @tag eqc_callback: :eqc_cluster
      
    end
  end

  # -- Wrapper functions ------------------------------------------------------

  @doc """
  Same as `:eqc_cluster.run_commands/2` but returns a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple.
  """
  def run_commands(mod, cmds) do
    run_commands(mod, cmds, []) end

  @doc """
  Same as `:eqc_cluster.run_commands/3` but returns a keyword list with
  `:history`, `:state`, and `:result` instead of a tuple.
  """
  def run_commands(mod, cmds, env) do
    {history, state, result} = :eqc_cluster.run_commands(mod, cmds, env)
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
  Generate a weight function given a keyword list of component names and weights.

  Usage:

      weight component1: weight1, component2: weight2

  Components not in the list get weight 1.
  """
  defmacro weight(cmds) do
    for {cmd, w} <- cmds do
      quote do
        def weight(unquote(cmd)) do unquote(w) end
      end
    end ++
      [ quote do
          def weight(_) do 1 end
        end ]
  end
end
