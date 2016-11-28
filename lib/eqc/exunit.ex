defmodule EQC.ExUnit do
  # import ExUnit.Case

  defmodule Pretty do
    @moduledoc false

    def print(true), do: ""
    def print([]), do: "\n"
    def print([term|tail]), do: pp(term) <> "\n   " <> print(tail)

    def pp(term) do
      if :eqc.version() == 2.01 do
        ## QuickCheck Mini has less advanced printing
        Macro.to_string(term)
      else
        IO.iodata_to_binary(:prettypr.format(:eqc_symbolic.pretty_elixir_symbolic_doc(term), 80))
      end
    end
    
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
    * `:morebugs` - Runs more_bugs
    * `:showstates` - For QuickCheck state machines, show intermediate states for failing tests 


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

      ## `mix eqc` options overwrite module tags
      env_flags =
        Enum.reduce([:numtests, :morebugs, :showstates],
                    [],
          fn(key, acc) ->
            value = Application.get_env(:eqc, key) 
            if value == nil do
              acc
            else
              [[{key, value}]|acc]
            end
          end)
      
      property = ExUnit.Case.register_test(__ENV__, :property, message,
                                           [:check, :property] ++ env_flags)

      def unquote(property)(context = unquote(context)) do

        transformed_prop = transform(unquote(prop), context)
                
        case {Map.get(context, :morebugs), Map.get(context, :eqc_callback)} do
          {true, callback} when callback != nil ->
            suite = :eqc_statem.more_bugs(transformed_prop)
            ## possibly save suite at ENV determined location
            case suite do
              {:feature_based, []} -> true
              {:feature_based, fset} ->
                tests =
                  for {_,ce} <- fset do
                  Pretty.print(ce)
                end
                assert false, Enum.join(tests, "\n\n")
              _ ->
                assert false, "No feature based suite returned" 
            end
          _ ->
            failures =
            if context.registered.check do
              Enum.reduce(context.registered.check, "",
                fn({label, ce}, acc) ->
                  if :eqc.check(transformed_prop, ce) do
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
              
              counterexample = :eqc.counterexample(transformed_prop)
              assert true == counterexample, unquote(string) <> "\nFailed for " <> Pretty.print(counterexample) <> failures
              assert "" == failures, unquote(string) <> "\nFailed for\n" <> failures
            end
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
  defp do_transform(prop, [{:showstates, b} | opts]) do
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
