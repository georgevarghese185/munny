module App.Plugin.UI (
    UiInput(..)
  , class Event
  , event
  , Context
  , newUi
  , updateScreen
  , wait
  ) where

import Prelude

import Data.Either (either)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe, maybe)
import Data.Newtype (class Newtype)
import Effect (Effect)
import Effect.AVar (AVar, empty, put)
import Effect.Aff (Aff, message)
import Effect.Aff.AVar (take)
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Class.Console (error)
import Foreign.Class (class Decode, class Encode)
import Foreign.Generic (defaultOptions, genericDecode, genericEncode)



newtype UiInput = UiInput {
  rootId :: String
}

derive instance newtypeUiInput :: Newtype UiInput _
derive instance genericUiInput :: Generic UiInput _
instance encodeUiInput :: Encode UiInput where encode = genericEncode defaultOptions{unwrapSingleConstructors = true}
instance decodeUiInput :: Decode UiInput where decode = genericDecode defaultOptions{unwrapSingleConstructors = true}


class Event state event where
  event :: state -> Maybe event

newtype Context state = Context {
  render :: state -> Effect Unit
, state :: AVar state
}

newUi :: forall m state. MonadEffect m => (state -> Effect Unit) -> m ({context :: Context state, updateState :: state -> Effect Unit})
newUi renderFn = liftEffect do
  st <- empty
  let updateState newState = void $ put newState st (either (message >>> error) pure)
  pure $ {context: Context {render: renderFn, state: st}, updateState}

updateScreen :: forall m state. MonadEffect m => state -> Context state -> m Unit
updateScreen st (Context {render}) = liftEffect $ render st

wait :: forall state event. Event state event => Context state -> Aff event
wait context@(Context {state: st}) = do
  newState <- take st
  maybe (wait context) pure $ event newState
