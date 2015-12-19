module Dash.Diagram where

import Time exposing (Time)
import List exposing (..)

----------------------------------------------------------------
-- TYPES
----------------------------------------------------------------
-- the target node of the diagram
type alias Target = String
type alias DataPoint = {date: Time, value: Int}
type alias History = List DataPoint

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


-- diagram_stream 
diagram_stream_mailbox : Signal.Mailbox Simple_Options
diagram_stream_mailbox = 
    Signal.mailbox({data = [], title ="", target = "#",
        min_x = Nothing,
        width = 0, height = 0, right = 0})     -- with initial value 

