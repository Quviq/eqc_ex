import ExUnit.Case

defmodule EQC.ExUnit do
		
	defmacro __using__(_opts) do
    quote do
			import EQC.ExUnit
			import EQC
			import :eqc_gen
    end
  end

	defmacro collect(xs) do
		case Enum.reverse(xs) do
			[ {:in, prop} | tail] ->
				do_collect(tail, prop)
			_ ->
				throw("Wrong property format")
		end
	end

	defp do_collect([{tag, {:in, _, [count,requirement]}} | t], acc) do
		acc = quote do: :eqc.collect(
					fn res ->
						case (unquote(requirement) -- Keyword.keys(res)) do
							[] -> :ok
							uncovered ->
								:eqc.format("Warning: not all features covered! ~p\n",[uncovered])
						end
						:eqc.with_title(unquote(tag)).(res)		
					end, unquote(count), unquote(acc))
		do_collect(t, acc)
	end
	defp do_collect([{tag, term} | t], acc) do
		acc = quote do: :eqc.collect(:eqc.with_title(unquote(tag)), unquote(term), unquote(acc))
		do_collect(t, acc)
	end
	defp do_collect([], acc) do acc
	end

  def feature(term, prop) do
		:eqc.collect( term, :eqc.features([term], prop))
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

	defmacro check(description, value, do: prop) do
		string = Macro.to_string(prop)
		quote do
			test unquote(description) do
				counterexample = :eqc.check(unquote(prop),unquote(value))
				assert counterexample, unquote(string)
			end
		end
	end
	
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
