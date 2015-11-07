defmodule Dash.Counter do
	@moduledoc """
	Implements a simple counter as an example for state
	"""

	@doc """
	Start the counter server, creates the counter `first` and starts 
	updates every seconds
	"""
	def start_link() do
		{_v, dict} = HashDict.new |> update_by_inc("first", 0)
		res = Agent.start_link(fn -> dict end, 
			name: __MODULE__)
		:timer.apply_interval(1_000, __MODULE__, :timed_update, [])
		res
	end

	def get(counter) do
		{:ok, value} = Agent.get(__MODULE__, fn map -> map |> Dict.fetch(counter) end)
		value 
	end

	@doc "Reset or creates a new counter"
	def reset(counter) do
		Agent.update(__MODULE__, fn map -> map |> Dict.put(counter, 0) end)
		0
	end

	@doc """
	Increments a `counter` by the given `value`, per default with `1`.
	If the counter does not exist, it is created with `value`
	"""
	def inc(counter, value \\ 1) do
		Agent.get_and_update(__MODULE__, 
			fn map -> update_by_inc(map, counter, value) end)
	end

	@doc "Starts a regular timer to update one counter by some arbitrary value"
	def timed_update() do
		updater = fn() -> 
			Agent.get_and_update(__MODULE__, 
				fn map ->
					counter = map |> Dict.keys |> arb
					{v, new_map} = map |> update_by_inc(counter, :rand.uniform(10) - 5)
					{{counter, v}, new_map}
				end)
		end
	end

	@doc "Used internally to update a counter"
	@spec update_by_inc(Dict.t, term, integer) :: {integer, Dict.t}
	def update_by_inc(map, counter, value) do
		v = Dict.get(map, counter, 0)
		new_map = map |> Dict.update(counter, value, fn v -> v + value end)
		{v + value, new_map}
	end

	def arb(enum) do
		n = enum |> Enum.count
		enum |> Enum.nth(:rand.uniform(n))
	end

end