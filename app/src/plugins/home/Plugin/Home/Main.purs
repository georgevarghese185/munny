module Plugin.Home.Main (
    main
  ) where

import Prelude

import App.Interface.Events (Event(..), waitFor)
import App.Plugin (pluginReady)
import Control.Monad.Except (ExceptT, runExcept, runExceptT, throwError)
import Data.Either (Either(..), either)
import Effect (Effect)
import Effect.Aff (Aff, Error, error)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Foreign (Foreign, readString, unsafeToForeign)
import Foreign.Index (index)
import Plugin.Home (pluginName)
import Plugin.Home.UI.HomeScreen (startHomeScreen)

main :: Effect Unit
main = pluginReady pluginName $ \input -> do
  either (show >>> unsafeToForeign) identity <$> runExceptT (start input)

start :: Foreign -> ExceptT Error Aff Foreign
start input = do
  rootId <- case runExcept $ index input "ui" >>= readString of
    Left _ -> throwError $ error "No ui input given"
    Right id -> pure id
  ui <- liftEffect $ startHomeScreen rootId
  liftAff $ waitFor BackPressed
  pure input
