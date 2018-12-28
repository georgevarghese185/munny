module App.Plugin.UI (
    Ui
  , newUi
  , updateState
  , onStateUpdate
  , newEvent
  , wait
  ) where

import Prelude

import Data.Either (either)
import Data.Maybe (Maybe, maybe)
import Effect (Effect)
import Effect.AVar (AVar, AVarCallback, empty, put, take, tryTake)
import Effect.Aff (Aff)
import Effect.Aff.AVar as A
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Class.Console (errorShow)

data Ui state event = Ui (AVar state) (AVar event)

replace :: forall a. a -> AVar a -> AVarCallback Unit -> Effect Unit
replace a aVar callback = do
  void $ tryTake aVar
  void $ put a aVar callback


newUi :: forall m state event. MonadEffect m => m (Ui state event)
newUi = liftEffect do
  st <- empty
  ev <- empty
  pure $ Ui st ev

updateState :: forall m state event. MonadEffect m => Ui state event -> state -> m Unit
updateState (Ui st _) newState = liftEffect $ replace newState st $ either errorShow pure

onStateUpdate :: forall m state event. MonadEffect m => Ui state event -> (state -> Effect Unit) -> m Unit
onStateUpdate (Ui st _) fn = liftEffect $ void $ take st $ either errorShow fn

newEvent :: forall m state event. MonadEffect m => Ui state event -> event -> m Unit
newEvent (Ui _ ev) event = liftEffect $ replace event ev $ either errorShow pure

wait :: forall a state event. Ui state event -> (event -> Maybe a) -> Aff a
wait ui@(Ui _ ev) fn = do
  event <- A.take ev
  maybe (wait ui fn) pure $ fn event
