defmodule Example do

#  def reverse([]) do
#		[]
#  end

#	def reverse([head|tail]) do
#		reverse(tail) ++ [head]
# end

	def reverse(xs) when length(xs) < 2 do xs end
  def reverse(xs) do
				{left, right} = Enum.split(xs, div(length(xs), 2))
				reverse(left) ++ reverse(right)
	end
#	end
end
