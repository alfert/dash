defmodule Dash.Reporter do
	@moduledoc """
	An Exometer custom reporter, sending the new data to an elixir process.  
	"""

	@behaviour :exometer_report

	defstruct type_map: [], 
		target: :unknown 

	require Logger

	@doc """
	Initializes the reporter. Currently no options are required.
	"""
	def exometer_init(opts) do
		type_map = opts |> Keyword.get(:type_map, [])
		target = opts |> Keyword.get(:target, :unknown)
		{:ok, %__MODULE__{type_map: type_map, target: target}}
	end

	def exometer_report(metric, datapoint, extra, value, state) do
		Logger.info "report metric #{inspect metric}_#{inspect datapoint} = #{inspect value}"
		key = metric ++ [datapoint]
		type = case :exometer_util.report_type(key, extra, state.type_map) do
			{:ok, t} -> t
			:error -> :unknown
		end
		Dash.Metrics.new_entry(state.target, metric, datapoint, value)
	end


	@doc "We don't care about subscriptions"
	def exometer_subscribe(_metric, _dataPoint, _extra, _interval, state) do
		{:ok, state}
	end

	@doc "We don't care about unsubscriptions"
	def exometer_unsubscribe(_metric, _dataPoint, _extra, state) do
		{:ok, state}
	end

	@doc "Callback for `GenServer.call`. Not needed here"
	def exometer_call(unknown, from, state) do
    	Logger.info "Unknown call #{inspect unknown} from #{from}"
    	{:ok, state}
	end	

	@doc "Callback for `GenServer.cast`. Not needed here"
	def exometer_cast(unknown, state) do
    	Logger.info "Unknown cast #{inspect unknown}"
    	{:ok, state}
	end	

	@doc "Callback for `GenServer.handle_info`. Not needed here"
	def exometer_info(unknown, state) do
    	Logger.info "Unknown info #{inspect unknown}"
    	{:ok, state}
	end	

	@doc "Callback for `new_entry`. Not needed here"
	def exometer_newentry(_entry, state), do: {:ok, state}

	@doc "Callback for `set_tops`. Not needed here"
	def exometer_setopts(_Metric, _Options, _Status, state), do: {:ok, state}

	@doc "Callback for `GenServer.terminate`. Not needed here"
	def exometer_terminate(_, _), do: :ignore



end