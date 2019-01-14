module Plugin.Home.UI.HomeScreen where

import Prelude

import App (appName)
import App.Plugin.UI (Ui, newEvent, newUi, onStateUpdate, updateState)
import Control.Monad.Except (runExcept)
import Data.Either (Either(..))
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..), maybe)
import Data.Symbol (SProxy(..))
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
, encryptOptions :: Array String
, viewers :: Array String
, dialogs :: {
    selectorDialog :: {
      visible :: Boolean
    , title :: String
    , label :: String
    , options :: Array String
    }
  , inputsDialog :: {
      visible :: Boolean
    , serviceName :: String
    }
  , encryptDialog :: {
      visible :: Boolean
    , options :: Array String
    }
  , passwordDialog :: {
      visible :: Boolean
    , title :: String
    , isNumberPin :: Boolean
    }
  , simpleDialog :: {
      visible :: Boolean
    , message :: String
    }
  , syncDialog :: {
      visible :: Boolean
    , accounts :: Array {
        name :: String
      , logo :: String
      , sync :: {
          status :: String
        , message :: String
        }
      }
    }
  }
}

_accounts = SProxy :: SProxy "accounts"
_lastUpdated = SProxy :: SProxy "lastUpdated"
_summaryRows = SProxy :: SProxy "summaryRows"
_value = SProxy :: SProxy "value"
_services = SProxy :: SProxy "services"
_encryptOptions = SProxy :: SProxy "encryptOptions"
_viewers = SProxy :: SProxy "viewers"
_dialogs = SProxy :: SProxy "dialogs"
_selectorDialog = SProxy :: SProxy "selectorDialog"
_visible = SProxy :: SProxy "visible"
_title = SProxy :: SProxy "title"
_label = SProxy :: SProxy "label"
_inputsDialog = SProxy :: SProxy "inputsDialog"
_serviceName = SProxy :: SProxy "serviceName"
_encryptDialog = SProxy :: SProxy "encryptDialog"
_passwordDialog = SProxy :: SProxy "passwordDialog"
_options = SProxy :: SProxy "options"
_isNumberPin = SProxy :: SProxy "isNumberPin"
_simpleDialog = SProxy :: SProxy "simpleDialog"
_message = SProxy :: SProxy "message"
_name = SProxy :: SProxy "name"
_logo = SProxy :: SProxy "logo"
_sync = SProxy :: SProxy "sync"
_status = SProxy :: SProxy "status"

type HomeScreenUi = Ui HomeScreenState HomeScreenEvent

derive instance eqHomeScreen :: Eq HomeScreenEvent
derive instance genericHomeScreenEvent :: Generic HomeScreenEvent _
instance encodeHomeScreenEvent :: Encode HomeScreenEvent where encode = genericEncode defaultOptions{unwrapSingleConstructors=true}
instance decodeHomeScreenEvent :: Decode HomeScreenEvent where decode = genericDecode defaultOptions{unwrapSingleConstructors=true}

data HomeScreenEvent =
    AddAccountClick
  | SyncClick
  | ViewDetailsClick
  | SelectorDialog String
  | InputsDialogRendered String

screenName :: String
screenName = "HomeScreen"

initialState :: HomeScreenState
initialState = {
  app: {
    name: appName
  , pluginDir: pluginDir
  }
, accounts: []
, encryptOptions: []
, viewers: []
, dialogs: {
    selectorDialog: {
      visible: false
    , title: ""
    , label: ""
    , options: []
    }
  , inputsDialog: {
      visible: false
    , serviceName: ""
    }
  , encryptDialog: {
      visible: false
    , options: []
    }
  , passwordDialog: {
      visible: false
    , title: ""
    , isNumberPin: false
    }
  , simpleDialog: {
      visible: false
    , message: ""
    }
  , syncDialog: {
      visible: false
    , accounts: []
    }
  }
}


decodeEvent :: forall a. Decode a => String -> Array Foreign -> Effect (Maybe a)
decodeEvent eventName args = case runExcept $ decode' eventName args of
  Right event -> pure $ Just event
  Left e -> errorShow e *> pure Nothing
  where
    decode' :: String -> Array Foreign -> F a
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
