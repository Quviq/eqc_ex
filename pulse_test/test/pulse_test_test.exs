defmodule PulseTestTest do
  use ExUnit.Case

  test "is ok" do
    assert :eqc.quickcheck(Simple.prop_ok)
  end
end
