module Dash.Diagram where

import Time exposing (Time)

----------------------------------------------------------------
-- TYPES
----------------------------------------------------------------
-- the target node of the diagram
type alias Target = String
type alias DataPoint = {date: Time, value: Int}
type alias History = List DataPoint
-- extensible record 
-- type alias Graph_Options = { a | data : History}

-- options for simple graphs
type alias Simple_Options = {
      data : History
    , target : Target
    , title : String
    , width : Int
    , height : Int
    , right : Int
}

-- simple_histogram
-- call this function with the Model history and
-- send the result of this as an effect to the mailbox
-- similar to sending the values to the forms
simple_histogram : History -> Target -> Simple_Options
simple_histogram hist_data the_target = 
    { 
        data = hist_data, 
        target = the_target, 
        title = "Simple Elm Historgram",
        width = 600,
        height = 200,
        right = 40
    }

-- diagram_stream 
diagram_stream_mailbox : Signal.Mailbox Simple_Options
diagram_stream_mailbox = 
    Signal.mailbox({data = [], title ="", target = "#",
        width = 0, height = 0, right = 0})     -- with initial value 

-- Output Ports => results in drawing graph of diagram_stream via JS 
port data_graph_port : Signal Simple_Options
port data_graph_port = diagram_stream_mailbox.signal

