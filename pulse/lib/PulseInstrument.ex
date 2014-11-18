
defmodule PulseInstrument do

## TODO
##  - Instrumented/mocked version of global (Erlang lib)
##  - Test GenServer


## PULSE instrumented module. Instruments if project config has :pulse == true.
defmacro pulse_defmodule(name, do: block) do
  cond do
    Mix.Project.config[:pulse] ->
      IO.puts ("Instrumenting file " <> __CALLER__.file)
      :erlang.put :instrumented_file, String.to_char_list(__CALLER__.file)
      mod = quote do
          defmodule unquote(name) do
            def is_pulse_instrumented, do: true
            unquote (instrument [context: :top], block)
          end
        end
      IO.puts Macro.to_string(mod)
      mod
    true ->
      quote do
        defmodule unquote(name), do: unquote block
      end
  end
end

defp srcLoc({_, meta, _}), do: srcLoc meta
defp srcLoc(meta),         do: {:erlang.get(:instrumented_file), meta[:line]}

defp call(mod, fun, args), do: {{:., [], [mod, fun]}, [], args}

## Set the pid name hint from a pattern or definition head.
defp set_hint({:=, _, [pat, _]}, env), do: set_hint(pat, env)
defp set_hint({var, _, _}, env) when is_atom var do
  Keyword.put env, :hint, var
end
defp set_hint(_, env), do: env

defp is_spawn_fun(:spawn),                                       do: :spawn
defp is_spawn_fun(:spawn_link),                                  do: :spawn_link
defp is_spawn_fun(:spawn_monitor),                               do: :spawn_monitor
defp is_spawn_fun({:., _, [{:__aliases__, _, [:Kernel]}, fun]}), do: is_spawn_fun(fun)
defp is_spawn_fun({:., _, [:erlang, fun]}),                      do: is_spawn_fun(fun)
defp is_spawn_fun(_),                                            do: nil

defp add_consumed({:->, meta, [[pat], body]}) do
  loc = srcLoc(meta)
  hd(case pat do
    {:when, meta1, [pat, guard]} ->
      quote do
        (x = unquote(pat)) when unquote(guard) ->
          :pulse.consumed x, unquote(loc)
          unquote(body)
      end
    _ ->
      quote do
        (x = unquote(pat)) ->
          :pulse.consumed x, unquote(loc)
          unquote(body)
      end
  end)
end

## send
defp instrument(env, {:send, meta, [pid, msg]}) do
  quote do
    :pulse.send unquote(pid), unquote(msg), unquote(srcLoc meta)
  end
end

## receive
defp instrument(env, {:receive, meta, [clauses]}) do
  loc      = srcLoc meta
  iclauses = instrument env, clauses
  recvClauses =
    case iclauses[:do] do
      nil -> []
      cs  -> [do: (for c <- cs, do: add_consumed(c))]
    end
  recvFun  =
    quote do
      fn retry ->
        unquote({:receive, meta, [recvClauses ++
                                  [after: quote(do: (0 -> retry.()))]]})
      end
    end
  fallback  = quote do: (fn -> unquote {:receive, meta, [iclauses]} end)
  afterArgs =
    case clauses[:after] do
      nil -> []
      [{:->, _meta, [[afterX], afterBody]}] ->
        [quote(do: (fn -> unquote afterBody end)), afterX]
    end
  call(:pulse, :receiving, [recvFun] ++ afterArgs ++ [fallback, loc])
end

## def
defp instrument(env, {df, meta, [name, body]})
    when df in [:def, :defp, :defmodule, :defmacro] do
  {df, meta, [name, instrument(set_hint(name, env), body)]}
end

## match (for name hints)
defp instrument(env, {:=, meta, [pat, expr]}) do
  new_env = set_hint(pat, env)
  {:=, meta, [pat, instrument(new_env, expr)]}
end

## call
defp instrument(env, {fun, meta, args}) do
  case is_spawn_fun(fun) do
    nil  -> {instrument(env, fun), meta, instrument(env, args)}
    spwn -> instrument_spawn(env, spwn, meta, args)
  end
end

## Generic cases
defp instrument(env, xs) when is_list(xs), do: (for x <- xs, do: instrument(env, x))
defp instrument(env, {a, b}),              do: {instrument(env, a), instrument(env, b)}
defp instrument(env, {fun, meta, args}),   do: {instrument(env, fun), meta, instrument(env, args)}
defp instrument(env, code),                do: code

## Spawn instrumentation
defp instrument_spawn(env, fun, meta, args) do
  options =
    case fun do
      :spawn         -> []
      :spawn_link    -> [:link]
      :spawn_monitor -> [:monitor]
    end
  hint =
    case env[:hint] do
      nil -> :Pid
      h   -> h
    end
  {m, f, a} =
    case args do
      [f]       -> {:erlang, :apply, [instrument(env, f), []]}
      [m, f, a] -> {m, f, a}
    end
  {{:., [], [:pulse, :spawn_opt]}, meta, [hint, m, f, a, options, srcLoc(meta)]}
end

end
