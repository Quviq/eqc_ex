
require Pulse

defmodule HelloServer do

Pulse.instrument
Pulse.replaceModule GenServer, with: Pulse.GenServer

def start_link do
  GenServer.start_link(__MODULE__, %{root: :undefined}, name: __MODULE__)
end

# -- Callbacks --------------------------------------------------------------

def init(s), do: {:ok, s}

def handle_call({:set_root, root}, _from, s) do
  {:reply, :ok, %{s | root: root}}
end
def handle_call(:stop, _, s), do: {:stop, :normal, :ok, s}

def handle_cast({:msg, m}, s) do
  send s.root, {:reply, m}
  {:noreply, s}
end

def handle_info(_, s),    do: {:noreply, s}
def terminate(_, _),      do: :ok
def code_change(_, s, _), do: {:ok, s}

end
