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

import Data.Either (Either(..), either)
import Data.Foldable (traverse_)
import Data.List (List, snoc)
import Data.Maybe (Maybe, maybe)
import Effect (Effect)
import Effect.AVar (AVar, AVarCallback, empty, new, put, tryTake)
import Effect.Aff (Aff, makeAff, nonCanceler, runAff_)
import Effect.Aff.AVar as A
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Class.Console (errorShow)

type Handlers a = List (a -> Effect Unit)

data Ui state event = Ui (AVar state) (AVar event) (AVar (Handlers state)) (AVar (Handlers event))

replace :: forall a. a -> AVar a -> AVarCallback Unit -> Effect Unit
replace a ref callback = do
  _ <- tryTake ref
  void $ put a ref callback

replaceAff :: forall a. a -> AVar a -> Aff Unit
replaceAff a ref = do
  _ <- A.tryTake ref
  A.put a ref

updateAndNotify :: forall a m. MonadEffect m => a -> AVar a -> AVar (Handlers a) -> m Unit
updateAndNotify a ref handlersRef = liftEffect $ runAff_ (either errorShow pure) do
  replaceAff a ref
  handlers <- A.take handlersRef
  A.put mempty handlersRef
  traverse_ (\fn -> liftEffect $ fn a) handlers

newUi :: forall m state event. MonadEffect m => m (Ui state event)
newUi = liftEffect do
  st <- empty
  ev <- empty
  stateHandlers <- new mempty
  eventHandlers <- new mempty
  pure $ Ui st ev stateHandlers eventHandlers

updateState :: forall m state event. MonadEffect m => Ui state event -> state -> m Unit
updateState (Ui st _ stHandlers _) newState = updateAndNotify newState st stHandlers

getState :: forall state event. Ui state event -> Aff state
getState (Ui st _ _ _) = A.read st

modifyState :: forall state event. Ui state event -> (state -> state) -> Aff Unit
modifyState ui fn = do
  state <- getState ui
  updateState ui $ fn state

newEvent :: forall m state event. MonadEffect m => Ui state event -> event -> m Unit
newEvent (Ui _ ev _ evHandlers) event = updateAndNotify event ev evHandlers

getLastEvent :: forall state event. Ui state event -> Aff event
getLastEvent (Ui _ ev _ _) = A.read ev

addHandler :: forall a m. MonadEffect m => AVar (Handlers a) -> (a -> Effect Boolean) -> m Unit
addHandler handlersRef fn = liftEffect $ runAff_ (either (errorShow) pure) do
  handlers <- A.read handlersRef
  replaceAff (snoc handlers $ \a -> do
      keep <- fn a
      if keep then addHandler handlersRef fn else pure unit
    ) handlersRef

onStateUpdate :: forall m state event. MonadEffect m => Ui state event -> (state -> Effect Boolean) -> m Unit
onStateUpdate ui@(Ui _ _ stHandlers _) fn = addHandler stHandlers fn

onEvent :: forall m state event. MonadEffect m => Ui state event -> (event -> Effect Boolean) -> m Unit
onEvent ui@(Ui _ _ _ evHandlers) fn = addHandler evHandlers fn


wait :: forall a state event. Ui state event -> (event -> Maybe a) -> Aff a
wait ui fn = do
  event <- makeAff \cb -> onEvent ui (\event -> cb (Right event) *> pure false) *> pure nonCanceler
  maybe (wait ui fn) pure $ fn event
