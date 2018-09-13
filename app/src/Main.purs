module Main where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Interface (setupInterface)
import Interface.Events (setupEvents)

main :: Effect Unit
main = do
  log "Setting up Interface"
  setupInterface
  log "Setting LifeCycle listener"
  setupEvents
  log "Startup complete"
