module Plugin.Home.UI.HomeScreen where

import Prelude

import App (appName)
import App.Plugin.UI (Ui, newEvent, newUi, onStateUpdate, updateState)
import Control.Monad.Except (runExcept)
import Data.Either (Either(..))
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..), maybe)
import Effect (Effect)
import Effect.Class.Console (errorShow)
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn2, runEffectFn1, runEffectFn2)
import Foreign (F, Foreign, unsafeToForeign)
import Foreign.Class (class Decode, class Encode, decode)
import Foreign.Generic (defaultOptions, genericDecode, genericEncode)
import Plugin.Home (pluginDir)
import Simple.JSON (write)

foreign import startHomeScreenImpl :: EffectFn2 String (EffectFn2 String (Array Foreign) Unit) (EffectFn1 Foreign Unit)

type AccountSummary = {
  leftColumn :: Maybe {
    label :: String
  , value :: String
  }
, rightColumn :: Maybe {
    label :: String
  , value :: String
  }
}

type Account = {
  name :: String
, logo :: String
, lastUpdated :: String
, summaryRows :: Array AccountSummary
}

type HomeScreenState = {
  app :: {
    name :: String
  , pluginDir :: String
  }
, accounts :: Array Account
, services :: Array String
, encryptOptions :: Array String
, viewers :: Array String
}

type HomeScreenUi = Ui HomeScreenState HomeScreenEvent

derive instance genericHomeScreenEvent :: Generic HomeScreenEvent _
instance encodeHomeScreenEvent :: Encode HomeScreenEvent where encode = genericEncode defaultOptions{unwrapSingleConstructors=true}
instance decodeHomeScreenEvent :: Decode HomeScreenEvent where decode = genericDecode defaultOptions{unwrapSingleConstructors=true}

data HomeScreenEvent =
    AddAccountClick
  | SyncClick
  | ViewDetailsClick

screenName :: String
screenName = "HomeScreen"

initialState :: HomeScreenState
initialState = {
  app: {
    name: appName
  , pluginDir: pluginDir
  }
, accounts: []
, services: []
, encryptOptions: []
, viewers: []
}

testState :: HomeScreenState
testState = {
  app: {
    name: appName
  , pluginDir: pluginDir
  }
, accounts: [
    {
      name: "ICICI"
    , logo: "bank_logos/icici.png"
    , lastUpdated: "4 centuries ago"
    , summaryRows: []
    }
  ]
, services: []
, encryptOptions: []
, viewers: []
}


decodeEvent :: String -> Array Foreign -> Effect (Maybe HomeScreenEvent)
decodeEvent eventName args = case runExcept $ decode' eventName args of
  Right event -> pure $ Just event
  Left e -> errorShow e *> pure Nothing
  where
    decode' :: String -> Array Foreign -> F HomeScreenEvent
    decode' e [a] = decode $ unsafeToForeign {tag: e, contents: a}
    decode' e as = decode $ unsafeToForeign {tag: e, contents: as}

startHomeScreen :: String -> Effect HomeScreenUi
startHomeScreen rootId = do
  ui <- newUi
  let onEvent eventName args = decodeEvent eventName args >>= maybe (pure unit) (newEvent ui)
  updateStateFn <- runEffectFn2 startHomeScreenImpl rootId (mkEffectFn2 onEvent)
  let stateUpdater state = do
        runEffectFn1 updateStateFn (write state)
        onStateUpdate ui stateUpdater
        pure true
  onStateUpdate ui stateUpdater
  updateState ui initialState
  pure ui
