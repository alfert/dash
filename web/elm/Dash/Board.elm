module Dash.Board (view, update, init, make_counter_action,
    Action, Model, CounterMsg, CounterType) where

import Dict exposing (Dict)
import Effects exposing (Effects, Never)
import Html exposing (..)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Time exposing (Time)
import Json.Encode as JS -- exposing (Value)

import Dash.Diagram exposing (..)


----------------------------------------------------------------
-- MODEL
----------------------------------------------------------------
type alias Id = String 
type alias Model = Dict.Dict Id Dash.Diagram.Model

-- the counter update message as sent from Phoenix
type alias CounterMsg = {id: Id, counter: CounterType}
-- The counter holds the value and the current time stamp
type alias CounterType = {date: Time, value: Int}
type alias History = List CounterType

init : (Model, Effects Action)
init =
  (reset_model, Effects.none)

----------------------------------------------------------------
-- UPDATE
----------------------------------------------------------------
type Action 
  = NoOp 
  | Reset Id
  | SubMessage Id Dash.Diagram.Action

make_counter_action : CounterMsg -> Action
make_counter_action v = 
      SubMessage v.id (Dash.Diagram.new_value v.counter)

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
  let 
    id = "elmChart" 
    title = id
  in Dict.singleton id (Dash.Diagram.init_model id title)

-- expects that the key exists. there is no runtime error,
-- but an empty diagram with new key is returned, if the key is not in the model
get_diagram: Id -> Model -> Dash.Diagram.Model
get_diagram id model = 
  let
    opts = [("y_scale_type", JS.string "linear") ]
    emptyDiagram = Dash.Diagram.init_model_with_opts id (diagram_title id) opts
  in 
    Maybe.withDefault emptyDiagram (Dict.get id model)

diagram_title : Id -> String
diagram_title id = case id of
  "first" -> "Diagram No 1: Counter First"
  "second" -> "Diagram No 2: Counter Second"
  _ ->  "Unknown Identifier for Chart"
----------------------------------------------------------------
-- VIEW
----------------------------------------------------------------
view : Signal.Address Action -> Model -> Html.Html
view address model =
 div []
    [ h2 [class "chart_title"] [(text "The Big Elm Chart - List Chart variant")]
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



