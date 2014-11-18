
defmodule EQC.Pulse do

defmacro instrument do
  quote do
    @compile {:parse_transform, :pulse_instrument}
  end
end

defmacro replaceModule(old, with: new) do
  quote(do: @compile {:pulse_replace_module, [{unquote(old), unquote(new)}]})
end

defp skip_funs({f, a}) when is_atom(f) and is_integer(a), do: [{f, a}]
defp skip_funs({{f, _, nil}, a}) when is_atom(f) and is_integer(a), do: [{f, a}]
defp skip_funs({:/, _, [f, a]}), do: skip_funs({f, a})
defp skip_funs(xs) when is_list(xs), do: :lists.flatmap(&skip_funs/1, xs)
defp skip_funs(other) do
  raise ArgumentError, "Expected list of FUN/ARITY or {FUN, ARITY}."
end

defmacro skipFunction(skip) do
  quote(do: @compile {:pulse_skip, unquote(skip_funs(skip))})
end

defp mk_blank({:_, _, _}), do: :_
defp mk_blank(x),          do: x

defp side_effects(es) when is_list(es), do: :lists.flatmap(&side_effects/1, es)
defp side_effects({:/, _, [{{:., _, [m, f]}, _, []}, a]}), do: side_effects({m, f, a})
defp side_effects({m, f, a}), do: [{:{}, [], [m, mk_blank(f), mk_blank(a)]}]
defp side_effects(other) do
  raise ArgumentError, "Expected list of {MOD, FUN, ARITY} or MOD.FUN/ARITY."
end

defmacro sideEffect(es) do
  quote(do: @compile {:pulse_side_effect, unquote(side_effects(es))})
end

defmacro noSideEffect(es) do
  quote(do: @compile {:pulse_no_side_effect, unquote(side_effects(es))})
end

defmacro withPulse(do: action, after: clauses) do
  res = Macro.var :res, __MODULE__
  quote do
    :eqc.forall(:pulse.seed(),
      fn seed ->
        unquote(res) = :pulse.run_with_seed(fn -> unquote(action) end, seed)
        unquote({:case, [], [res, [do: clauses]]})
      end)
  end
end
defmacro withPulse(_) do
  raise(ArgumentError, "Syntax: withPulse do: ACTION, after: (RES -> PROP)")
end

end
