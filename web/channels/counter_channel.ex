defmodule Dash.CounterChannel do
  use Dash.Web, :channel
  require Logger

  alias Dash.Counter
  @counter "first"

  def join("counters:lobby", payload, socket) do
    Logger.info "joing counters:lobby from socket #{inspect socket}"
    if authorized?(payload) do
      {:ok, %{id: @counter, counter: Dash.Counter.get(@counter)}, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (counters:lobby).
  def handle_in("set_value", inc_value, socket) do#
    Logger.info "got message: <set_value, #{inspect inc_value}>"
    value = Counter.inc(@counter, inc_value)
    broadcast socket, "getCounterValue", %{value: value}
    {:noreply, socket}
  end

  # This is invoked every time a notification is being broadcast
  # to the client. The default implementation is just to push it
  # downstream but one could filter or change the event.
  def handle_out(event, payload, socket) do
    Logger.info "handle out: event=#{inspect event}, payload=#{inspect payload}"
    push socket, event, payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
