module App.Plugin.UI (
    Ui
  , newUi
  , updateState
  , getState
  , modifyState
  , newEvent
  , getLastEvent
  , onStateUpdate
  , onEvent
  , wait
  ) where

import Prelude

import Data.Either (Either(..))
import Data.Maybe (Maybe, maybe)
import Effect (Effect)
import Effect.AVar (AVar, empty)
import Effect.Aff (Aff, launchAff_, makeAff, nonCanceler)
import Effect.Aff.AVar as A
import Effect.Aff.Bus (BusRW, make, read, write)
import Effect.Class (class MonadEffect, liftEffect)


data Ui state event = Ui (AVar state) (AVar event) (BusRW state) (BusRW event)

replaceAVar :: forall a. AVar a -> a -> Aff Unit
replaceAVar ref a = do
  _ <- A.tryTake ref
  A.put a ref

newUi :: forall m state event. MonadEffect m => m (Ui state event)
newUi = liftEffect do
  st <- empty
  ev <- empty
  stBus <- make
  evBus <- make
  pure $ Ui st ev stBus evBus

addHandler :: forall a m. MonadEffect m => BusRW a -> (a -> Effect Boolean) -> m Unit
addHandler bus fn = liftEffect $ launchAff_ do
  a <- read bus
  keep <- liftEffect $ fn a
  if keep then addHandler bus fn else pure unit

update :: forall a m. MonadEffect m => BusRW a -> AVar a -> a -> m Unit
update bus ref a = liftEffect $ launchAff_ do
  replaceAVar ref a
  write a bus

updateState :: forall m state event. MonadEffect m => Ui state event -> state -> m Unit
updateState (Ui st _ stBus _) newState = update stBus st newState

getState :: forall state event. Ui state event -> Aff state
getState (Ui st _ _ _) = A.read st

modifyState :: forall state event. Ui state event -> (state -> state) -> Aff Unit
modifyState ui fn = do
  state <- getState ui
  updateState ui $ fn state

newEvent :: forall m state event. MonadEffect m => Ui state event -> event -> m Unit
newEvent (Ui _ ev _ evBus) event = update evBus ev event

getLastEvent :: forall state event. Ui state event -> Aff event
getLastEvent (Ui _ ev _ _) = A.read ev

onStateUpdate :: forall m state event. MonadEffect m => Ui state event -> (state -> Effect Boolean) -> m Unit
onStateUpdate ui@(Ui _ _ stBus _) fn = addHandler stBus fn

onEvent :: forall m state event. MonadEffect m => Ui state event -> (event -> Effect Boolean) -> m Unit
onEvent ui@(Ui _ _ _ evBus) fn = addHandler evBus fn


wait :: forall a state event. Ui state event -> (event -> Maybe a) -> Aff a
wait ui fn = do
  event <- makeAff \cb -> onEvent ui (\event -> cb (Right event) *> pure false) *> pure nonCanceler
  maybe (wait ui fn) pure $ fn event
