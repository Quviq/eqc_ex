
defmodule EQC.ExUnit do
  import ExUnit.Case

  defmacro __using__(_opts) do
    quote do
      import EQC.ExUnit
      use EQC
    end
  end


  defp eqc_propname(string) do
    String.to_atom("prop_" <> string)
  end

  defmacro property(description, do: prop) do
    string = Macro.to_string(prop)
    quote do
      def unquote(eqc_propname(description))(), do: unquote(prop)
      test unquote("Property " <> description) do
        counterexample = :eqc.counterexample(unquote(prop))
        assert true == counterexample, :counterexample, counterexample, unquote(string)
      end
    end
  end

  defmacro property(description) do
    quote do
      unquote(eqc_propname(description))()
    end
  end

end
