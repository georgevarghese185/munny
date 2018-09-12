module Startup.LifeCycle where

import Prelude

import Effect (Effect)

foreign import setupLifeCycleCallbacks :: Effect Unit
