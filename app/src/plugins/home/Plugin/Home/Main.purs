module Plugin.Home.Main (
    main
  ) where

import Prelude

import App.Plugin (pluginReady)
import App.Plugin.UI (updateScreen, wait)
import Control.Monad.Except (ExceptT, runExcept, runExceptT, throwError)
import Data.Either (Either(..), either)
import Effect (Effect)
import Effect.Aff (Aff, Error, error)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Foreign (Foreign, unsafeToForeign)
import Foreign.Index (index)
import Plugin.Home.UI (HomeEvent, HomeState(..), startHomeUi)

pluginName :: String
pluginName = "home"

main :: Effect Unit
main = pluginReady pluginName $ \input -> do
  either (show >>> unsafeToForeign) identity <$> runExceptT (start input)

start :: Foreign -> ExceptT Error Aff Foreign
start input = do
  rootId <- case runExcept $ index input "ui" of
    Left _ -> throwError $ error "No ui input given"
    Right id -> pure id
  context <- liftEffect $ startHomeUi
  liftEffect $ updateScreen (HomeState {message: "YO", continueClicked: false}) context
  liftEffect $ updateScreen (HomeState {message: "YAAASS", continueClicked: false}) context
  (event :: HomeEvent) <- liftAff $ wait context
  log "Continue clicked"
  pure input
