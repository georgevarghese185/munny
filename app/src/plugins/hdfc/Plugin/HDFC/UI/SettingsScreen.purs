module Plugin.HDFC.UI.SettingsScreen where

import Prelude

import App.Plugin.UI (Ui, newEvent, newUi, onStateUpdate, updateState)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe, maybe)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn2, runEffectFn1, runEffectFn2)
import Foreign (Foreign)
import Foreign.Class (class Decode, class Encode)
import Foreign.Generic (defaultOptions, genericDecode, genericEncode)
import Plugin.HDFC.Settings (HdfcSettings)
import Plugin.Home.UI.HomeScreen (decodeEvent)

foreign import startSettingsScreenImpl :: EffectFn2 String (EffectFn2 String (Array Foreign) Unit) (EffectFn1 SettingsScreenState Unit)

type SettingsScreenState = {
  customerId :: String
, password :: String
}

type SettingsScreenUi = Ui SettingsScreenState SettingsScreenEvent

derive instance genericSettingsScreenEvent :: Generic SettingsScreenEvent _
instance encodeSettingsScreenEvent :: Encode SettingsScreenEvent where encode = genericEncode defaultOptions
instance decodeSettingsScreenEvent :: Decode SettingsScreenEvent where decode = genericDecode defaultOptions

data SettingsScreenEvent =
  SettingsDone String String

startSettingsScreen :: String -> Maybe HdfcSettings -> Effect (SettingsScreenUi)
startSettingsScreen id currentSettings = do
  ui <- newUi
  let onEvent eventName args = decodeEvent eventName args >>= maybe (pure unit) (newEvent ui)
  updateStateFn <- runEffectFn2 startSettingsScreenImpl id (mkEffectFn2 onEvent)
  let stateUpdater state = do
        runEffectFn1 updateStateFn state
        pure true
  onStateUpdate ui stateUpdater
  updateState ui $ maybe {customerId: "", password: ""} identity currentSettings
  pure ui
