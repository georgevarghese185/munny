module Plugin.Home.Main (
    main
  ) where

import Prelude

import App.Plugin (Plugin, getPluginsByType, pluginReady)
import App.Plugin.UI (wait)
import Control.Monad.Except (runExceptT, throwError)
import Data.Either (Either(..), either)
import Data.Newtype (unwrap)
import Effect (Effect)
import Effect.Aff (Aff, error)
import Effect.Class (liftEffect)
import Foreign (Foreign)
import Foreign.Class (encode)
import Plugin.Home (pluginName)
import Plugin.Home.AddAccount (addAccount)
import Plugin.Home.UI.HomeScreen (HomeScreenUi, startHomeScreen)
import Plugin.Home.UI.HomeScreen as Events
import Simple.JSON (read)

type Params = {
  inputs :: {
    ui :: String
  }
}

main :: Effect Unit
main = pluginReady pluginName start

getServices :: Aff (Array Plugin)
getServices = do
  either throwError pure =<< (runExceptT $ getPluginsByType "account-service")

start :: Foreign -> Aff Foreign
start params = do
  (p :: Params) <- case read params of
    Left _ -> throwError $ error "No ui input given"
    Right id -> pure id
  ui <- liftEffect $ startHomeScreen p.inputs.ui
  homeScreen ui
  pure $ encode unit

homeScreen :: HomeScreenUi -> Aff Unit
homeScreen ui = do
  -- on BackPressed (liftEffect exit) <|> wait ui Events.addAccountClicked
  wait ui Events.addAccountClicked
  services <- getServices
  addAccount ui (unwrap >>> _.name <$> services)
  homeScreen ui
