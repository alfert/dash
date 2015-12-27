module Dash where

import StartApp exposing (App)
import Effects exposing (Effects, Never)
import Task exposing (Task)
import Time exposing (Time)
import Dict exposing (Dict)

import Html exposing (..)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)

import Dash.Diagram exposing (..)
import Json.Encode exposing (Value)

{-- 
  What to do here properly: 
    * design a module for a time series chart, addressable, such 
      that incoming data can be sent to. ==> Data comes in from phoenix via sockets
      ==> DONE
    * design a larger frame, where charts can be embedded. The model is a dictionary,
      mapping ids (or targets) to the diagram model.
    * design an even larger frame with menu etc. 
  What not to do: 
    * Mess around with times etc in Elm since time is bound to signals.
--}



init : (Model, Effects Action)
init =
  (reset_model, Effects.none)


-- MODEL
type alias Id = String 
type alias Model = Dict.Dict Id Dash.Diagram.Model

-- the counter update message as sent from Phoenix
type alias CounterMsg = {id: Id, counter: CounterType}
-- The counter holds the value and the current time stamp
type alias CounterType = {date: Time, value: Int}
type alias History = List CounterType

-- UPDATE

type Action 
  = NoOp 
  | Reset Id
  | SubMessage Id Dash.Diagram.Action

update : Action -> Model -> (Model, Effects Action)
update action model = 
    case action of
        NoOp -> (model, Effects.none) -- do nothing
        Reset id -> reset_single_diagram id reset_model
        SubMessage id diag_act -> update_single_diagram id diag_act model
          
update_single_diagram : Id -> Dash.Diagram.Action -> Model -> (Model, Effects Action)
update_single_diagram id diag_act model = 
    let
      diag = get_diagram id model 
      (d, a) = Dash.Diagram.update (diag_act) diag
      m = Dict.update id (\v -> Just d) model
    in
      (m, Effects.map (SubMessage id) a)

reset_single_diagram : Id -> Model -> (Model, Effects Action)
reset_single_diagram id model = 
  let
      diag = get_diagram id model
      (d, a) = Dash.Diagram.reset diag
      m = Dict.update id (\v -> Just d) model
    in
      (m, Effects.map (SubMessage id) a)

reset_model : Model
reset_model = 
  let id = "elmChart" 
  in Dict.singleton id (Dash.Diagram.init_model id)

-- expects that the key exists. there is no runtime error,
-- but an empty diagram is returned, if the key is not in the model
get_diagram: Id -> Model -> Dash.Diagram.Model
get_diagram id model = 
  let
    emptyDiagram = Dash.Diagram.init_model "Unknown Identifier for Chart"
  in 
    Maybe.withDefault emptyDiagram (Dict.get id model)

-- EFFECTS

-- PORTS

-- Write something towards phoenix
port sendValuePort : Signal CounterType
port sendValuePort = 
    sendValueMailBox.signal 

-- Get something from phoenix
port getCounterValue : Signal CounterMsg

-- Output Ports => results in drawing graph of diagram_stream via JS 
port data_graph_port : Signal Json.Encode.Value
port data_graph_port = diagram_stream_mailbox.signal

-- SIGNALS
setCounterAction: Signal Action
setCounterAction = 
  Signal.map (\v -> 
      SubMessage v.id (Dash.Diagram.new_value v.counter)) getCounterValue

incomingActions : Signal Action
incomingActions = setCounterAction

sendValueMailBox : Signal.Mailbox CounterType
sendValueMailBox =
  let init = { date = 0 * Time.millisecond, value = 0}
  in Signal.mailbox (init) -- initial value!

-- VIEW
view : Signal.Address Action -> Model -> Html.Html
view address model =
 div []
    [ h2 [] [(text "The Big Elm Chart - List Chart variant")]
    , div [] (all_diags address model)
    ]

all_diags : Signal.Address Action ->Model -> List Html.Html
all_diags address model = 
  Dict.toList model 
    |> List.map (\entry -> 
      let (id, v) = entry
      in diagView address id v)

diagView : Signal.Address Action -> Id -> Dash.Diagram.Model -> Html.Html
diagView address id model = 
  let 
    wrap : Dash.Diagram.Action -> Action
    wrap = \x -> SubMessage id x
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

