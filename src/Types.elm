module Types exposing (..)

import Http


type alias Model =
    { player : Player
    , platforms : Platforms
    , alive : Bool
    , score : Int
    , highScore : Int
    , name : Maybe String
    , message : Maybe String
    , userID : Maybe String
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


type alias ScoreApiRes =
    { id : String
    , name : String
    , highScore : Int
    }


type Msg
    = OnAnimationFrame Float
    | KeyDown PlayerAction
    | KeyUp PlayerAction
    | RestartGame
    | GenList ListOfFloat
    | ApiRespRecieved (Result Http.Error ScoreApiRes)
    | SavedHighScore (Result Http.Error ())
    | SaveScore
    | GetScoreAndName
    | IdInput String


type alias ListOfFloat =
    List Float


type PlayerAction
    = Jump
    | Left
    | Right
    | Other
