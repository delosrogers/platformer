module Types exposing (..)


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
