use Mix.Config

# use exometer for hackney's metrics monitoring
# config :hackney, mod_metrics: :exometer


app_name         = :dash
polling_interval = 1_000
reporter		     = Dash.Reporter # :exometer_report_tty
histogram_stats  = ~w(min max 999 99 97 95 90)a
histo_opts       = [truncate: false, keep_high: 1_000]
memory_stats     = ~w(atom binary ets processes total)a
pool_stats       = ~w(take_rate no_socket in_use_count free_count queue_counter)a

config :exometer,
  predefined:
    [
      {
        ~w(erlang memory)a,
        {:function, :erlang, :memory, [], :proplist, memory_stats},
        []
      },
      {
        # Run queue statistics 
        ~w(erlang statistics)a,
        {:function, :erlang, :statistics, [:'$dp'], :value, [:run_queue]},
        []
      },
    ],

  reporters:
    [
      {Dash.Reporter, [target: {:global, Dash.Metrics}]},
      exometer_report_statsd:
      [
        hostname: '192.168.99.100', # 'localhost',
        port: 8125
      ],
      exometer_report_tty: []
    ],

  report: [
    subscribers:
      [
        {reporter,
          [:erlang, :memory], memory_stats, polling_interval, true
        },
        {reporter,
          [:erlang, :statistics], :run_queue, polling_interval, true
        }
      ]
  ]