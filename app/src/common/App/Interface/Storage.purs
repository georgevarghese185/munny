module App.Interface.Storage where

import Prelude

import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toMaybe)
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Uncurried (EffectFn1, EffectFn2, runEffectFn1, runEffectFn2)

foreign import storeImpl :: EffectFn2 String String Unit
foreign import getImpl :: EffectFn1 String (Nullable String)
foreign import clearImpl :: EffectFn1 String Unit

store :: forall m. MonadEffect m => String -> String -> m Unit
store key val = liftEffect $ runEffectFn2 storeImpl key val

get :: forall m. MonadEffect m => String -> m (Maybe String)
get key = liftEffect $ toMaybe <$> runEffectFn1 getImpl key

clear :: forall m. MonadEffect m => String -> m Unit
clear key = liftEffect $ runEffectFn1 clearImpl key
