module Dash where

import StartApp.Simple exposing (start)

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)

main = start { model = 0, update = update, view = view }

-- MODEL
type alias Model = Int

-- UPDATE

type Action = Reset | Inc | NewValue

update : Action -> Model -> Model
update action model = 
    case action of
        Reset -> 0
        Inc -> model + 1

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
