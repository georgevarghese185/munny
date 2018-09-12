module Main where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Startup.Interface (setupInterface)
import Startup.LifeCycle (setupLifeCycleCallbacks)

main :: Effect Unit
main = do
  log "Setting up Interface"
  setupInterface
  log "Setting LifeCycle listener"
  setupLifeCycleCallbacks
  log "Startup complete"
