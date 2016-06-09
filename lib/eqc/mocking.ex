defmodule EQC.Mocking do
  @copyright "Quviq AB, 2014-2016"

  @moduledoc """
  This module contains macros to be used with [Quviq
  QuickCheck](http://www.quviq.com). It defines Elixir versions of the Erlang
  macros found in `eqc/include/eqc_mocking.hrl`. For detailed documentation of the
  macros, please refer to the QuickCheck documentation.

  `Copyright (C) Quviq AB, 2014-2016.`

  ## Example

  Typical use in Component module definitions

      require EQC.Mocking
 
        def api_spec do
          EQC.Mocking.api_spec [
            modules: [
              EQC.Mocking.api_module name: :mock
            ]
          ]
        end

  ## QuickCheck dependency

  Note that mocking only works with the full version of QuickCheck, not with 
  QuickCheck Mini. In order to use this module, one has to compile it with QuickCheck installed. 
  This compilation will then generate the Elixir Records corresponding to 
  the records defined in the Erlang header files of QuickCheck.  

  """
  require Record

  try do
    Record.defrecord :api_spec,   Record.extract(:api_spec, from_lib: "eqc/include/eqc_mocking_api.hrl")
    Record.defrecord :api_module, Record.extract(:api_module, from_lib: "eqc/include/eqc_mocking_api.hrl")
    Record.defrecord :api_fun,    Record.extract(:api_fun, from_lib: "eqc/include/eqc_mocking_api.hrl")
  rescue _ ->
      "Full Version of QuickCheck Needed"
  end
  
end
