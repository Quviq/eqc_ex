defmodule EQC.Pulse do
  @copyright "Quviq AB, 2014"

  @moduledoc """
  This module defines macros for using Quviq PULSE with Elixir. For more
  information about the compiler options see the QuickCheck documentation.

  See also the [`pulse_libs`](http://hex.pm/packages/pulse_libs) package for
  instrumented versions of some of the Elixir standard libraries.

  `Copyright (C) Quviq AB, 2014.`
  """

  defmacro __using__([]) do
    quote(do: EQC.Pulse.instrument)
  end

  @doc """
  Instrument the current file with PULSE.

  Equivalent to

      @compile {:parse_transform, :pulse_instrument}
  """
  defmacro instrument do
    quote do
      @compile {:parse_transform, :pulse_instrument}
    end
  end

  @doc """
  Replace a module when instrumenting.

  Usage:

      replace_module old, with: new

  This will replace calls `old.f(args)` by `new.f(args)`. Note: it will not
  replace instances of `old` used as an atom. For instance `spawn old, :f,
  args` will not be changed.

  Equivalent to

      @compile {:pulse_replace_module, [{old, new}]}
  """
  defmacro replace_module(old, with: new) when new != nil do
    quote(do: @compile {:pulse_replace_module, [{unquote(old), unquote(new)}]})
  end
  defmacro replace_module(old, opts) do
    _ = {old, opts}
    raise ArgumentError, "Usage: replace_module NEW, with: OLD"
  end

  defp skip_funs({f, a}) when is_atom(f) and is_integer(a), do: [{f, a}]
  defp skip_funs({{f, _, nil}, a}) when is_atom(f) and is_integer(a), do: [{f, a}]
  defp skip_funs({:/, _, [f, a]}), do: skip_funs({f, a})
  defp skip_funs(xs) when is_list(xs), do: :lists.flatmap(&skip_funs/1, xs)
  defp skip_funs(_) do
    raise ArgumentError, "Expected list of FUN/ARITY."
  end

  @doc """
  Skip instrumentation of the given functions.

  Example:

      skip_function [f/2, g/0]

  Equivalent to

      @compile {:pulse_skip, [{:f, 2}, {:g, 0}]}
  """
  defmacro skip_function(funs) do
    quote(do: @compile {:pulse_skip, unquote(skip_funs(funs))})
  end

  defp mk_blank({:_, _, _}), do: :_
  defp mk_blank(x),          do: x

  defp side_effects(es) when is_list(es), do: :lists.flatmap(&side_effects/1, es)
  defp side_effects({:/, _, [{{:., _, [m, f]}, _, []}, a]}), do: side_effects({m, f, a})
  defp side_effects({m, f, a}), do: [{:{}, [], [m, mk_blank(f), mk_blank(a)]}]
  defp side_effects(_) do
    raise ArgumentError, "Expected list of MOD.FUN/ARITY."
  end

  @doc """
  Declare side effects.

  Example:

      side_effect [Mod.fun/2, :ets._/_]

  Equivalent to

      @compile {:pulse_side_effect, [{Mod, :fun, 2}, {:ets, :_, :_}]}
  """
  defmacro side_effect(es) do
    quote(do: @compile {:pulse_side_effect, unquote(side_effects(es))})
  end

  @doc """
  Declare functions to not be effectful.

  Useful to override `side_effect/1`. For instance,

      side_effect    :ets._/_
      no_side_effect :ets.is_compiled_ms/1

  The latter line is quivalent to

      @compile {:pulse_no_side_effect, [{:ets, :is_compiled_ms, 1}]}
  """
  defmacro no_side_effect(es) do
    quote(do: @compile {:pulse_no_side_effect, unquote(side_effects(es))})
  end

  @doc """
  Define a QuickCheck property that uses PULSE.

  Usage:

      with_pulse do
        action
      after res ->
        prop
      end

  Equivalent to

      forall seed <- :pulse.seed do
        case :pulse.run_with_seed(fn -> action end, seed) do
          res -> prop
        end
      end
  """
  defmacro with_pulse(do: action, after: clauses) when action != nil and clauses != nil do
    res = Macro.var :res, __MODULE__
    quote do
      :eqc.forall(:pulse.seed(),
        fn seed ->
          unquote(res) = :pulse.run_with_seed(fn -> unquote(action) end, seed)
          unquote({:case, [], [res, [do: clauses]]})
        end)
    end
  end
  defmacro with_pulse(opts) do
    _ = opts
    raise(ArgumentError, "Syntax: with_pulse do: ACTION, after: (RES -> PROP)")
  end
end
