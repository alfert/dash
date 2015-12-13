defmodule Dash.Counter do
	@moduledoc """
	Implements a simple counter as an example for state
	"""

	require Logger

	@type millis :: non_neg_integer
	defstruct date: 0, value: 0 
	@typedoc "The struct of a counter"
	@type t :: %__MODULE__{date: millis, value: integer}

	@doc """
	Start the counter server, creates the counter `first` and starts 
	updates every seconds
	"""
	def start_link() do
		dict = HashDict.new |> Dict.put("first", set_value(0))
		res = Agent.start_link(fn -> dict end, 
			name: __MODULE__)
		timer = :timer.apply_interval(1_000, __MODULE__, :timed_update, [])
		Logger.info "Counter first startet: #{inspect res}"
		Logger.info "Timer for apply_interval is: #{inspect timer}"
		res
	end

	def get(counter) do
		{:ok, value} = Agent.get(__MODULE__, fn map -> map |> Dict.fetch(counter) end)
		value 
	end

	@doc "Reset or creates a new counter"
	def reset(counter) do
		Agent.update(__MODULE__, fn map -> 
			map |> Dict.put(counter, set_value(0) |> publish_counter) end)
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
		Logger.info "Timed update is called!" 
		Agent.get_and_update(__MODULE__, 
			fn map ->
				counter = map |> Dict.keys |> arb
				{v, new_map} = map |> update_by_inc(counter, :rand.uniform(10) - 5)
				{{counter, v}, new_map}
			end)
	end

	@doc "Used internally to update a counter and publishes the new value"
	@spec update_by_inc(Dict.t, term, integer) :: {t, Dict.t}
	def update_by_inc(map, counter, value) do
		Logger.info "increment counter #{counter} with #{value}"
		v = Dict.get(map, counter, set_value(0))
		Logger.info "old value is: #{inspect v}"
		new_map = map |> Dict.update(counter, value, 
			fn %__MODULE__{value: v} -> 
				set_value(v + value) |> publish_counter 
			 	any -> Logger.error "old value for #{inspect counter} is #{inspect any}"
			 		any
			end)
		{new_map |> Dict.fetch!(counter), new_map}
	end

	@doc "Sets the value and the current time"
	@spec set_value(integer) :: t
	def set_value(v) do
		now = Timex.Time.now(:msecs)
		%__MODULE__{value: v, date: now}
	end

	@doc "Publishes a counter to the Phoenix Channel `counter:first`"
	@spec publish_counter(t) :: t
	def publish_counter(%__MODULE__{} = counter) do
		:ok = Dash.Endpoint.broadcast! "counters:lobby", "getCounterValue", counter
		Logger.info "publishes counter: #{inspect counter}"
		counter
	end

	def arb(enum) do
		[r] = enum |> Enum.take_random(1)
		r
	end

end