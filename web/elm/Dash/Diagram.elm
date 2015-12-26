module Dash.Diagram 
    (DataPoint, Model, Action, reset, update, init_model, view_histogram, new_value,
        diagram_stream_mailbox) where

import Time exposing (Time)
import List exposing (..)
import Html exposing (..)
import Html.Attributes exposing (class, id)
import Effects exposing (Effects, Never)
import Json.Encode as JS

----------------------------------------------------------------
-- TYPES
----------------------------------------------------------------
-- the target node of the diagram
type alias Target = String
type alias DataPoint = {date: Time, value: Int}
type alias History = List DataPoint

-- Each diagram has an id (its target) and the history of data points
type alias Model = {id: Target, history: History}
type Action = NoOp | Reset | NewValue DataPoint

-- options for simple graphs
type alias Simple_Options = {
      data : History
    , target : Target
    , title : String
    , width : Int
    , height : Int
    , right : Int
    , min_x : Maybe Float
}

toJson : Simple_Options -> JS.Value
toJson opts = 
    JS.object [
         ("data", history_to_json opts.data)
        ,("target", JS.string opts.target)
        ,("title", JS.string opts.title)
        ,("width", JS.int opts.width)
        ,("height", JS.int opts.height)
        ,("right", JS.int opts.right)
        ,("min_x", maybe_to_json opts.min_x)
    ]

history_to_json : History -> JS.Value
history_to_json h = JS.list (map dp_to_json h)
dp_to_json : DataPoint -> JS.Value
dp_to_json dp = JS.object [
    ("date", JS.float dp.date), 
    ("value", JS.int dp.value)
    ]
maybe_to_json : Maybe Float -> JS.Value
maybe_to_json x = case x of
    Just v -> JS.float v
    Nothing -> JS.null

new_value : DataPoint -> Action
new_value dp = NewValue dp

----------------------------------------------------------------
-- Update the model
----------------------------------------------------------------
update : Action -> Model -> (Model, Effects Action)
update action model = 
    case action of
        NoOp -> (model, Effects.none) -- do nothing
        Reset -> (model, show_diagram model) -- set a (empty?) model and show it
        NewValue value -> let m = set_model value model 
          in (m, show_diagram m) -- receive a new value and store it as model value


-- puts a new datapoint on top of the list.
set_model : DataPoint -> Model -> Model
set_model data m = Debug.log "set_model: " { m | history = data :: m.history}

-- The initial state of the model is the empty list.
init_model : Target -> Model
init_model new_id = {id = new_id, history = []}

-- 
reset : Model -> (Model, Effects Action)
reset model = update Reset model

----------------------------------------------------------------
-- View the histogram
----------------------------------------------------------------
view_histogram : Signal.Address Action -> Model -> Html.Html 
view_histogram address model = 
    p [id model.id] []

-- simple_histogram
-- call this function with the Model history and
-- send the result of this as an effect to the mailbox
-- similar to sending the values to the forms
simple_histogram : Model -> Simple_Options
simple_histogram m  = 
    { 
        data = m.history
            |> filter (\x -> x.date > 0),
        target = "#" ++ m.id, 
        title = "Simple Elm Histogram",
        width = 600,
        height = 200,
        right = 40,
        min_x = Nothing -- min_gt_zero hist_data
    }

min_gt_zero: History -> Maybe Float
min_gt_zero hist = 
    hist 
        |> map (\x -> x.date) 
        |> filter (\x -> x > 0)
        |> minimum

----------------------------------------------------------------
-- Update the histogram chart with new data 
----------------------------------------------------------------
-- send the model to draw a diagram
show_diagram : Model -> Effects Action
show_diagram m =
  let 
    eff s = s |> Effects.task |> Effects.map (always NoOp)
    diagram = Debug.log "show_diagram: " (simple_histogram m)
  in
    Effects.batch [
      (Signal.send diagram_stream_mailbox.address (diagram |> toJson)) |> eff 
    ]


-- diagram_stream mailbox with initial value
diagram_stream_mailbox : Signal.Mailbox JS.Value
diagram_stream_mailbox = 
    init_model "" 
        |> simple_histogram 
        |> toJson 
        |> Signal.mailbox
