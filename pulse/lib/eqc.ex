
defmodule EQC do

defp eqc_forall(x, g, prop) do
  quote(do: :eqc.forall(unquote(g), fn unquote(x) -> unquote(prop) end))
end

defp eqc_bind(x, g, body) do
  quote(do: :eqc_gen.bind(unquote(g), fn unquote(x) -> unquote(body) end))
end

defmacro forAll({:<-, _, [x, g]}, do: prop) when prop != nil, do: eqc_forall(x, g, prop)
defmacro forAll(_, _),    do: syntaxError "forAll PAT <- GEN, do: PROP"
defmacro forAll(_, _, _), do: syntaxError "forAll PAT <- GEN, do: PROP"

defmacro let({:<-, _, [x, g]}, do: body) when body != nil, do: eqc_bind(x, g, body)
defmacro let(_, _),    do: syntaxError "let PAT <- GEN, do: GEN"
defmacro let(_, _, _), do: syntaxError "let PAT <- GEN, do: GEN"

defmacro suchThat({:<-, _, [x, g]}, do: pred) when pred != nil do
  loc = {__CALLER__.file, __CALLER__.line}
  quote do
    :eqc_gen.suchthat(unquote(g), fn unquote(x) -> unquote(pred) end, unquote(loc))
  end
end
defmacro suchThat(_, _),    do: syntaxError "suchThat PAT <- GEN, do: PRED"
defmacro suchThat(_, _, _), do: syntaxError "suchThat PAT <- GEN, do: PRED"

defmacro sized(n, prop) do
  quote(do: :eqc_gen.sized(fn unquote(n) -> unquote(prop) end))
end

defmacro shrink(g, gs) do
  quote(do: :eqc_gen.shrinkwith(unquote(g), fn -> unquote(gs) end))
end

defmacro letShrink({:<-, _, [es, gs]}, do: g) when g != nil do
  quote(do: :eqc_gen.letshrink(unquote(gs), fn unquote(es) -> unquote(g) end))
end
defmacro letShrink(_, _),    do: syntaxError "letShrink PAT <- GEN, do: GEN"
defmacro letShrink(_, _, _), do: syntaxError "letShrink PAT <- GEN, do: GEN"

defmacro whenFail(action, do: prop) when prop != nil do
  quote do
    :eqc.whenfail(fn eqcResult ->
        :erlang.put :eqc_result, eqcResult
        unquote(action)
      end, EQC.lazy(unquote(prop)))
  end
end
defmacro whenFail(_, _), do: syntaxError "whenFail ACTION, do: PROP"

defmacro lazy(g) do
  quote(do: :eqc_gen.lazy(fn -> unquote(g) end))
end

defmacro implies(pre, do: prop) when prop != nil do
  quote(do: :eqc.implies(unquote(pre), unquote(to_char_list(Macro.to_string(pre))), fn -> unquote(prop) end))
end
defmacro implies(_, _), do: syntaxError "implies COND, do: PROP"

defmacro trapExit(prop), do: quote(do: :eqc.trapexit(fn -> unquote(prop) end))

defmacro timeout(limit, do: prop) when prop != nil do
  quote(do: :eqc.timeout_property(unquote(limit), EQC.lazy(unquote(prop))))
end
defmacro timeout(_, _), do: syntaxError "timeout TIME, do: PROP"

defmacro always(n, do: prop) when prop != nil do
  quote(do: :eqc.always(unquote(n), fn -> unquote(prop) end))
end
defmacro always(_, _), do: syntaxError "always N, do: PROP"

defmacro sometimes(n, do: prop) when prop != nil do
  quote(do: :eqc.sometimes(unquote(n), fn -> unquote(prop) end))
end
defmacro sometimes(_, _), do: syntaxError "sometimes N, do: PROP"

defmacro setup(fun, do: prop) when prop != nil do
  quote(do: {:eqc_setup, unquote(fun), EQC.lazy(unquote(prop))})
end
defmacro setup(_, _), do: syntaxError "setup SETUP, do: PROP"

defp syntaxError(err), do: raise(ArgumentError, "Syntax: " <> err)

end
