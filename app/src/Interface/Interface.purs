module Interface where

import Prelude

import Data.Either (Either(..))
import Data.Newtype (class Newtype)
import Effect (Effect)
import Effect.Aff (Aff, makeAff, nonCanceler)
import Effect.Class (liftEffect)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn3, EffectFn4, runEffectFn1, runEffectFn2)
import Foreign (Foreign)

type EF1 a = EffectFn1 a Unit
type EF2 a b = EffectFn2 a b Unit
type EF3 a b c = EffectFn3 a b c Unit
type EF4 a b c d = EffectFn4 a b c d Unit

foreign import setupInterface :: Effect Unit
foreign import spawnWebScripter :: EF2 String (Effect Unit)
foreign import killScripter :: EF1 String
foreign import executeScripter :: EF4 String String (EF1 (Array Foreign)) (EF1 String)
foreign import showScripter :: EF1 String
foreign import hideScripter :: EF1 String
foreign import exit :: Effect Unit
