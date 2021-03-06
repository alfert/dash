module Dash.Diagram 
    (DataPoint, Model, Action, reset, update, init_model, init_model_with_opts,
        view_histogram, new_value,
        diagram_stream_mailbox) where

import Time exposing (Time)
import List exposing (..)
import Dict exposing (Dict)
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
type alias DiagOptions = List (String, JS.Value)

-- Each diagram has an id (its target) and the history of data points
-- type alias Model = {id: Target, history: History}
type Action = NoOp | Reset | NewValue DataPoint

-- options for simple graphs
type alias Simple_Options_X = Model
type alias Model = {
      id: Target
    , data : History
    , target : Target
    , title : String
    , opts : DiagOptions
}

--toJson : Simple_Options_X -> JS.Value
toJson : Model -> JS.Value
toJson opts = 
    let
        fields = [
         ("data", history_to_json opts.data)
        ,("target", JS.string opts.target)
        ,("title", JS.string opts.title)
    ] 
    in 
        JS.object (fields ++ opts.opts)

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
set_model data m = Debug.log "set_model: " { m | data = data :: m.data}

-- The initial state of the model is the empty list.
init_model : Target -> String -> Model
init_model new_id new_title = {
    id = new_id,
    data = [],
    target = "#" ++ new_id, 
    title = new_title,
    opts = [ 
         ("interpolate", JS.string "basic")
        ,("area", JS.bool True) 
        ,("x_sort", JS.bool False)
        ,("european_clock", JS.bool True)
        ,("width", JS.int 600)
        ,("height", JS.int 200)
        ,("right", JS.int 40)
        ]
    }

init_model_with_opts : Target -> String -> DiagOptions -> Model
init_model_with_opts id title new_opts = 
    let 
        m : Model
        m = init_model id title
        -- make a dictionary from the model's option list for easier updates
        d : Dict String JS.Value
        d = Dict.fromList m.opts
        -- update the option dictionary
        apply_opts : (String, JS.Value) -> Dict String JS.Value -> Dict String JS.Value
        apply_opts = \(key, value) -> \opts -> 
            Dict.update key (\_ -> Just value ) opts 
        -- fold all new options into the default options
        all_opts : Dict String JS.Value
        -- List.foldl: (a -> b -> b) -> b -> List a -> b
        all_opts = List.foldl apply_opts d new_opts
    in 
        { m | opts = Dict.toList all_opts}

-- reset the to model to the initial values
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
simple_histogram : Model -> Simple_Options_X
simple_histogram m  = m 
    
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
    init_model "" ""
        |> simple_histogram 
        |> toJson 
        |> Signal.mailbox
