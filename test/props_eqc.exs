defmodule SimpleTests do
  use ExUnit.Case
  use EQC.ExUnit

  property "naturals are >= 0" do
    :eqc.fails(
    forall n <- nat do
      ensure n > 0
    end)
  end

  property "implies fine" do
      forall {n,m} <- {int, nat} do
        implies m > n, do:
        ensure m > n
    end
  end

end
