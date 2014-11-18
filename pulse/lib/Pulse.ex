
defmodule Pulse do

defmacro instrument do
  quote do
    @compile {:parse_transform, :pulse_instrument}
  end
end

defmacro replaceModule(old, with: new) do
  quote do
    @compile {:pulse_replace_module, [{unquote(old), unquote(new)}]}
  end
end

defmacro pulse(do: action, after: clauses) do
  res = Macro.var :res, __MODULE__
  quote do
    :eqc.forall(:pulse.seed(),
      fn seed ->
        unquote(res) = :pulse.run_with_seed(fn -> unquote(action) end, seed)
        unquote({:case, [], [res, [do: clauses]]})
      end)
  end
end

end
