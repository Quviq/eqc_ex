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

			@file "eqc_component.hrl"
			@compile {:parse_transform, :eqc_group_commands}
		end
  end

	def run_commands(mod, cmds) do
		run_commands(mod, cmds, []) end

	def run_commands(mod, cmds, env) do
		{history, state, result} = :eqc_component.run_commands(mod, cmds, env)
		[history: history, state: state, result: result]
	end
	
	def pretty_commands(mod, cmds, res, bool) do
		:eqc_component.pretty_commands(mod, cmds,
																{res[:history], res[:state], res[:result]},
																bool)
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
	
end
