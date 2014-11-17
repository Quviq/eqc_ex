
import PulseInstrument
import Pulse

defmodule Simple do

@compile {:parse_transform, :pulse_instrument}
@compile {:pulse_skip, [{:hello_test, 0}]}

def hello_server(root) do
  spawn fn -> server_loop(root) end
end

def server_loop(root) do
  receive do
    {:msg, msg} ->
      send root, {:reply, msg}
      server_loop root
    :stop -> :ok
  end
end

def hello_test do
  server = hello_server self
  send server, {:msg, :hello}
  Kernel.spawn fn -> send server, {:msg, :world} end
  xs = for _ <- [:hello, :world] do
        receive do
          {:reply, x} -> x
        end
       end
  send server, :stop
  xs
end

def prop_pulse do
  pulse do
    hello_test()
  after res ->
    :eqc.equals(res, [:hello, :world])
  end
end

def pulse_test do
  :pulse.start
  :pulse.verbose [:all]
  :eqc.quickcheck prop_pulse
end

def bla do
  task = Task.async(fn -> 42 end)
  x = 1 + Task.await(task)
  pid = Process.spawn(fn -> 40 end, [:link])
  link pid
  pid
end

# defmacro forall(x, g, do: prop) do
#   quote do
#     :eqc.forall(unquote(g), fn unquote(x) -> unquote(prop) end)
#   end
# end
# defmacro forall(x, opts) do
#   :io.format("x    = ~p\n", [x])
#   :io.format("opts = ~p\n", [opts])
# end

# defmacro let(x, in: g, do: body) do
#   quote do
#     :eqc_gen.bind(unquote(g), fn unquote(x) -> unquote(body) end)
#   end
# end

# defmacro suchthat(x, g, pred) do
#   loc = {__CALLER__.file, __CALLER__.line}
#   quote do
#     :eqc_gen.suchthat(unquote(g), fn unquote(x) -> unquote(pred) end, unquote(loc))
#   end
# end

# def prop_nat do
#   forall {n, m}, {suchthat(n, :eqc_gen.nat(), n <= 150),
#                   suchthat(n, :eqc_gen.nat(), n <= 15)} do
#     n + m < 30
#   end
# end

end
