module Main exposing (main)

import Basics exposing (Float)
import Browser
import Browser.Events
import Canvas
import Canvas.Settings
import Color
import Config
import GameLogic exposing (..)
import Html exposing (button, div, text)
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Random
import Types exposing (..)


init : () -> ( Model, Cmd Msg )
init _ =
    initWithBestScore 0


initWithBestScore : Int -> ( Model, Cmd Msg )
initWithBestScore hs =
    ( { player =
            { x = 50
            , y = 300
            , vX = 0
            , vY = 0
            }
      , alive = True
      , platforms =
            []
      , score = 0
      , highScore = hs
      }
    , Random.generate GenList genXPos
    )


genXPos : Random.Generator (List Float)
genXPos =
    Random.list 500 (Random.float 0 Config.width)


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg unshifted_model =
    let
        model =
            shiftModel unshifted_model
    in
    case msg of
        OnAnimationFrame _ ->
            if model.alive then
                let
                    updatedPlayer =
                        updatePlayer model
                in
                ( { model
                    | player = updatedPlayer
                    , platforms = movePlatforms model.platforms
                    , alive =
                        if updatedPlayer.y > Config.height then
                            False

                        else
                            True
                  }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        KeyDown action ->
            case action of
                Jump ->
                    ( jumpPlayer model, Cmd.none )

                Left ->
                    ( { model | player = turnLeft model.player }, Cmd.none )

                Right ->
                    ( { model | player = turnRight model.player }, Cmd.none )

                Other ->
                    ( model, Cmd.none )

        KeyUp action ->
            -- ( { model | player = stopXMotion model.player }, Cmd.none )
            case action of
                Other ->
                    ( model, Cmd.none )

                _ ->
                    ( { model | player = stopXMotion model.player }, Cmd.none )

        RestartGame ->
            initWithBestScore model.highScore

        GenList xPositions ->
            ( { model
                | platforms =
                    { x = 0, y = 300, vX = 0, width = Config.width }
                        :: List.indexedMap generatePlatforms xPositions
              }
            , Cmd.none
            )


generatePlatforms : Int -> Float -> Platform
generatePlatforms i xPos =
    { x = xPos
    , y = 300 - toFloat (i * 100)
    , width = toFloat 100
    , vX =
        ((0.05 * toFloat i) + 1)
            * toFloat
                (if modBy 2 i == 0 then
                    -1

                 else
                    1
                )
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Browser.Events.onAnimationFrameDelta (\x -> OnAnimationFrame x)
        , Browser.Events.onKeyDown keyDecoder
        , Browser.Events.onKeyUp keyUpDecoder
        ]


keyDecoder : Decode.Decoder Msg
keyDecoder =
    Decode.map toDirection (Decode.field "key" Decode.string)


toDirection : String -> Msg
toDirection string =
    case string of
        "ArrowLeft" ->
            KeyDown Left

        "ArrowRight" ->
            KeyDown Right

        "ArrowUp" ->
            KeyDown Jump

        "w" ->
            KeyDown Jump

        "a" ->
            KeyDown Left

        "d" ->
            KeyDown Right

        _ ->
            KeyDown Other


keyUpDecoder : Decode.Decoder Msg
keyUpDecoder =
    Decode.map
        (\string ->
            case string of
                "ArrowLeft" ->
                    KeyUp Left

                "ArrowRight" ->
                    KeyUp Right

                "a" ->
                    KeyUp Left

                "d" ->
                    KeyUp Right

                _ ->
                    KeyUp Other
        )
        (Decode.field "key" Decode.string)



-- VIEW


view : Model -> Html.Html Msg
view model =
    div []
        [ button [ Html.Events.onClick RestartGame ] [ text "reset" ]
        , text
            (" your score is "
                ++ String.fromInt model.score
                ++ " your high score is "
                ++ String.fromInt model.highScore
            )
        , if model.alive then
            Canvas.toHtml
                ( round Config.width, round Config.height )
                [ Html.Attributes.style "display" "block" ]
                [ Canvas.clear ( 0, 0 ) Config.width Config.height
                , renderPlayer model.player
                , renderPlatforms model.platforms
                ]

          else
            text " you died "
        ]


renderPlayer : Player -> Canvas.Renderable
renderPlayer player =
    Canvas.shapes [ Canvas.Settings.fill Color.blue ] [ Canvas.circle ( player.x, player.y ) 15 ]


renderPlatforms : Platforms -> Canvas.Renderable
renderPlatforms platforms =
    Canvas.shapes []
        (List.map
            (\platform ->
                Canvas.rect ( platform.x, platform.y )
                    platform.width
                    Config.platformHeight
            )
            platforms
        )
