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

foreign import _setupInterface :: Effect Unit
foreign import _spawnWebScripter :: EF2 String (Effect Unit)
foreign import _killScripter :: EF1 String
foreign import _executeScripter :: EF4 String String (EF1 (Array Foreign)) (EF1 String)
foreign import _showScripter :: EF1 String
foreign import _hideScripter :: EF1 String
foreign import _exit :: Effect Unit
