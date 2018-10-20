module Plugin.Home.UI where


import Prelude

import App.Plugin.UI (class Event, Context, newUi)
import Control.Monad.Except (runExcept)
import Data.Either (Either(..))
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Effect (Effect)
import Effect.Class.Console (error)
import Effect.Uncurried (EffectFn1, mkEffectFn1, runEffectFn1)
import Foreign (Foreign)
import Foreign.Class (class Decode, class Encode, decode, encode)
import Foreign.Generic (defaultOptions, genericDecode, genericEncode)


foreign import startUi :: Effect (EffectFn1 Foreign Unit)
foreign import setStateListener :: EffectFn1 (EffectFn1 Foreign Unit) Unit


newtype HomeState = HomeState {
  message :: String
, continueClicked :: Boolean
}

derive instance newtypeHomeState :: Newtype HomeState _
derive instance genericHomeState :: Generic HomeState _
instance encodeHomeState :: Encode HomeState where encode = genericEncode defaultOptions{unwrapSingleConstructors = true}
instance decodeHomeState :: Decode HomeState where decode = genericDecode defaultOptions{unwrapSingleConstructors = true}


data HomeEvent = Continue

instance homeEvent :: Event HomeState HomeEvent where
  event (HomeState {continueClicked: true}) = Just Continue
  event _ = Nothing

initialState :: HomeState
initialState = HomeState {
  message: "Hi",
  continueClicked: false
}

startHomeUi :: Effect (Context HomeState)
startHomeUi = do
  renderFn <- startUi
  {context, updateState} <- newUi (encode >>> runEffectFn1 renderFn)
  runEffectFn1 setStateListener $ mkEffectFn1 \f -> case runExcept $ decode f of
    Right state -> updateState state
    Left e-> error $ "Screen state error: " <> show e
  pure context
