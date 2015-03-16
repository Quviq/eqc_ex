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

	defmacro commands(mod) do
		quote do
			:eqc_statem.commands(unquote(mod))
		end
	end

	defmacro commands(mod, initial_state) do
		quote do
			:eqc_statem.commands(unquote(mod), unquote(initial_state))
		end
	end

	defmacro run_commands(mod, cmds) do
		quote do
			{history, state, result} = :eqc_statem.run_commands(unquote(mod), unquote(cmds))
			[history: history, state: state, result: result]

		end
	end

	defmacro run_commands(mod, cmds, env) do
		quote do
			{history, state, result} = :eqc_statem.run_commands(unquote(mod), unquote(cmds), unquote(env))
			[history: history, state: state, result: result]
		end
	end

	defmacro parallel_commands(mod) do
		quote do
			:eqc_statem.parallel_commands(unquote(mod))
		end
	end

	defmacro parallel_commands(mod, initial_state) do
		quote do
			:eqc_statem.parallel_commands(unquote(mod), unquote(initial_state))
		end
	end
	
	defmacro run_parallel_commands(mod, cmds) do
		quote do
			{history, state, result} = :eqc_statem.run_parallel_commands(unquote(mod), unquote(cmds))
			[history: history, state: state, result: result]

		end
	end

	defmacro run_parallel_commands(mod, cmds, env) do
		quote do
			{history, state, result} = :eqc_statem.run_parallel_commands(unquote(mod), unquote(cmds), unquote(env))
			[history: history, state: state, result: result]
		end
	end
	
	defmacro pretty_commands(mod, cmds, run_result, bool) do
		quote do
			res = unquote(run_result)
			:eqc_statem.pretty_commands(unquote(mod), unquote(cmds),
																	{res[:history], res[:state], res[:result]},
																	unquote(bool))
		end
	end

	defmacro check_commands(mod, cmds, run_result) do
		quote do
			res = unquote(run_result)
			:eqc_statem.check_commands(unquote(mod), unquote(cmds),
																	{res[:history], res[:state], res[:result]})
		end
	end

	defmacro check_commands(mod, cmds, run_result, env) do
		quote do
			res = unquote(run_result)
			:eqc_statem.check_commands(unquote(mod), unquote(cmds),
																	{res[:history], res[:state], res[:result]},
																	unquote(env))
		end
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
