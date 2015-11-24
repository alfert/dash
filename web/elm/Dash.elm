module Dash where

import StartApp exposing (App)
import Effects exposing (Effects, Never)
import Task exposing (Task)

import Html exposing (..)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)


init : (Model, Effects Action)
init =
  (reset_model, Effects.none)


-- MODEL
type alias Model = (CounterType, History)
type alias CounterType = Int
type alias History = List CounterType

-- UPDATE

type Action = NoOp | Reset | Inc | NewValue CounterType

update : Action -> Model -> (Model, Effects Action)
update action model = 
    case action of
        NoOp -> (model, Effects.none) -- do nothing
        Reset -> (reset_model, publish_model reset_model) -- send 0 to the channel (= Effect)
        Inc -> let m = inc_model model 
          in (m, publish_model m) -- send the new model value
        NewValue value -> let m = set_model value model 
          in (m, Effects.none) -- receive a new value and store it as model value

reset_model : Model
reset_model = (0, [0])

inc_model : Model -> Model
inc_model (x, xs) = (x+1, (x+1) :: xs)

set_model : Int -> Model -> Model
set_model value (_, xs) = (value, value :: xs)


-- EFFECTS

publish_model : Model -> Effects Action
publish_model (x, history) =
  let 
    eff s = s |> Effects.task |> Effects.map (always NoOp)
  in
    Effects.batch [
      Signal.send sendValueMailBox.address x |> eff,
      Signal.send sendHistoryMailBox.address history |> eff 
    ]
    

-- PORTS

-- Write something towards phoenix
port sendValuePort : Signal CounterType
port sendValuePort = 
    sendValueMailBox.signal 

-- Get something from phoenix
port getCounterValue : Signal CounterType
-- port getCounterValue = Signal.constant 0

-- Send the current history to D3 time series
port sendHistoryPort : Signal History
port sendHistoryPort = sendHistoryMailBox.signal

-- SIGNALS
setCounterAction: Signal Action
setCounterAction = Signal.map NewValue getCounterValue

incomingActions : Signal Action
incomingActions = setCounterAction

sendValueMailBox : Signal.Mailbox CounterType
sendValueMailBox =
  Signal.mailbox (0) -- initial value!?

sendHistoryMailBox : Signal.Mailbox History
sendHistoryMailBox =
  Signal.mailbox ([]) -- initial value!

-- VIEW
view : Signal.Address Action -> Model -> Html.Html
view address model =
 div []
    [ button [ onClick address Reset ] [ text "Reset" ]
    , div [ countStyle ] [ text (toString model) ]
    , button [ onClick address Inc ] [ text "+" ]
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


main : Signal Html
main =
  app.html


port tasks : Signal (Task Never ())
port tasks =
  app.tasks

