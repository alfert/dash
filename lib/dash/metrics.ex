defmodule Dash.Metrics do
	@moduledoc """
	Holds the metrics send from `exometer` and publishes towards the dashboard. 
	"""

	use GenServer
	require Logger
	@name __MODULE__
	## Assign a global name for this server and start it within Dash

	def start_link(name \\ {:global, @name}) do
		GenServer.start_link(__MODULE__, name: name)
	end

	def new_entry(server, metric, datapoint, value) do
		GenServer.cast(server, {:new_entry, metric, datapoint, value})
	end

	def handle_cast({:new_entry, metric, datapoint, value}, state) do
		Logger.error "Send new entry to the channel"
	end
end