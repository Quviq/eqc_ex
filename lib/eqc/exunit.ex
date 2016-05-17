defmodule EQC.ExUnit do
  import ExUnit.Case

  defmodule Pretty do
    @moduledoc false

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
      
      ExUnit.plural_rule("property", "properties")
    end
  end

  @moduledoc """
  Properties can be executed using the ExUnit framework using 'mix test'.

  A test module using properties writes 'property' instead or 'test' and uses
  `EQC.ExUnit` module for the macro definitions.

  ## Example

      defmodule SimpleTests do
        use ExUnit.Case
        use EQC.ExUnit

        property "naturals are >= 0" do
          forall n <- nat do
            ensure n >= 0
          end
        end  
      end

 
  ## Tags

  Properties can be tagged similar to ExUnit test cases.

    * `numtests:` `n` - QuickCheck runs `n` test cases, default is `100`
    * `min_time:` `t` - QuickCheck runs for at least `t` milliseconds
    * `timeout:` `t`  - QuickCheck runs for at most `t` milliseconds
    * `erlang_counterexample:` `false` - Specify whether QuickCheck should output 
       the Erlang term that it gets as a counterexample when a property fails. Default `true`


  ## Example 
  In the example below, QuickCheck runs at most 1 second for each test.
  For each property there is a different number of tests generated, but no matter the
  number, the total testing time per property is 1 second.

      defmodule SimpleTests do
        use ExUnit.Case
        use EQC.ExUnit

        @moduletag timeout: 1000

        @tag numtests: 80
        property "naturals are >= 0" do
          forall n <- nat do
            ensure n >= 0
          end
        end

        @tag numtests: 31000
        property "implies fine" do
          forall {n,m} <- {int, nat} do
            implies m > n, do:
            ensure m > n
          end
        end
  
      end


  """

  defp eqc_propname(string), do: :"prop_#{string}"

  @doc false
  defmacro property(description, do: prop) do
    string = Macro.to_string(prop)
    quote do
      def unquote(eqc_propname(description))(), do: unquote(prop)
        ## here we can add property: PropName to the context, numtests is already in there
      @tag type: :property
      test unquote("Property " <> description), context do
        ## IO.puts "seed #{inspect ExUnit.configuration()}"
        :eqc_random.seed(:os.timestamp) ## rather use real :seed
        counterexample = :eqc.counterexample(transform unquote(prop), context)
        assert true == counterexample, unquote(string) <> "\nFailed for " <> Pretty.print(counterexample)
      end
    end
  end

  @doc false
  defmacro property(description) do
    quote do
      unquote(eqc_propname(description))()
    end
  end

  @doc false
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
