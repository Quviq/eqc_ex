
defmodule EQC.ExUnit do
  import ExUnit.Case

  defmodule Pretty do

    def print(true), do: ""
    def print([]), do: "\n"
    def print([term|tail]), do: pp(term) <> "\n   " <> print(tail)
      
    def pp(term) do
      case command_sequence(term) do
        true  ->
          "commands"
        false ->
          Macro.to_string(term)
      end
    end

    defp command_sequence([{:set, {:var, _}, {:call, _, _, _}}|_]), do: true
    defp command_sequence(_), do: false
  end
  
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
      test unquote("Property " <> description), context do
        counterexample =
          if num = context[:num_tests] do
            :eqc.counterexample(:eqc.numtests(num, unquote(prop)))
          else
            :eqc.counterexample(unquote(prop))
          end
        assert true == counterexample, unquote(string) <> "\nFailed for " <> Pretty.print(counterexample)
      end
    end
  end

  defmacro property(description) do
    quote do
      unquote(eqc_propname(description))()
    end
  end

end
