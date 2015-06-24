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
  defmacro call(c) do
    _ = c
    syntax_error "call F(E1, .., En)"
  end

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
  defmacro callout(call, opts) do
    _ = {call, opts}
    syntax_error "callout MOD.FUN(ARG1, .., ARGN), return: RES"
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
  defmacro match(e) do
    _ = e
    syntax_error "match PAT = EXP, or match PAT <- GEN"
  end

  # Hacky. Let's you write (for instance) match pat = case exp do ... end.
  @doc false
  defmacro match({:=, cxt1, [pat, {fun, cxt2, args}]}, opts) do
    do_match({:=, cxt1, [pat, {fun, cxt2, args ++ [opts]}]})
  end
  defmacro match({:<-, cxt1, [pat, {fun, cxt2, args}]}, opts) do
    do_match({:<-, cxt1, [pat, {fun, cxt2, args ++ [opts]}]})
  end
  defmacro match(_, _), do: syntax_error "match PAT = EXP, or match PAT <- GEN"

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

  @doc """
  Model sending a message.

  In Erlang: `?SEND(Pid, Msg)`
  """
  def send(pid, msg), do: callout(:erlang, :send, [pid, msg], msg)

  @doc """
  Specify the result of an operation.

  In Erlang: `?RET(X)`
  """
  def ret(x), do: {:return, x}

  @doc """
  Run-time assertion.

  In Erlang: `?ASSERT(Mod, Fun, Args)`
  """
  defmacro assert(mod, fun, args) do
    loc = {__CALLER__.file, __CALLER__.line}
    quote do
      {:assert, unquote(mod), unquote(fun), unquote(args),
        {:assertion_failed, unquote(mod), unquote(fun), unquote(args), unquote(loc)}}
    end
  end

  @doc """
  Convenient syntax for assert.

  Usage:

      assert mod.fun(e1, .., en)
  """
  defmacro assert({{:., _, [mod, fun]}, _, args}) do
    quote do assert(unquote(mod), unquote(fun), unquote(args)) end
  end
  defmacro assert(call) do
    _ = call
    syntax_error "assert MOD.FUN(ARG1, .., ARGN)"
  end

  @doc """
  Get access to (part of) an argument to a callout. For instance,

      match {val, :ok} = callout :mock.foo(some_arg, __VAR__), return: :ok
      ...

  Argument values are returned in a tuple with the return value.

  Use `:_` to ignore a callout argument.

  In Erlang: `?VAR`
  """
  defmacro __VAR__, do: :"$var"

  @doc """
  Access the pid of the process executing an operation.

  In Erlang: `?SELF`
  """
  defmacro __SELF__, do: :"$self"

  @doc """
  A list of callout specifications in sequence.

  In Erlang: `?SEQ`
  """
  def seq(list), do: {:seq, list}

  @doc """
  A list of callout specications arbitrarily interleaved.

  In Erlang: `?PAR`
  """
  def par(list), do: {:par, list}

  @doc """
  A choice between two different callout specifications.

  In Erlang: `?EITHER(Tag, C1, C2)`
  """
  def either(c1, c2), do: {:xalt, c1, c2}

  @doc """
  A choice between two different callout specifications where every choice with
  the same tag has to go the same way (left or right).

  In Erlang: `?EITHER(Tag, C1, C2)`
  """
  def either(tag, c1, c2), do: {:xalt, tag, c1, c2}

  @doc """
  An optional callout specification. Equivalent to `either(c, :empty)`.

  In Erlang: `?OPTIONAL(C)`
  """
  def optional(c), do: either(c, :empty)

  @doc """
  Specify a blocking operation.

  In Erlang: `?BLOCK(Tag)`
  """
  def block(tag), do: {:"$eqc_block", tag}

  @doc """
  Equivalent to block(__SELF__).

  In Erlang: `?BLOCK`
  """
  def block(), do: block(__SELF__)

  @doc """
  Unblocking a blocked operation.

  In Erlang: `?UNBLOCK(Tag, Res)`
  """
  def unblock(tag, res), do: {:unblock, tag, res}

  @doc """
  Conditional callout specification.

  Usage:

      guard g, do: c

  Equivalent to:

      case g do
        true  -> c
        false -> :empty
      end

  In Erlang: `?WHEN(G, C)`
  """
  defmacro guard(g, do: c) do
    quote do
      case unquote(g) do
        true  -> unquote(c)
        false -> :empty
      end
    end
  end
  defmacro guard(g, c) do
    _ = {g, c}
    syntax_error "guard GUARD, do: CALLOUTS"
  end

  @doc """
  Indicate that the following code is using the callout specification language.

  This is default for the `_callouts` callback, but this information is lost in
  some constructions like list comprehensions or `par/1` calls.

  Usage:

      callouts do
        ...
      end

  In Erlang: `?CALLOUTS(C1, .., CN)`
  """
  defmacro callouts(do: {:__block__, cxt, args}), do: {:"$eqc_callout_quote", cxt, args}
  defmacro callouts(do: c), do: {:"$eqc_callout_quote", [], [c]}
  defmacro callouts(c) do
    _ = c
    syntax_error "callouts do CALLOUTS end"
  end

  defp syntax_error(err), do: raise(ArgumentError, "Usage: " <> err)
end
