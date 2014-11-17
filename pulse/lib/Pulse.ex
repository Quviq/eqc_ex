
defmodule Pulse do

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
