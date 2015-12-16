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
type alias Model = (CounterType, History)
-- The counter holds the value and the current time stamp
type alias CounterType = {date: Time, value: Int}
type alias History = List CounterType

-- UPDATE

type Action = NoOp | Reset | Inc Time | NewValue CounterType

update : Action -> Model -> (Model, Effects Action)
update action model = 
    case action of
        NoOp -> (model, Effects.none) -- do nothing
        Reset -> (reset_model, publish_model reset_model) -- send 0 to the channel (= Effect)
        Inc t -> let m = inc_model t model 
          in (m, publish_model m) -- send the new model value
        NewValue value -> let m = set_model value model 
          in (m, show_diagram m) -- receive a new value and store it as model value

reset_model : Model
reset_model = 
  let m = {value = 0, date = 0 * Time.millisecond} 
  in (m, [m])

inc_model : Time -> Model -> Model
inc_model t ( x, xs) = 
  let count = {date = t, value = x.value + 1}
  in
    (count, count :: xs)

set_model : CounterType -> Model -> Model
set_model value (_, xs) = Debug.log "set_model: " (value, value :: xs)


-- EFFECTS

------ Problem: The history data is not sent to the port. 
------          Nothing appears in the console.log

publish_model : Model -> Effects Action
publish_model (x, history) =
  let 
    eff s = s |> Effects.task |> Effects.map (always NoOp)
    diagram = Debug.log "publish model: " (Dash.Diagram.simple_histogram history "#elmChart")
  in
    Effects.batch [
      Signal.send sendValueMailBox.address x |> eff,
      Signal.send sendHistoryMailBox.address history |> eff,
      Signal.send diagram_stream_mailbox.address diagram |> eff 
    ]
    
-- send the model to draw a diagram
show_diagram : Model -> Effects Action
show_diagram (x, history) =
  let 
    eff s = s |> Effects.task |> Effects.map (always NoOp)
    diagram = Debug.log "show_diagram: " (Dash.Diagram.simple_histogram history "#elmChart")
  in
    Effects.batch [
      Signal.send diagram_stream_mailbox.address diagram |> eff 
    ]

-- PORTS

-- Write something towards phoenix
port sendValuePort : Signal CounterType
port sendValuePort = 
    sendValueMailBox.signal 

-- Get something from phoenix
port getCounterValue : Signal CounterType

-- Send the current history to D3 time series
port sendHistoryPort : Signal History
port sendHistoryPort = sendHistoryMailBox.signal

-- Output Ports => results in drawing graph of diagram_stream via JS 
port data_graph_port : Signal Simple_Options
port data_graph_port = diagram_stream_mailbox.signal

-- SIGNALS
setCounterAction: Signal Action
setCounterAction = Signal.map NewValue getCounterValue

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
    [ button [ onClick address Reset ] [ text "Reset" ]
    , div [ countStyle ] [ text (toString model) ]
    , button [ onClick address (Inc 0) ] [ text "+" ]
    , p [id "counterChart"] []
    , p [id "elmChart"] []
    ]
countStyle : Html.Attribute 
countStyle = class "form.button"

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

