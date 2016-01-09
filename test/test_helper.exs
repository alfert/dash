ExUnit.start

IO.puts """
I don't call: 
Mix.Task.run "ecto.create", ["--quiet"]"
Mix.Task.run "ecto.migrate", ["--quiet"]
Ecto.Adapters.SQL.begin_test_transaction(Dash.Repo)
"""

