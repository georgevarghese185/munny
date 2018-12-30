module Plugin.Home.Main (
    main
  ) where

import Prelude

import App.Plugin (pluginReady)
import App.Plugin.UI (updateState, wait)
import Control.Monad.Except (ExceptT, runExcept, runExceptT, throwError)
import Data.Either (Either(..), either)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff, Error, error)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Foreign (Foreign, readString, unsafeToForeign)
import Foreign.Generic (encodeJSON)
import Foreign.Index (index)
import Plugin.Home (pluginName)
import Plugin.Home.UI.HomeScreen (startHomeScreen, testState)

main :: Effect Unit
main = pluginReady pluginName $ \input -> do
  either (show >>> unsafeToForeign) identity <$> runExceptT (start input)

start :: Foreign -> ExceptT Error Aff Foreign
start input = do
  rootId <- case runExcept $ index input "ui" >>= readString of
    Left _ -> throwError $ error "No ui input given"
    Right id -> pure id
  ui <- liftEffect $ startHomeScreen rootId
  event <- liftAff $ wait ui Just
  updateState ui testState
  log $ encodeJSON event
  pure input
