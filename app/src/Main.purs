module Main where

import Prelude

import Effect (Effect)
import Effect.Class.Console (log)
import Interface (_setupInterface)
import Interface.Events (setupEvents)

main :: Effect Unit
main = do
  log "Setting up Interface" *> _setupInterface
  log "Setting up Event listeners" *> setupEvents
  log "Startup complete"
