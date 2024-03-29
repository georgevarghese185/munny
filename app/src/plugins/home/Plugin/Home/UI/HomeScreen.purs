module Plugin.Home.UI.HomeScreen where

import Prelude

import App (appName)
import App.Plugin.UI (Ui, modifyState, newEvent, newUi, onStateUpdate, updateState)
import Control.Monad.Except (runExcept)
import Data.DateTime (DateTime, diff)
import Data.Either (Either(..))
import Data.Generic.Rep (class Generic)
import Data.Int (floor)
import Data.Maybe (Maybe(..), fromMaybe, maybe)
import Data.Newtype (unwrap)
import Data.Symbol (SProxy(..))
import Data.Time.Duration (Days(..), Hours(..), Minutes(..), Seconds(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Class.Console (errorShow)
import Effect.Now (nowDateTime)
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn2, runEffectFn1, runEffectFn2)
import Foreign (F, Foreign, unsafeToForeign)
import Foreign.Class (class Decode, class Encode, decode)
import Foreign.Generic (defaultOptions, encodeJSON, genericDecode, genericEncode)
import Plugin.Home (pluginDir)
import Plugin.Home.Account (AccountSummary, getAccounts)
import Record (modify, set)
import Simple.JSON (write)

foreign import startHomeScreenImpl :: EffectFn2 String (EffectFn2 String (Array Foreign) Unit) (EffectFn1 Foreign Unit)

type Account = {
  name :: String
, logo :: String
, lastUpdated :: String
, summary :: Array AccountSummary
}

type SyncingAccount = {
  name :: String
, logo :: String
, sync :: {
    status :: String
  , message :: String
  }
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
  , textInputDialog :: {
      visible :: Boolean
    , title :: String
    , inputType :: String
    }
  , simpleDialog :: {
      visible :: Boolean
    , message :: String
    }
  , syncDialog :: {
      visible :: Boolean
    , accounts :: Array SyncingAccount
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
_textInputDialog = SProxy :: SProxy "textInputDialog"
_syncDialog = SProxy :: SProxy "syncDialog"
_options = SProxy :: SProxy "options"
_isNumberPin = SProxy :: SProxy "isNumberPin"
_simpleDialog = SProxy :: SProxy "simpleDialog"
_message = SProxy :: SProxy "message"
_name = SProxy :: SProxy "name"
_logo = SProxy :: SProxy "logo"
_sync = SProxy :: SProxy "sync"
_status = SProxy :: SProxy "status"

refreshAccounts :: HomeScreenUi -> Aff Unit
refreshAccounts ui = do
  accounts <- getAccounts
  now <- liftEffect nowDateTime
  let uiAccounts = map (\a -> {
        name: a.name,
        logo: a.serviceName <> "/assets/logo.png",
        lastUpdated: fromMaybe "Never" $ renderLastUpdated now <$> a.lastUpdated,
        summary: a.summary
      }) accounts
  modifyState ui $ set _accounts uiAccounts

hideSelectorDialog :: HomeScreenUi -> Aff Unit
hideSelectorDialog ui =
  modifyState ui $ modify _dialogs (modify _selectorDialog (set _visible false))

showSelectorDialog :: HomeScreenUi -> String -> String -> Array String -> Aff Unit
showSelectorDialog ui title label options =
  modifyState ui $ modify _dialogs (set _selectorDialog {
    visible: true
  , title
  , label
  , options
  })

hideInputsDialog :: HomeScreenUi -> Aff Unit
hideInputsDialog ui =
  modifyState ui $ modify _dialogs (modify _inputsDialog (set _visible false))

showInputsDialog :: HomeScreenUi -> String -> Aff Unit
showInputsDialog ui serviceName =
  modifyState ui $ modify _dialogs (set _inputsDialog {
    visible: true
  , serviceName
  })

hideEncryptDialog :: HomeScreenUi -> Aff Unit
hideEncryptDialog ui =
  modifyState ui $ modify _dialogs (modify _encryptDialog (set _visible false))

showEncryptDialog :: HomeScreenUi -> Array String -> Aff Unit
showEncryptDialog ui options =
  modifyState ui $ modify _dialogs (set _encryptDialog {
    visible: true
  , options
  })

hideTextInputDialog :: HomeScreenUi -> Aff Unit
hideTextInputDialog ui =
  modifyState ui $ modify _dialogs (modify _textInputDialog (set _visible false))

showTextInputDialog :: HomeScreenUi -> String -> String -> Aff Unit
showTextInputDialog ui title inputType =
  modifyState ui $ modify _dialogs (set _textInputDialog {
    visible: true
  , title
  , inputType
  })

hideSimpleDialog :: HomeScreenUi -> Aff Unit
hideSimpleDialog ui =
  modifyState ui $ modify _dialogs (modify _simpleDialog (set _visible false))

showSimpleDialog :: HomeScreenUi -> String -> Aff Unit
showSimpleDialog ui message =
  modifyState ui $ modify _dialogs (set _simpleDialog {
    visible: true
  , message
  })

hideSyncDialog :: HomeScreenUi -> Aff Unit
hideSyncDialog ui =
  modifyState ui $ modify _dialogs (modify _syncDialog (set _visible false))

showSyncDialog :: HomeScreenUi -> Array SyncingAccount -> Aff Unit
showSyncDialog ui accounts =
  modifyState ui $ modify _dialogs (set _syncDialog {
    visible: true
  , accounts
  })

type HomeScreenUi = Ui HomeScreenState HomeScreenEvent

derive instance eqHomeScreen :: Eq HomeScreenEvent
derive instance genericHomeScreenEvent :: Generic HomeScreenEvent _
instance encodeHomeScreenEvent :: Encode HomeScreenEvent where encode = genericEncode defaultOptions{unwrapSingleConstructors=true}
instance decodeHomeScreenEvent :: Decode HomeScreenEvent where decode = genericDecode defaultOptions{unwrapSingleConstructors=true}


data HomeScreenEvent =
    AddAccountClick
  | SyncClick
  | OkClick
  | TextEnter String
  | ViewDetailsClick
  | SelectorDialog String
  | InputsDialogRendered String
  | EncryptOption String

addAccountClicked :: HomeScreenEvent -> Maybe Unit
addAccountClicked AddAccountClick = Just unit
addAccountClicked _ = Nothing

serviceSelected :: HomeScreenEvent -> Maybe String
serviceSelected (SelectorDialog service) = Just service
serviceSelected _ = Nothing

inputsDialogRendered :: HomeScreenEvent -> Maybe String
inputsDialogRendered (InputsDialogRendered id) = Just id
inputsDialogRendered _ = Nothing

okClicked :: HomeScreenEvent -> Maybe Unit
okClicked OkClick = Just unit
okClicked _ = Nothing

textEntered :: HomeScreenEvent -> Maybe String
textEntered (TextEnter password) = Just password
textEntered _ = Nothing

encryptOptionSelected :: HomeScreenEvent -> Maybe String
encryptOptionSelected (EncryptOption choice) = Just choice
encryptOptionSelected _ = Nothing


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
  , textInputDialog: {
      visible: false
    , title: ""
    , inputType: "text"
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

renderLastUpdated :: DateTime -> DateTime -> String
renderLastUpdated now date
  | diff now date >= (Days 1.0) = encodeJSON $ floor $ unwrap $ (diff now date :: Days)
  | diff now date >= (Hours 1.0) = encodeJSON $ floor $ unwrap $ (diff now date :: Hours)
  | diff now date >= (Minutes 1.0) = encodeJSON $ floor $ unwrap $ (diff now date :: Minutes)
  | diff now date >= (Seconds 1.0) = encodeJSON $ floor $ unwrap $ (diff now date :: Seconds)
  | otherwise = "Just now"

startHomeScreen :: String -> Effect HomeScreenUi
startHomeScreen rootId = do
  ui <- newUi
  let onEvent eventName args = decodeEvent eventName args >>= maybe (pure unit) (newEvent ui)
  updateStateFn <- runEffectFn2 startHomeScreenImpl rootId (mkEffectFn2 onEvent)
  let stateUpdater state = do
        runEffectFn1 updateStateFn (write state)
        pure true
  onStateUpdate ui stateUpdater
  updateState ui initialState
  pure ui
