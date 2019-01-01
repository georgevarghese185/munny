module Plugin.HDFC.Main (
    main
  ) where

import Prelude

import App.Plugin (pluginReady)
import App.Plugin.UI (wait)
import Control.Alt ((<|>))
import Control.Monad.Error.Class (throwError)
import Control.Monad.Except (runExcept)
import Data.Either (Either(..), hush)
import Data.Foldable (elem)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Effect.Exception (error)
import Foreign (F, Foreign)
import Foreign.Class (decode)
import Foreign.Index (index)
import Plugin.HDFC (pluginName)
import Plugin.HDFC.Settings (HdfcSettings)
import Plugin.HDFC.UI.Settings (SettingsScreenEvent(..), startSettingsScreen)
import Simple.JSON (read, write)

main :: Effect Unit
main = pluginReady pluginName start

start :: Foreign -> Aff Foreign
start inputs =
  accountFetch inputs <|> settingsRequest inputs

settingsDone :: SettingsScreenEvent -> Maybe HdfcSettings
settingsDone (SettingsDone customerId password) = Just {customerId, password}

settingsRequest :: Foreign -> Aff Foreign
settingsRequest inputs = do
  rootId <- case read inputs of
    Right inputs' -> pure inputs'
    Left e -> throwError $ error $ show e
  case elem "service-accounts-settings" <$> runExcept ((index inputs "outputs" >>= decode) :: F (Array String)) of
    Right true -> pure unit
    _ -> throwError $ error "Unknown request"
  let currentSettings = hush $ (runExcept $ index inputs "service-account-settings") >>= read
  ui <- liftEffect $ startSettingsScreen rootId currentSettings
  settings <- wait ui settingsDone
  pure $ write settings


accountFetch :: Foreign -> Aff Foreign
accountFetch inputs = pure inputs
