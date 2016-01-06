module Dash where

import StartApp exposing (App)
import Effects exposing (Effects, Never)
import Task exposing (Task)
import Html exposing (..)
import Time exposing (Time)
import Json.Encode as JS -- exposing (Value)

import Dict exposing (Dict)


import Dash.Diagram exposing (..)
import Dash.Board exposing (..)


{-- 
  What to do here properly: 
    * design a module for a time series chart, addressable, such 
      that incoming data can be sent to. ==> Data comes in from phoenix via sockets
      ==> DONE
    * design a larger frame, where charts can be embedded. The model is a dictionary,
      mapping ids (or targets) to the diagram model.
      ==> DONE
    * setting the title (and other features) of a diagram when creating the 
      initial model from Dash.elm
      ==> DONE
    * Refactor Dash.elm such that a library module for handling diagrams exists
      and a main module with ports, signals and wirings to connect to Elixir.
      ==> DONE
    * design an even larger frame with menu etc. 
  What not to do: 
    * Mess around with times etc in Elm since time is bound to signals.
--}




-- EFFECTS

-- PORTS

-- Write something towards phoenix
port sendValuePort : Signal Dash.Board.CounterType
port sendValuePort = 
    sendValueMailBox.signal 

-- Get something from phoenix
port getCounterValue : Signal Dash.Board.CounterMsg

-- Output Ports => results in drawing graph of diagram_stream via JS 
port data_graph_port : Signal JS.Value
port data_graph_port = diagram_stream_mailbox.signal

-- SIGNALS
setCounterAction: Signal Dash.Board.Action
setCounterAction = 
  Signal.map Dash.Board.make_counter_action getCounterValue

incomingActions : Signal Dash.Board.Action
incomingActions = setCounterAction

sendValueMailBox : Signal.Mailbox Dash.Board.CounterType
sendValueMailBox =
  let init = { date = 0 * Time.millisecond, value = 0}
  in Signal.mailbox (init) -- initial value!


-- WIRING

app : App Dash.Board.Model
app =
  StartApp.start
    { init = Dash.Board.init
    , update = Dash.Board.update
    , view = Dash.Board.view
    , inputs = [incomingActions]
    }

{-- --}
main : Signal Html
main =
  app.html


port tasks : Signal (Task Never ())
port tasks =
  app.tasks

