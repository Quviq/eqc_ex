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
    @compile {:parse_transform, :eqc_transform_callouts}
  end
end

# -- Callout language -------------------------------------------------------

def call(mod, fun, args), do: {:self_callout, mod, fun, args}
defmacro call(fun, args) do
  quote do
    call(__MODULE__, unquote(fun), unquote(args))
  end
end
defmacro call({{:., _, [mod, fun]}, _, args}) do
  quote do call(unquote(mod), unquote(fun), unquote(args)) end
end
defmacro call({fun, _, args}) when is_atom(fun) do
  quote do call(__MODULE__, unquote(fun), unquote(args)) end
end
defmacro call(_), do: raise(ArgumentError, "Usage: call F(E1, .., En)")

def callout(mod, fun, args, res), do: :eqc_component.callout(mod, fun, args, res)

defmacro callout({{:., _, [mod, fun]}, _, args}, [return: res]) do
  quote do callout(unquote(mod), unquote(fun), unquote(args), unquote(res)) end
end

defp do_match(e) do
  quote do {:"$eqc_callout_match", unquote(e)} end
end

defp do_match_gen(e) do
  quote do {:"$eqc_callout_match_gen", unquote(e)} end
end

defmacro match(e={:=,  _, [_, _]}), do: do_match(e)
defmacro match(e={:<-, _, [_, _]}), do: do_match_gen(e)
defmacro match(_), do: raise(ArgumentError, "Usage: match PAT = EXP, or match PAT <- GEN")

# Hacky. Let's you write (for instance) match pat = case exp do ... end.
defmacro match({:=, cxt1, [pat, {fun, cxt2, args}]}, opts) do
  do_match({:=, cxt1, [pat, {fun, cxt2, args ++ opts}]})
end

def fail(e), do: {:fail, e}

defmacro exception(e) do
  quote do {:"$eqc_exception", unquote(e)} end
end

# -- Wrapper functions ------------------------------------------------------

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
