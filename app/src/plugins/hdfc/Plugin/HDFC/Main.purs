module Plugin.HDFC.Main (
    main
  ) where

import Prelude

import App.Plugin (pluginReady)
import App.Plugin.UI (wait)
import Control.Monad.Error.Class (throwError)
import Data.Either (Either(..))
import Data.Foldable (elem)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Exception (error)
import Foreign (Foreign)
import Plugin.HDFC (pluginName)
import Plugin.HDFC.Settings (HdfcSettings)
import Plugin.HDFC.UI.SettingsScreen (SettingsScreenEvent(..), startSettingsScreen)
import Simple.JSON (read, write)

type Params = {
  inputs :: {
    ui :: Maybe String,
    serviceAccountSettings :: Maybe HdfcSettings
  },
  outputs :: Array String
}

main :: Effect Unit
main = pluginReady pluginName start

start :: Foreign -> Aff Foreign
start inputs =
  settingsRequest inputs

settingsDone :: SettingsScreenEvent -> Maybe HdfcSettings
settingsDone (SettingsDone customerId password) = Just {customerId, password}

settingsRequest :: Foreign -> Aff Foreign
settingsRequest fgn = do
  (p :: Params) <- case read fgn of
    Right inputs' -> pure inputs'
    Left e -> throwError $ error $ show e
  if elem "serviceAccountSettings" p.outputs
    then pure unit
    else throwError $ error "Unknown request"
  divId <- case p.inputs.ui of
    Just id -> pure id
    Nothing -> throwError $ error "No UI provided for settings request"
  let currentSettings = p.inputs.serviceAccountSettings
  ui <- liftEffect $ startSettingsScreen divId currentSettings
  settings <- wait ui settingsDone
  pure $ write settings

syncRequest :: Foreign -> Aff Foreign
syncRequest fgn = do
  (p :: Params) <- case read fgn of
    Right inputs' -> pure inputs'
    Left e -> throwError $ error $ show e
  if elem "accounts" p.outputs
    then pure unit
    else throwError $ error "Unknown request"
  
  pure fgn
