# note to self
# build and compile in deps/eqc_ex
# cp deps/eqc_ex/_build/dev/lib/eqc_ex/ebin/* _build/test/lib/eqc_ex/ebin/
# Each beam occurs many times, as it occurs.

defmodule ExampleTest do
	use ExUnit.Case
  use EQC.ExUnit

#	property "less than five" do
#		forall x <- nat do
#			x < 5
#		end
#	end
	
#	test "few elements" do
#		assert Enum.to_list(1 .. 5) == [1,2,3,4,5]
#	end
#
#	test "one element" do
#		assert Enum.to_list(3 .. 3) == [3]
#	end
#
#	test "no element" do
#		assert Enum.to_list(3 .. 1) == [3,2,1]
#	end
#
#	test "start negative" do
#		assert Enum.to_list(-3 .. 12) == [-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,11,12]
#	end
#
#	test "end negative" do
#		assert Enum.to_list(-4 .. -2) == [-4,-3,-2]
#	end
	
	property "sequence length" do
		forall {m, n} <- {int, int} do
			:eqc.collect {order(m,n), posneg(m), posneg(n)},
									 length(Enum.to_list(m .. n)) == abs(n - m) +1
		end
	end

	property "sequence length 2" do
		forall {m, n} <- {int, int} do
			collect order: order(m,n), m: posneg(m), n: posneg(n),
			in:
			    length(Enum.to_list(m .. n)) == abs(n - m) + 1 
		end
	end


		property "sequence length 4" do
		:eqc.numtests(5,
		forall {m, n} <- {int, int} do
			  length(Enum.to_list(m .. n)) == abs(n - m) + 1
		end)
	end

	property "sequence length 3" do
		:eqc.numtests(5,
		forall {m, n} <- {int, int} do
			collect order: order(m,n) in ['<','>','=='], m: posneg(m), n: posneg(n),
			in:
			    length(Enum.to_list(m .. n)) == abs(n - m) + 1 
		end)
	end

#	test "special case 3..4" do
#		assert :eqc.check(property("sequence length"), [{3,4}])
#	end

#	check "5..12 case", [{5,12}] do
#		property "sequence length"
#	end
	
#	check "sequence length", "5..12 case" do
#		[{5,12}]
#	end
	
	def posneg(x) do
		cond do
			x>0 -> 'pos'
			x<0 -> 'neg'
			true -> 0
		end
 end
	
	def order(m,n) do 
		cond do
			m < n -> '<'
		  m > n -> '>'
			m == n -> '=='
		end
	end

#	property "foutje" do
#		forall x <- nat do
#			x < 6
#		end
#	end

#	property "unique sort" do
#		forall l <- list(nat) do
#			Enum.sort(Enum.uniq(l)) == Enum.uniq(Enum.sort(l))
#		end
#	end

#	property "take every" do
#		forall {m,n,i} <- {int,int,int} do
#			length(Enum.take_every(m .. n, i)) == n-m
#		end
#	end
																											
	test "reverse decomposed" do
    assert true = :eqc.quickcheck(prop_reverse())
  end

#	def prop_reverse do
#		forall xs <- list(nat) do
#			Example.reverse(Example.reverse(xs)) == xs
#		end
#	end

	def prop_reverse() do
		forall xs <- list(nat) do
			:eqc.equals(Example.reverse(Example.reverse(xs)),xs)
		end
	end

#	property "reverse2 decomposed" do
#		forall {xs, ys} <- {list(nat), list(nat)} do
#			:eqc.equals(Example.reverse2(ys) ++ Example.reverse2(xs), Example.reverse2(xs++ys))
#		end
#	end
	
#	property "reverse2" do
#		forall xs <- list(nat) do
#			Example.reverse2(Example.reverse2(xs)) == xs
#		end
#	end
#
#	property "reverse2 same as reverse" do
#		forall xs <- list(nat) do
#			:eqc.equals(Example.reverse2(xs), Example.reverse(xs))
#		end
#	end

end
