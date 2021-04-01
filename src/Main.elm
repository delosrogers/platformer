module Main exposing (main)

import Basics exposing (Float)
import Browser
import Browser.Events
import Canvas
import Canvas.Settings
import Color
import Config
import GameLogic exposing (..)
import Html exposing (button, div, span, text)
import Html.Attributes
import Html.Events
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Random
import Types exposing (..)


init : Flags -> ( Model, Cmd Msg )
init flags =
    initWithState 0
        Nothing
        (if flags.id == "a" then
            Nothing

         else
            Just flags.id
        )
        flags.xsrf
        (if flags.id == "a" then
            False

         else
            True
        )
        Nothing


initWithState : Int -> Maybe String -> Maybe String -> String -> Bool -> Maybe (List LeaderboardItem) -> ( Model, Cmd Msg )
initWithState hs name id xsrf fetchState leaderboard =
    ( { player =
            { x = 150
            , y = 275
            , vX = 0
            , vY = 0
            }
      , alive = True
      , platforms =
            []
      , score = 0
      , highScore = hs
      , name = name
      , message = Nothing
      , userID = id
      , xsrf = xsrf
      , leaderboard = leaderboard
      }
    , if fetchState then
        Cmd.batch
            [ Random.generate GenList genXPos
            , getScore id xsrf
            , getLeaderboard
            ]

      else
        Cmd.batch [ Random.generate GenList genXPos, getLeaderboard ]
    )


genXPos : Random.Generator (List Float)
genXPos =
    Random.list 200 (Random.float 0 Config.width)


main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


saveScore : Model -> Cmd Msg
saveScore model =
    Http.request
        { method = "PUT"
        , headers = [ Http.header "CSRF-Token" model.xsrf ]
        , url =
            "api/v1/u/"
                ++ Maybe.withDefault "" model.userID
                ++ "/highscore"
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "score", Encode.int model.highScore ) ]
                )
        , expect = Http.expectWhatever SavedHighScoreApiResp
        , timeout = Nothing
        , tracker = Nothing
        }


getScore : Maybe String -> String -> Cmd Msg
getScore userID xsrf =
    Http.request
        { method = "GET"
        , headers = [ Http.header "CSRF-Token" xsrf ]
        , url =
            "api/v1/u/"
                ++ Maybe.withDefault "" userID
        , body = Http.emptyBody
        , timeout = Nothing
        , tracker = Nothing
        , expect = Http.expectJson ScoreNameApiResp scoreNameDecoder
        }


scoreNameDecoder : Decode.Decoder ScoreApiRes
scoreNameDecoder =
    Decode.map3 ScoreApiRes
        (Decode.field "_id" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "highScore" Decode.int)


getLeaderboard : Cmd Msg
getLeaderboard =
    Http.get
        { url = "api/v1/leaderboard"
        , expect = Http.expectJson LeaderboardApiResp leaderboardDecoder
        }


leaderboardDecoder : Decode.Decoder (List LeaderboardItem)
leaderboardDecoder =
    Decode.list
        (Decode.map2 LeaderboardItem
            (Decode.field "name" Decode.string)
            (Decode.field "highScore" Decode.int)
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg unshifted_model =
    let
        model =
            shiftModel unshifted_model
    in
    case msg of
        ScoreNameApiResp resp ->
            case resp of
                Ok playerInfo ->
                    ( { model
                        | highScore = max model.highScore playerInfo.highScore
                        , name = Just playerInfo.name
                        , message = Nothing
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( { model | message = Just "Something went wrong fetching your score and name" }, Cmd.none )

        LeaderboardApiResp resp ->
            case resp of
                Ok leaderboard ->
                    ( { model
                        | leaderboard = Just leaderboard
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        SavedHighScoreApiResp resp ->
            case resp of
                Ok _ ->
                    ( { model | message = Just "saved" }, Cmd.none )

                Err _ ->
                    ( { model | message = Just "Something went wrong saving your score" }, Cmd.none )

        SaveScore ->
            ( model
            , saveScore model
            )

        GetScoreAndName ->
            ( model
            , getScore model.userID model.xsrf
            )

        IdInput newId ->
            ( { model | userID = Just newId }, Cmd.none )

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
                , if model.alive && updatedPlayer.y > Config.height then
                    saveScore model

                  else
                    Cmd.none
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
            initWithState model.highScore model.name model.userID model.xsrf False model.leaderboard

        GenList xPositions ->
            ( { model
                | platforms =
                    { x = 0, y = 300, vX = 0, width = Config.width, kind = Normal }
                        :: List.indexedMap generatePlatforms xPositions
              }
            , Cmd.none
            )


generatePlatforms : Int -> Float -> Platform
generatePlatforms i xPos =
    { x = xPos
    , y = 200 - toFloat (i * 100)
    , width = toFloat 100
    , vX =
        ((0.05 * toFloat i) + 1)
            * toFloat
                (if modBy 2 (round xPos) == 0 then
                    -1

                 else
                    1
                )
    , kind =
        if modBy 5 i == 0 then
            Boosted

        else
            Normal
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
    div [ Html.Attributes.class "container" ]
        [ div [ Html.Attributes.classList [ ( "justify-content-center", True ), ( "row", True ) ] ]
            [ div [ Html.Attributes.class "col" ]
                [ button [ Html.Events.onClick RestartGame, Html.Attributes.class "btn-primary" ] [ text "reset" ]
                , div []
                    [ Html.button [ Html.Events.onClick SaveScore ] [ Html.text "save" ]
                    , case model.userID of
                        Just _ ->
                            text " signed in "

                        Nothing ->
                            Html.a [ Html.Attributes.href "/auth/google" ] [ text "sign in with google (this will cause you to lose your highscore)" ]
                    ]
                , div [ Html.Attributes.class "center-block" ]
                    [ text
                        ("Hi "
                            ++ Maybe.withDefault "" model.name
                            ++ " your score is "
                            ++ String.fromInt model.score
                            ++ " your high score is "
                            ++ String.fromInt model.highScore
                        )
                    ]
                , case model.message of
                    Just msg ->
                        div [] [ text msg ]

                    Nothing ->
                        span [] []
                , if model.alive then
                    Canvas.toHtml
                        ( round Config.width - 100, round Config.height )
                        [ Html.Attributes.style "display" "block" ]
                        (Canvas.clear ( 0, 0 ) Config.width Config.height
                            :: renderPlayer model.player
                            :: renderPlatforms model.platforms
                        )

                  else
                    text " you died "
                ]
            , div [ Html.Attributes.class "col" ]
                [ Html.h2 [] [ text "Leaderboard:" ], renderLeaderboard model.leaderboard ]
            ]
        ]


renderPlayer : Player -> Canvas.Renderable
renderPlayer player =
    Canvas.shapes [ Canvas.Settings.fill Color.blue ] [ Canvas.circle ( player.x - 100, player.y ) 15 ]


renderPlatforms : Platforms -> List Canvas.Renderable
renderPlatforms platforms =
    List.map
        (\platform ->
            case platform.kind of
                Boosted ->
                    Canvas.shapes [ Canvas.Settings.fill Color.red ]
                        [ Canvas.rect ( platform.x - 100, platform.y )
                            platform.width
                            Config.platformHeight
                        ]

                Normal ->
                    Canvas.shapes []
                        [ Canvas.rect ( platform.x - 100, platform.y )
                            platform.width
                            Config.platformHeight
                        ]
        )
        platforms


renderLeaderboard : Maybe (List LeaderboardItem) -> Html.Html Msg
renderLeaderboard maybeLeaderboard =
    case maybeLeaderboard of
        Just leaderboard ->
            div []
                (List.map
                    (\item -> div [] [ text (Maybe.withDefault "no name" (List.head (String.split " " item.name)) ++ ": " ++ String.fromInt item.score) ])
                    leaderboard
                )

        Nothing ->
            span [] [ text "sign in to view leaderboard" ]
