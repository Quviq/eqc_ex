defmodule SimpleTests do
  use ExUnit.Case
  use EQC.ExUnit

  #@moduletag numtests: 80
  
  property "naturals are >= 0" do
    :eqc.fails(
    forall n <- nat do
      ensure n > 0
    end)
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
  
end
