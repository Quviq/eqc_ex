defmodule EQC.ExUnit do
  # import ExUnit.Case

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
      ExUnit.Case.register_attribute __ENV__, :check

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

    * `numtests:` `n`  - QuickCheck runs `n` test cases, default is `100`. This tag has priority over `min_time` and `max_time` tags.
    * `min_time:` `t`  - QuickCheck runs for `t` milliseconds unless `numtests` is reached.
     * `max_time:` `t`  - QuickCheck runs for at most `t` milliseconds unless `numtests` is reached.
    * `timeout:` `t` - Inherited from ExUnit and fails if property takes more than `t` milliseconds.
    * `erlang_counterexample:` `false` - Specify whether QuickCheck should output 
       the Erlang term that it gets as a counterexample when a property fails. Default `true`.

  ## Example 
  In the example below, QuickCheck runs the first propery for max 1 second and the second
  property for at least 1 second. This results in 100 tests (the default) or less for the 
  first property and e.g. 22000 tests for the second property.

      defmodule SimpleTests do
        use ExUnit.Case
        use EQC.ExUnit

        @tag max_time: 1000
        property "naturals are >= 0" do
          forall n <- nat do
            ensure n >= 0
          end
        end

        @tag min_time: 1000
        property "implies fine" do
          forall {n,m} <- {int, nat} do
            implies m > n, do:
            ensure m > n
          end
        end
  
      end

  ## Checks

  You may want to test a previously failing case. You can do this by annotating the property
  with `@check`followed by a list of labelled counter examples.

      defmodule SimpleTests do
        use ExUnit.Case
        use EQC.ExUnit

        @check minimum_error: [-1], other_error: [-3]
        property "integers are >= 0" do
          forall n <- int do
            ensure n >= 0
          end
        end  
      end

  """

  @doc """
  Defines a property with a string similar to how tests are defined in
  `ExUnit.Case`.

  ## Examples
      property "naturals are >= 0" do
        forall n <- nat do
          ensure n >= 0
        end
      end
  """
  defmacro property(message, var \\ quote(do: _), contents) do
    prop_ok =
        case contents do
          [do: block] ->
            quote do
              unquote(block)
            end
          _ ->
            quote do
              try(unquote(contents))
            end
        end

    context = Macro.escape(var)
    prop = Macro.escape(prop_ok, unquote: true)

    quote bind_quoted: [prop: prop, message: message, context: context] do
      string = Macro.to_string(prop)
      property = ExUnit.Case.register_test(__ENV__, :property, message, [:check, :property])

      def unquote(property)(context = unquote(context)) do
        failures =
          if context.registered.check do
            Enum.reduce(context.registered.check, "",
              fn({label, ce}, acc) ->
                if :eqc.check(transform(unquote(prop), context), ce) do
                  acc
                else
                  acc <> "#{label}: " <> Pretty.print(ce)
                end
              end)
          else
            ""
          end
        if :check in ExUnit.configuration()[:include] do
           assert "" == failures, unquote(string) <> "\nFailed for\n" <> failures
        else
          :eqc_random.seed(:os.timestamp)
          counterexample = :eqc.counterexample(
            transform(unquote(prop), context))
          assert true == counterexample, unquote(string) <> "\nFailed for " <> Pretty.print(counterexample) <> failures
          assert "" == failures, unquote(string) <> "\nFailed for\n" <> failures
        end
      end

    end
  end

  @doc false
  def transform(prop, opts), do: do_transform(prop, Enum.to_list(opts))

  defp do_transform(prop, []) do
    prop
  end
  defp do_transform(prop, [{:numtests, nr}| opts]) do
    do_transform(:eqc.numtests(nr, prop), opts)
  end
  defp do_transform(prop, [{:min_time, ms} | opts]) do
    do_transform(:eqc.with_testing_time_unit(1, :eqc.testing_time({:min, ms}, prop)), opts)
  end
  defp do_transform(prop, [{:max_time, ms} | opts]) do
    do_transform(:eqc.with_testing_time_unit(1, :eqc.testing_time({:max, ms}, prop)), opts)
  end
  defp do_transform(prop, [{:erlang_counterexample, b} | opts]) do
    if !b do
      do_transform(:eqc.dont_print_counterexample(prop), opts)
    else
      do_transform(prop, opts)
    end
  end
  defp do_transform(prop, [{:show_states, b} | opts]) do
    if b do
      do_transform(:eqc_statem.show_states(prop), opts)
    else
      do_transform(prop, opts)
    end
  end
  defp do_transform(prop, [_ | opts]) do
    do_transform(prop, opts)
  end



end
