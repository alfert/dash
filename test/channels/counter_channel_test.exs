defmodule Dash.CounterChannelTest do
  use Dash.ChannelCase, async: true

  alias Dash.CounterChannel

  setup do
    {:ok, _, socket} =
      socket("user_id", %{some: :assign})
      |> subscribe_and_join(CounterChannel, "counters:lobby")

    {:ok, socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push socket, "ping", %{"hello" => "there"}
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "shout broadcasts to counters:lobby", %{socket: socket} do
    push socket, "set_value", 5
    assert_broadcast "getCounterValue", %{counter: %Dash.Counter{value: 5}}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from! socket, "broadcast", %{"some" => "data"}
    assert_push "broadcast", %{"some" => "data"}
  end
end
