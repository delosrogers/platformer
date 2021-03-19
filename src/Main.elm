module Main exposing (main)

import Basics exposing (Float)
import Browser
import Browser.Events
import Canvas
import Canvas.Settings
import Color
import Html
import Html.Attributes exposing (width)
import Json.Decode as Decode
import Process
import Random
import Task


type alias Model =
    { player : Player
    , platforms : Platforms
    , alive : Bool
    }


type alias Platforms =
    List Platform


type alias Player =
    { x : Float
    , y : Float
    , vX : Float
    , vY : Float
    }


type alias Platform =
    { x : Float
    , y : Float
    , width : Float
    , vX : Float
    }


platformHeight : Float
platformHeight =
    10


playerSpeed : Float
playerSpeed =
    10


platformSpeed : Float
platformSpeed =
    2


init : () -> ( Model, Cmd Msg )
init _ =
    ( { player =
            { x = 0
            , y = 200
            , vX = 0
            , vY = 0
            }
      , platforms =
            [ { x = 0
              , y = 0
              , width = 100
              , vX = platformSpeed
              }
            ]
      , alive = True
      }
    , Cmd.none
    )


type Msg
    = OnAnimationFrame Float
    | KeyDown PlayerAction
    | KeyUp PlayerAction
    | RestartGame


type PlayerAction
    = Jump
    | Left
    | Right


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnAnimationFrame _ ->
            let
                updatedPlayer =
                    updatePlayer model

                updatedModel =
                    { model
                        | player = updatedPlayer
                        , platforms = movePlatforms model.platforms
                        , alive =
                            if updatedPlayer.y == 0 then
                                False

                            else
                                True
                    }
            in
            ( updatedModel, Cmd.none )

        KeyDown action ->
            case action of
                Jump ->
                    ( jumpPlayer model, Cmd.none )

                Left ->
                    ( { model | player = turnLeft model.player }, Cmd.none )

                Right ->
                    ( { model | player = turnRight model.player }, Cmd.none )

        KeyUp _ ->
            ( { model | player = stopXMotion model.player }, Cmd.none )

        RestartGame ->
            init ()


turnRight : Player -> Player
turnRight player =
    { player | vX = playerSpeed }


turnLeft : Player -> Player
turnLeft player =
    { player | vX = -1 * playerSpeed }


movePlatforms : Platforms -> Platforms
movePlatforms platforms =
    List.map (\platform -> { platform | x = platform.x + platform.vX }) platforms


stopXMotion : Player -> Player
stopXMotion player =
    { player | vX = 0 }


jumpPlayer : Model -> Model
jumpPlayer model =
    let
        player =
            model.player
    in
    { model
        | player =
            { player | vY = player.vY + 10 }
    }


updatePlayer : Model -> Player
updatePlayer model =
    let
        player =
            model.player

        platforms =
            model.platforms
    in
    if playerOnPlatforms player platforms then
        { player | x = player.x + player.vX, vY = 0 }

    else
        { player
            | x = player.x + player.vX
            , vY = player.vY - 1
            , y = player.y + player.vY
        }


playerOnPlatforms : Player -> List Platform -> Bool
playerOnPlatforms player platforms =
    List.map (playerOnPlatform player) platforms
        |> List.any (\x -> x)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


playerOnPlatform : Player -> Platform -> Bool
playerOnPlatform player platform =
    player.x
        > platform.x
        && player.x
        < platform.x
        + platform.width
        && player.y
        > platform.y
        && player.y
        < platform.y
        + platformHeight



-- VIEW


view : Model -> Html.Html Msg
view model =
    Canvas.toHtml ( 500, 500 )
        [ Html.Attributes.style "display" "block" ]
        [ renderPlayer model.player
        , renderPlatforms model.platforms
        ]


renderPlayer : Player -> Canvas.Renderable
renderPlayer player =
    Canvas.shapes [ Canvas.Settings.fill Color.red ] [ Canvas.circle ( player.x, player.y ) 15 ]


renderPlatforms : Platforms -> Canvas.Renderable
renderPlatforms platforms =
    Canvas.shapes [ Canvas.Settings.fill Color.red ]
        (List.map
            (\platform ->
                Canvas.rect ( platform.x, platform.y )
                    platform.width
                    platformHeight
            )
            platforms
        )
