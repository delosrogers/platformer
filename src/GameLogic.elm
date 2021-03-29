module GameLogic exposing
    ( jumpPlayer
    , movePlatforms
    , shiftModel
    , stopXMotion
    , turnLeft
    , turnRight
    , updatePlayer
    )

import Config exposing (..)
import Types exposing (..)


updatePlayer : Model -> Player
updatePlayer model =
    let
        player =
            model.player

        platforms =
            model.platforms
    in
    case playerOnPlatforms player platforms of
        Just _ ->
            if player.vY > 0 then
                { player
                    | x = player.x + player.vX |> playerWrapAround
                    , vY = -1 * player.vY
                    , y = player.y + gravity + 10
                }

            else
                { player
                    | x = player.x + player.vX |> playerWrapAround
                    , vY = 0
                }

        Nothing ->
            { player
                | x = player.x + player.vX |> playerWrapAround
                , vY = player.vY - gravity
                , y = player.y - player.vY
            }


playerWrapAround : Float -> Float
playerWrapAround x =
    x |> round |> modBy (round width) |> abs |> toFloat


playerOnPlatforms : Player -> List Platform -> Maybe Platform
playerOnPlatforms player platforms =
    List.head (List.filter (playerOnPlatform player) platforms)


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
    if player.vY == 0 then
        case playerOnPlatforms player model.platforms of
            Just platform ->
                case platform.kind of
                    Normal ->
                        { model
                            | player =
                                { player | vY = player.vY + 5, y = player.y - platformHeight - 1 }
                        }

                    Boosted ->
                        { model
                            | player =
                                { player | vY = player.vY + 7, y = player.y - platformHeight - 1 }
                        }

            Nothing ->
                model

    else
        model
