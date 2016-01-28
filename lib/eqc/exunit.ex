
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
    defp command_sequence({[{:set, {:var, _}, {:call, _, _, _}}|_], _}), do: true
    defp command_sequence({[], [[{:set, {:var, _}, {:call, _, _, _}}|_]| _]}), do: true
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
        counterexample = :eqc.counterexample(transform unquote(prop), context)
        assert true == counterexample, unquote(string) <> "\nFailed for " <> Pretty.print(counterexample)
      end
    end
  end

  defmacro property(description) do
    quote do
      unquote(eqc_propname(description))()
    end
  end

  def transform(prop, opts), do: do_transform(prop, Enum.uniq(opts))

  defp do_transform(prop, []) do
    prop
  end
  defp do_transform(prop, [{:numtests, nr}| opts]) do
    do_transform(:eqc.numtests(nr, prop), opts)
  end
  defp do_transform(prop, [{:min_time, ms} | opts]) do
    do_transform(:eqc.testing_time({:min, div(ms, 1000)}, prop), opts)
  end
  defp do_transform(prop, [{:timeout, ms} | opts]) do
    do_transform(:eqc.testing_time({:max,div(ms, 1000)}, prop), opts)
  end
  defp do_transform(prop, [{:erlang_counterexample, b} | opts]) do
    do_transform(:eqc_gen.with_parameter(:print_counterexample, b, prop), opts)
  end
  defp do_transform(prop, [_ | opts]) do
    do_transform(prop, opts)
  end



end
