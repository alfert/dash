module Dash where

import StartApp exposing (App)
import Effects exposing (Effects, Never)
import Task exposing (Task)

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)


init : (Model, Effects Action)
init =
  (0, Effects.none)


-- MODEL
type alias Model = Int

-- UPDATE

type Action = NoOp | Reset | Inc | NewValue Model

update : Action -> Model -> (Model, Effects Action)
update action model = 
    case action of
        NoOp -> (model, Effects.none) -- do nothing
        Reset -> (0, send_value_to_server 0) -- should send something to the channel (= Effect)
        Inc -> (model + 1, send_value_to_server (model + 1))
        NewValue value -> (value, Effects.none)

-- EFFECTS

send_value_to_server : Model -> Effects Action
send_value_to_server model =
  Signal.send sendValueMailBox.address model
    |> Effects.task
    |> Effects.map (always NoOp)

-- PORTS

-- Write something towards phoenix
port sendValuePort : Signal Model
port sendValuePort = 
    sendValueMailBox.signal 

-- Get something from phoenix
port getCounterValue : Signal Model
-- port getCounterValue = Signal.constant 0

-- SIGNALS
setCounterAction: Signal Action
setCounterAction = Signal.map NewValue getCounterValue

incomingActions : Signal Action
incomingActions = setCounterAction

sendValueMailBox : Signal.Mailbox Model
sendValueMailBox =
  Signal.mailbox (0) -- initial value!?

-- VIEW
view : Signal.Address Action -> Model -> Html.Html
view address model =
 div []
    [ button [ onClick address Reset ] [ text "Reset" ]
    , div [ countStyle ] [ text (toString model) ]
    , button [ onClick address Inc ] [ text "+" ]
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

