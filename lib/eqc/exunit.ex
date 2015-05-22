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

  ## remove, too specific
  defmacro check(description, value, do: prop) do
    string = Macro.to_string(prop)
    quote do
      test unquote(description) do
        counterexample = :eqc.check(unquote(prop),unquote(value))
        assert counterexample, unquote(string)
      end
    end
  end

  ## put somehwere else?
  defmacro test_suite(description, do: prop) do
    quote do
      test  unquote("Test Suite " <> description) do
        {:feature_based, testsuite} = :eqc_suite.feature_based(unquote(prop))
        testcases = Enum.map testsuite,
          fn ({[feature],vals}) ->
            "test " <> Macro.to_string(feature) <> " do check " <> Macro.to_string(vals) <>" end"
          end
        assert false, Enum.join(testcases, "\n")
      end
    end
  end
end
