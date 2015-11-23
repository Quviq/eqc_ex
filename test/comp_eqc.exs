defmodule Comp_eqc do
  use ExUnit.Case
  use EQC.ExUnit
  use EQC.Component
  require EQC.Mocking

  def initial_state, do: 0

  def add_args(_state), do: [int]

  def add_pre(_state, [i]), do: i > 0

  def add(i), do: :mock.add(i)

  def add_callouts(_state, [i]) do
    callout(:mock, :add, [i], :ok)
  end

  def add_next(state, _, [i]) do
    state+i
  end

  def add_post(state, [_], _) do
    state >= 0
  end
  
  property "Mock Add" do
    EQC.setup_teardown setup do
      forall cmds <- commands(__MODULE__) do
        res = run_commands(__MODULE__, cmds)
        pretty_commands(__MODULE__, cmds, res,
                        :eqc.aggregate(command_names(cmds),
                                       res[:result] == :ok))
      end
    after _ -> teardown
    end
  end

  def setup() do
    :eqc_mocking.start_mocking(api_spec)
  end

  def teardown() do
    :ok
  end

  def api_spec do
    EQC.Mocking.api_spec [
      modules: [
        EQC.Mocking.api_module(name: :mock,
                               functions:
                               [ EQC.Mocking.api_fun(name: :add, arity: 1) ])
      ]
    ]
  end


end
