module Dash.Diagram where

import Time exposing (Time)
import List exposing (..)
import Html exposing (..)
import Html.Attributes exposing (class, id)
import Effects exposing (Effects, Never)

----------------------------------------------------------------
-- TYPES
----------------------------------------------------------------
-- the target node of the diagram
type alias Target = String
type alias DataPoint = {date: Time, value: Int}
type alias History = List DataPoint

type alias Model = History
type Action = NoOp | NewValue DataPoint

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

----------------------------------------------------------------
-- Update the model
----------------------------------------------------------------
update : Action -> Model -> (Model, Effects Action)
update action model = 
    case action of
        NoOp -> (model, Effects.none) -- do nothing
        NewValue value -> let m = set_model value model 
          in (m, show_diagram m) -- receive a new value and store it as model value


-- puts a new datapoint on top of the list.
set_model : DataPoint -> Model -> Model
set_model value xs = Debug.log "set_model: " value :: xs

-- The initial state of the model is the empty list.
init_model : Model
init_model = []


----------------------------------------------------------------
-- View the histogram
----------------------------------------------------------------
view_histogram : Target -> Signal.Address Action -> Model -> Html.Html 
view_histogram diagram_id address model = 
    p [id diagram_id] []

-- simple_histogram
-- call this function with the Model history and
-- send the result of this as an effect to the mailbox
-- similar to sending the values to the forms
simple_histogram : History -> Target -> Simple_Options
simple_histogram hist_data the_target = 
    { 
        data = hist_data 
            |> filter (\x -> x.date > 0),
        target = the_target, 
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
show_diagram history =
  let 
    eff s = s |> Effects.task |> Effects.map (always NoOp)
    diagram = Debug.log "show_diagram: " (simple_histogram history "#elmChart")
  in
    Effects.batch [
      Signal.send diagram_stream_mailbox.address diagram |> eff 
    ]


-- diagram_stream 
diagram_stream_mailbox : Signal.Mailbox Simple_Options
diagram_stream_mailbox = 
    Signal.mailbox({data = [], title ="", target = "#",
        min_x = Nothing,
        width = 0, height = 0, right = 0})     -- with initial value 

