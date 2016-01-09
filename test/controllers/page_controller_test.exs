defmodule Dash.PageControllerTest do
  use Dash.ConnCase, async: true

  test "GET /" do
    conn = get conn(), "/"
    assert html_response(conn, 200) =~ "<div id=\"elm-main\"></div>"
  end
end
