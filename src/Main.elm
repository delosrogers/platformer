module Main exposing (main)

import Basics exposing (Float)
import Browser
import Browser.Events
import Canvas
import Canvas.Settings
import Color
import Html exposing (button, div, text)
import Html.Attributes exposing (width)
import Html.Events
import Json.Decode as Decode
import Random


type alias Model =
    { player : Player
    , platforms : Platforms
    , alive : Bool
    , score : Int
    , highScore : Int
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
    5


platformSpeed : Float
platformSpeed =
    0


width : Float
width =
    400


height : Float
height =
    700


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
    Random.list 500 (Random.float 0 width)


type Msg
    = OnAnimationFrame Float
    | KeyDown PlayerAction
    | KeyUp PlayerAction
    | RestartGame
    | GenList ListOfFloat


type alias ListOfFloat =
    List Float


type PlayerAction
    = Jump
    | Left
    | Right
    | Other


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
                        if updatedPlayer.y > height then
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
                | platforms = { x = 0, y = 300, vX = 0, width = width } :: List.indexedMap generatePlatforms xPositions
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


shiftModel : Model -> Model
shiftModel model =
    let
        player =
            model.player

        newScore =
            model.score + 2
    in
    if model.player.y < 300 then
        { model
            | player = { player | y = player.y + 2 }
            , platforms =
                List.map
                    (\platform ->
                        { platform | y = platform.y + 2 }
                    )
                    model.platforms
            , score = newScore
            , highScore = max newScore model.highScore
        }

    else
        model


turnRight : Player -> Player
turnRight player =
    { player | vX = playerSpeed }


turnLeft : Player -> Player
turnLeft player =
    { player | vX = -1 * playerSpeed }


movePlatforms : Platforms -> Platforms
movePlatforms platforms =
    List.map (\platform -> { platform | x = (platform.x + platform.vX) |> round |> modBy (round width) |> abs |> toFloat }) platforms


stopXMotion : Player -> Player
stopXMotion player =
    { player | vX = 0 }


jumpPlayer : Model -> Model
jumpPlayer model =
    let
        player =
            model.player
    in
    if playerOnPlatforms player model.platforms then
        { model
            | player =
                { player | vY = player.vY + 5, y = player.y - platformHeight - 1 }
        }

    else
        model


gravity =
    0.1


updatePlayer : Model -> Player
updatePlayer model =
    let
        player =
            model.player

        platforms =
            model.platforms
    in
    if playerOnPlatforms player platforms then
        if player.vY > 0 then
            { player
                | x = player.x + player.vX |> playerWrapAround
                , vY = -1 * player.vY
                , y = player.y + gravity + 5
            }

        else
            { player
                | x = player.x + player.vX |> playerWrapAround
                , vY = 0
            }

    else
        { player
            | x = player.x + player.vX |> playerWrapAround
            , vY = player.vY - gravity
            , y = player.y - player.vY
        }


playerWrapAround : Float -> Float
playerWrapAround x =
    x |> round |> modBy (round width) |> abs |> toFloat


playerOnPlatforms : Player -> List Platform -> Bool
playerOnPlatforms player platforms =
    List.map (playerOnPlatform player) platforms
        |> List.any (\x -> x)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
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

                _ ->
                    KeyUp Other
        )
        (Decode.field "key" Decode.string)


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
                ( round width, round height )
                [ Html.Attributes.style "display" "block" ]
                [ Canvas.clear ( 0, 0 ) width height
                , renderPlayer model.player
                , renderPlatforms model.platforms
                ]

          else
            text " you died "
        ]


renderPlayer : Player -> Canvas.Renderable
renderPlayer player =
    Canvas.shapes [ Canvas.Settings.fill Color.red ] [ Canvas.circle ( player.x, player.y ) 15 ]


renderPlatforms : Platforms -> Canvas.Renderable
renderPlatforms platforms =
    Canvas.shapes []
        (List.map
            (\platform ->
                Canvas.rect ( platform.x, platform.y )
                    platform.width
                    platformHeight
            )
            platforms
        )
