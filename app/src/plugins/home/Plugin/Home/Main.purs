module Plugin.Home.Main (
    main
  ) where

import Prelude

import App ((<|>))
import App.Interface (exit)
import App.Interface.Events (Event(..), on)
import App.Plugin (Plugin(..), getPluginsByType, pluginReady)
import App.Plugin.UI (wait)
import Control.Monad.Except (ExceptT(..), lift, runExcept, runExceptT, throwError)
import Data.Either (Either(..), either)
import Data.Newtype (unwrap)
import Effect (Effect)
import Effect.Aff (Aff, error)
import Effect.Class (liftEffect)
import Foreign (Foreign, readString)
import Foreign.Index (index)
import Plugin.Home (pluginName)
import Plugin.Home.UI.AddAccount (addAccountClicked, addAccount)
import Plugin.Home.UI.HomeScreen (HomeScreenUi, startHomeScreen)

main :: Effect Unit
main = pluginReady pluginName start

getServices :: Aff (Array Plugin)
getServices = do
  either throwError pure =<< (runExceptT $ getPluginsByType "account-service")

start :: Foreign -> Aff Foreign
start input = do
  rootId <- case runExcept $ index input "ui" >>= readString of
    Left _ -> throwError $ error "No ui input given"
    Right id -> pure id
  ui <- liftEffect $ startHomeScreen rootId
  homeScreen ui
  pure input

homeScreen :: HomeScreenUi -> Aff Unit
homeScreen ui = do
  on BackPressed (liftEffect exit) <|> wait ui addAccountClicked
  services <- getServices
  addAccount ui (unwrap >>> _.name <$> services)
  homeScreen ui
