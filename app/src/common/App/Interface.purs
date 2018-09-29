module App.Interface where

import Prelude

import Effect (Effect)

foreign import setupInterface :: Effect Unit
foreign import exit :: Effect Unit
