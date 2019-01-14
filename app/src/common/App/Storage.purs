module App.Storage (
    store
  , get
  , clear
  ) where

import Prelude

import Data.Maybe (Maybe(..))
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn3, runEffectFn1, runEffectFn2, runEffectFn3)
import Foreign (Foreign)

foreign import storeImpl :: EffectFn2 String Foreign Unit
foreign import getImpl :: EffectFn3 (Foreign -> Maybe Foreign) (Maybe Foreign) String (Maybe Foreign)
foreign import clearImpl :: EffectFn1 String Unit

store :: forall m. MonadEffect m => String -> Foreign -> m Unit
store key val = liftEffect $ runEffectFn2 storeImpl key val

get :: forall m. MonadEffect m => String -> m (Maybe Foreign)
get key = liftEffect $ runEffectFn3 getImpl Just Nothing key

clear :: forall m. MonadEffect m => String -> m Unit
clear key = liftEffect $ runEffectFn1 clearImpl key
