module Dash where

import StartApp exposing (App)
import Effects exposing (Effects, Never)
import Task exposing (Task)
import Time exposing (Time)

import Html exposing (..)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)

import Dash.Diagram exposing (..)

{-- 
  What to do here properly: 
    * design a module for a time series chart, addressable, such 
      that incoming data can be sent to. ==> Data comes in from phoenix via sockets
    * design a larger frame, where charts can be embedded
    * design an even larger frame with menu etc. 
  What not to do: 
    * Mess around with times etc in Elm since time is bound to signals.
--}



init : (Model, Effects Action)
init =
  (reset_model, Effects.none)


-- MODEL
type alias Model = Dash.Diagram.Model
-- The counter holds the value and the current time stamp
type alias CounterType = {date: Time, value: Int}
type alias History = List CounterType

-- UPDATE

type Action 
  = NoOp 
  | Reset 
  | SubMessage Dash.Diagram.Action

update : Action -> Model -> (Model, Effects Action)
update action model = 
    case action of
        NoOp -> (model, Effects.none) -- do nothing
        Reset -> 
          (reset_model, Effects.map SubMessage (Dash.Diagram.show_diagram reset_model)) -- send 0 to the channel (= Effect)
        SubMessage diag_act -> 
          let
            (m, a) = Dash.Diagram.update (diag_act) model
          in
            (m, Effects.map SubMessage a)


reset_model : Model
reset_model = Dash.Diagram.init_model "elmChart"

-- EFFECTS

-- PORTS

-- Write something towards phoenix
port sendValuePort : Signal CounterType
port sendValuePort = 
    sendValueMailBox.signal 

-- Get something from phoenix
port getCounterValue : Signal CounterType

-- Output Ports => results in drawing graph of diagram_stream via JS 
port data_graph_port : Signal Simple_Options
port data_graph_port = diagram_stream_mailbox.signal

-- SIGNALS
setCounterAction: Signal Action
setCounterAction = 
  Signal.map (\v -> SubMessage (Dash.Diagram.NewValue v)) getCounterValue

incomingActions : Signal Action
incomingActions = setCounterAction

sendValueMailBox : Signal.Mailbox CounterType
sendValueMailBox =
  let init = { date = 0 * Time.millisecond, value = 0}
  in Signal.mailbox (init) -- initial value!

sendHistoryMailBox : Signal.Mailbox History
sendHistoryMailBox =
  Signal.mailbox ([]) -- initial value!

-- VIEW
view : Signal.Address Action -> Model -> Html.Html
view address model =
 div []
    [ h2 [] [(text "The Big Elm Chart - Single Chart variant")]
    , (diagView address model)
      ]

diagView : Signal.Address Action -> Model -> Html.Html
diagView address model = 
  let 
    wrap : Dash.Diagram.Action -> Action
    wrap = \x -> SubMessage x
  in
    Dash.Diagram.view_histogram (Signal.forwardTo address wrap) model


-- WIRING

app : App Model
app =
  StartApp.start
    { init = init
    , update = update
    , view = view
    , inputs = [incomingActions]
    }

{-- --}
main : Signal Html
main =
  app.html


port tasks : Signal (Task Never ())
port tasks =
  app.tasks

