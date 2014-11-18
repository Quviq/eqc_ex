
import Task
import EQC
require Pulse
import :eqc_gen

defmodule Simple do

Pulse.instrument
Pulse.replaceModule Task,      with: Pulse.Task
Pulse.replaceModule GenServer, with: Pulse.GenServer

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

def recv(n) do
  for _ <- :lists.seq(1, n) do
    receive do
      {:reply, x} -> x
    end end
end

def hello_test do
  server = hello_server self
  send server, {:msg, :hello}
  # Kernel.spawn fn -> send server, {:msg, :world} end
  task = async fn -> send server, {:msg, :world} end
  await task
  xs = recv 2
  send server, :stop
  xs
end

def gen_hello_server(root) do
  HelloServer.start_link
  GenServer.call(HelloServer, {:set_root, root})
end

def gen_hello do
  gen_hello_server self
  GenServer.cast HelloServer, {:msg, :hello}
  spawn fn -> GenServer.cast HelloServer, {:msg, :world} end
  xs = recv 2
  GenServer.call HelloServer, :stop
  xs
end

def prop_pulse do
  Pulse.pulse do
    # hello_test
    gen_hello
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
  _x = 1 + Task.await(task)
  pid = Process.spawn(fn -> 40 end, [:link])
  link pid
  pid
end

def orderedList do
  let xs <- list(nat) do
    :lists.sort xs
  end
end

def prop_list do
  forAll xs <- orderedList do
    :lists.sum(xs) < 100
  end
end

def prop_ok do
  forAll n <- nat, do: n != 58434
end

def prop_nat do
  forAll {n, m} <- {nat, suchThat(n <- nat, do: n <= 15)} do
  implies n > 20 do
    whenFail IO.puts("n = #{n}, m = #{m}"), do: n + m < 30
  end end
end

end
