defmodule SimpleTests do
  use ExUnit.Case
  use EQC.ExUnit

  #@moduletag numtests: 80


  @tag erlang_counterexample: false
  @tag zero: 0
  property "naturals are >= 0", context do
    forall n <- nat do
      ensure n > context.zero
    end
  end

  @tag numtests: 31
  property "implies fine" do
      forall {n,m} <- {int, nat} do
        implies m > n, do:
        ensure m > n
    end
  end

  @tag min_time: 2000 
  property "min testing_time" do
    forall _min <- int do
      true
    end
  end
  
  @tag timeout: 5000
  @tag min_time: 4000 
  property "min testing_time too long" do
    forall _min_long <- int do
      true
    end
  end

  def string, do: utf8
  
  property "reverse strings", context do
    forall s <- string do
      ensure String.reverse(String.reverse(s)) == s
    end
  end
  
end
