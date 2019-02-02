module App.Interface.Storage (
    store
  , get
  , getWith
  , clear
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe(..), maybe)
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

getWith :: forall e a m. MonadEffect m => (String -> Either e a) -> String -> m (Either e (Maybe a))
getWith f key = liftEffect $ do
  ma <- get key
  pure $ maybe (Right Nothing) (f >=> (Just >>> Right)) ma

clear :: forall m. MonadEffect m => String -> m Unit
clear key = liftEffect $ runEffectFn1 clearImpl key
