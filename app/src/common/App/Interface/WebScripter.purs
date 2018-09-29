module App.Interface.WebScripter (
    ScripterId(..)
  , ScriptStep(..)
  , Script(..)
  , createScripter
  , killScripter
  , showScripter
  , hideScripter
  , executeScripter
  ) where

import Prelude

import Control.Monad.Except (runExcept)
import Data.Either (Either(..), hush)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe)
import Data.Newtype (class Newtype)
import Effect (Effect)
import Effect.Aff (Aff, effectCanceler, makeAff, nonCanceler)
import Effect.Class (liftEffect)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn4, mkEffectFn1, runEffectFn1, runEffectFn2, runEffectFn4)
import Foreign (Foreign, unsafeToForeign)
import Foreign.Class (class Encode, decode)
import Foreign.Generic (defaultOptions, encodeJSON, genericEncode)

newtype ScripterId = ScripterId String

derive instance newtypeScripterId :: Newtype ScripterId _

data ScriptStep = URL String | JS String
newtype Script = Script (Array ScriptStep)



instance encodeScriptStep :: Encode ScriptStep where
  encode (URL url) = unsafeToForeign {type: "URL", command: url}
  encode (JS codeSnippet) = unsafeToForeign {type: "JS", command: codeSnippet}

derive instance newtypeScript :: Newtype Script _
derive instance genericScript :: Generic Script _
instance encodeScript :: Encode Script where encode = genericEncode defaultOptions {unwrapSingleConstructors = true}

foreign import spawnWebScripterImpl :: EffectFn2 String (Effect Unit) Unit
foreign import killScripterImpl :: EffectFn1 String Unit
foreign import executeScripterImpl :: EffectFn4 String String (EffectFn1 (Array Foreign) Unit) (EffectFn1 String Unit) Unit
foreign import cancelScripterImpl :: EffectFn1 String Unit
foreign import showScripterImpl :: EffectFn1 String Unit
foreign import hideScripterImpl :: EffectFn1 String Unit

createScripter :: ScripterId -> Aff Unit
createScripter (ScripterId id) =
  makeAff (\cb -> runEffectFn2 spawnWebScripterImpl id (cb $ Right unit) *> pure nonCanceler)

killScripter :: ScripterId -> Aff Unit
killScripter (ScripterId id) =
  liftEffect $ runEffectFn1 killScripterImpl id

showScripter :: ScripterId -> Aff Unit
showScripter (ScripterId id) =
  liftEffect $ runEffectFn1 showScripterImpl id

hideScripter :: ScripterId -> Aff Unit
hideScripter (ScripterId id) =
  liftEffect $ runEffectFn1 hideScripterImpl id

executeScripter :: ScripterId -> Script -> Aff (Either String (Array (Maybe String)))
executeScripter (ScripterId id) script =
  let
    decodeMaybeString = decode >>> runExcept >>> hush
    success cb = (mkEffectFn1 $ map decodeMaybeString >>> Right >>> Right >>> cb)
    error cb = (mkEffectFn1 $ Left >>> Right >>> cb) in
  makeAff (\cb -> runEffectFn4 executeScripterImpl id (encodeJSON script) (success cb) (error cb)
                    *> pure (effectCanceler (runEffectFn1 cancelScripterImpl id)))
