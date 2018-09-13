module Main where

import Prelude

import Data.Either (Either(..))
import Effect (Effect)
import Effect.Aff (Aff, Error, runAff_)
import Effect.Class.Console (log, logShow)
import Interface (exit, setupInterface)
import Interface.Events (setupEvents)
import WebScripter (Script(..), ScriptStep(..), ScripterId(..), createScripter, executeScripter)

main :: Effect Unit
main = do
  log "Setting up Interface" *> setupInterface
  log "Setting up Event listeners" *> setupEvents
  log "Startup complete"
  runAff_ handler app
  where
    handler :: Either Error Unit -> Effect Unit
    handler _ = exit

app :: Aff Unit
app = do
  let
    id = ScripterId "test"
    script = Script [
      URL "https://techradar.com",
      JS $    "var articleNames = Array.from(document.getElementsByClassName(\"article-name\")).map(h => h.innerHTML);"
					<>  "Interface.onCommandDone(JSON.stringify(articleNames));"
    ]
  log "Creating scripter"
  createScripter id
  log "executing"
  result <- executeScripter id script
  log "back from scripter"
  case result of
    Right results -> logShow results
    Left e -> logShow e
