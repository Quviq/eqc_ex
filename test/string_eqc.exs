defmodule StringTests do
  use ExUnit.Case
  use EQC.ExUnit
  
  def string, do: utf8()

  @tag numtests: 0
  property "reverse strings" do
    forall s <- string() do
      ensure String.reverse(String.reverse(s)) == s
    end
  end

  @tag numtests: 1000
  property "replace all leading occurrence of strings" do
    forall {ls, n, s, rs}  <- {string(), nat(), string(), string()} do
      implies not String.starts_with?(s, ls) do
        string = String.duplicate(ls, n) <> s 
        replaced = String.duplicate(rs, n) <> s
        collect ls: (ls == ""), string: (s == ""), in:
          ensure String.replace_leading(string, ls, rs) == replaced
        end
      end
  end


  @tag numtests: 100000
  property "replace all multiple occurrences of string" do
    forall {ls, n, rs}  <- {string(), nat(), string()} do
      implies ls != "" do
        string = String.duplicate(ls, n) 
        replaced = String.duplicate(rs, n)
        ensure String.replace_leading(string, ls, rs) == replaced
      end
    end
  end

  @tag numtests: 100000
  property "replace one prefix occurrences of string" do
    forall {ls, rs, s}  <- {string(), string(), string()} do
        string = ls <> s
        replaced = rs <> s
        ensure String.replace_prefix(string, ls, rs) == replaced
    end
  end
  

end
