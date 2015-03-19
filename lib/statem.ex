defmodule EQC.StateM do
		
	defmacro __using__(_opts) do
    quote do
			import EQC
			import :eqc_gen
			import EQC.StateM

			@file "eqc_statem.hrl"
			@compile {:parse_transform, :eqc_group_commands}
		end
  end

	defmacro eq(a,b) do
		quote do
			:eqc_statem.eq(unquote(a),unquote(b))
		end
	end

	def commands(mod) do :eqc_statem.commands(mod) end
	
	def commands(mod, initial_state) do
		:eqc_statem.commands(mod, initial_state) end

	def run_commands(mod, cmds) do
		run_commands(mod, cmds, []) end

	def run_commands(mod, cmds, env) do
		{history, state, result} = :eqc_statem.run_commands(mod, cmds, env)
		[history: history, state: state, result: result]
	end

	def parallel_commands(mod) do
		:eqc_statem.parallel_commands(mod) end

	defmacro parallel_commands(mod, initial_state) do
		:eqc_statem.parallel_commands(mod, initial_state)	end
	
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
	
end
