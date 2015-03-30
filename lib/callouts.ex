defmodule EQC.Component.Callouts do
@copyright "Quviq AB, 2015"

@moduledoc """
This module contains functions to be used with [Quviq
QuickCheck](http://www.quviq.com). It defines an Elixir version of the callout
language found in `eqc/include/eqc_component.hrl`. For detailed documentation
of the macros, please refer to the QuickCheck documentation.

`Copyright (C) Quviq AB, 2014-2015.`
"""

@doc """
Call a command from a callout.

In Erlang: `?APPLY(Mod, Fun, Args)`.
"""
def call(mod, fun, args), do: {:self_callout, mod, fun, args}

@doc """
Call a local command from a callout.

In Erlang: `?APPLY(Fun, Args)`.
"""
defmacro call(fun, args) do
  quote do
    call(__MODULE__, unquote(fun), unquote(args))
  end
end

@doc """
Convenient syntax for `call`.

    call m.f(e1, .., en)
    call f(e1, .., en)

is equivalent to

    call(m, f, [e1, .., en])
    call(f, [e1, .., en])
"""
defmacro call({{:., _, [mod, fun]}, _, args}) do
  quote do call(unquote(mod), unquote(fun), unquote(args)) end
end
defmacro call({fun, _, args}) when is_atom(fun) do
  quote do call(__MODULE__, unquote(fun), unquote(args)) end
end
defmacro call(_), do: raise(ArgumentError, "Usage: call F(E1, .., En)")

@doc """
Specify a callout.

In Erlang: `?CALLOUT(Mod, Fun, Args, Res)`.
"""
def callout(mod, fun, args, res), do: :eqc_component.callout(mod, fun, args, res)

@doc """
Convenient syntax for `callout`.

    callout m.f(e1, .., en), return: res

is equivalent to

    callout(m, f, [e1, .., en], res)
"""
defmacro callout({{:., _, [mod, fun]}, _, args}, [return: res]) do
  quote do callout(unquote(mod), unquote(fun), unquote(args), unquote(res)) end
end

defp do_match(e) do
  quote do {:"$eqc_callout_match", unquote(e)} end
end

defp do_match_gen(e) do
  quote do {:"$eqc_callout_match_gen", unquote(e)} end
end

@doc """
Bind the result of a callout or generator.

Usage:

    match pat = exp
    match pat <- gen

In Erlang: `?MATCH(Pat, Exp)` or `?MATCH_GEN(Pat, Gen)`.
"""
defmacro match(e={:=,  _, [_, _]}), do: do_match(e)
defmacro match(e={:<-, _, [_, _]}), do: do_match_gen(e)
defmacro match(_), do: raise(ArgumentError, "Usage: match PAT = EXP, or match PAT <- GEN")

# Hacky. Let's you write (for instance) match pat = case exp do ... end.
@doc false
defmacro match({:=, cxt1, [pat, {fun, cxt2, args}]}, opts) do
  do_match({:=, cxt1, [pat, {fun, cxt2, args ++ [opts]}]})
end
defmacro match({:<-, cxt1, [pat, {fun, cxt2, args}]}, opts) do
  do_match({:<-, cxt1, [pat, {fun, cxt2, args ++ [opts]}]})
end

@doc """
Model failure.

In Erlang: `?FAIL(E)`.
"""
def fail(e), do: {:fail, e}

@doc """
Exception return value. Can be used as the return value for a callout to make it throw an exception.

In Erlang: `?EXCEPTION(e)`.
"""
defmacro exception(e) do
  quote do {:"$eqc_exception", unquote(e)} end
end

end
