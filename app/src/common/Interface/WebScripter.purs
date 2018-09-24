module Interface.WebScripter where

import Prelude

import Control.Monad.Except (runExcept)
import Data.Either (Either(..), hush)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe)
import Data.Newtype (class Newtype)
import Effect.Aff (Aff, effectCanceler, makeAff, nonCanceler)
import Effect.Class (liftEffect)
import Effect.Uncurried (mkEffectFn1, runEffectFn1, runEffectFn2, runEffectFn4)
import Foreign (unsafeToForeign)
import Foreign.Class (class Encode, decode)
import Foreign.Generic (defaultOptions, encodeJSON, genericEncode)
import Interface (_cancelScripter)
import Interface as Interface

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


createScripter :: ScripterId -> Aff Unit
createScripter (ScripterId id) =
  makeAff (\cb -> runEffectFn2 Interface._spawnWebScripter id (cb $ Right unit) *> pure nonCanceler)

killScripter :: ScripterId -> Aff Unit
killScripter (ScripterId id) =
  liftEffect $ runEffectFn1 Interface._killScripter id

showScripter :: ScripterId -> Aff Unit
showScripter (ScripterId id) =
  liftEffect $ runEffectFn1 Interface._showScripter id

hideScripter :: ScripterId -> Aff Unit
hideScripter (ScripterId id) =
  liftEffect $ runEffectFn1 Interface._hideScripter id

executeScripter :: ScripterId -> Script -> Aff (Either String (Array (Maybe String)))
executeScripter (ScripterId id) script =
  let
    decodeMaybeString = decode >>> runExcept >>> hush
    success cb = (mkEffectFn1 $ map decodeMaybeString >>> Right >>> Right >>> cb)
    error cb = (mkEffectFn1 $ Left >>> Right >>> cb) in
  makeAff (\cb -> runEffectFn4 Interface._executeScripter id (encodeJSON script) (success cb) (error cb)
                    *> pure (effectCanceler (runEffectFn1 _cancelScripter id)))
