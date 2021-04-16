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
    , xsrf : String
    , leaderboard : Maybe (List LeaderboardItem)
    , backgrounds : List Background
    }


type alias LeaderboardItem =
    { name : String
    , score : Int
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
    , kind : PlatformType
    }


type alias Background =
    { x : Float
    , y : Float
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
    | GenBack ListOfFloat
    | SaveScore
    | GetScoreAndName
    | IdInput String
    | ScoreNameApiResp (Result Http.Error ScoreApiRes)
    | LeaderboardApiResp (Result Http.Error (List LeaderboardItem))
    | SavedHighScoreApiResp (Result Http.Error ())


type alias Flags =
    { id : String
    , xsrf : String
    }


type alias ListOfFloat =
    List Float


type PlayerAction
    = Jump
    | Left
    | Right
    | Other


type PlatformType
    = Normal
    | Boosted
