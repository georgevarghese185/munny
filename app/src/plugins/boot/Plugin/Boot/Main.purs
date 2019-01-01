module Plugin.Boot.Main (
    main
  ) where

import Prelude

import App.Interface (setupInterface)
import App.Interface.Events (setupEvents)
import App.Plugin (loadPlugin)
import App.Plugin as Plugin
import App.Plugin.Meta (Plugin(..), getPluginsByType)
import Control.Monad.Except (ExceptT, runExceptT, throwError)
import Data.Array (elem, head)
import Data.Either (Either(..), either)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff, Error, error, runAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Class.Console as Console
import Effect.Exception (throwException)
import Foreign (Foreign, unsafeToForeign)
import Foreign.Class (encode)

main :: Effect Unit
main = do
  setupInterface
  setupEvents
  Plugin.initialize
  log "Boot complete"
  runAff_ handler $ runExceptT start >>= either (throwException >>> liftEffect) pure
  where
    handler :: Either Error Unit -> Effect Unit
    handler result = case result of
      Right _ -> pure unit
      Left err -> Console.error ("App error: " <> show err)

start :: ExceptT Error Aff Unit
start = do
  plugins <- getPluginsByType "main"
  (Plugin p) <- case head plugins of
    Nothing -> throwError $ error "No main plugin found"
    Just p -> pure p
  let input = if elem "ui" p.inputs
        then unsafeToForeign {ui: "#root"}
        else encode (Nothing :: Maybe Foreign)
  void $ loadPlugin p.name input
  pure unit
