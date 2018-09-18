module Interface where

import Prelude

import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn3, EffectFn4)
import Foreign (Foreign)

type EF1 a = EffectFn1 a Unit
type EF2 a b = EffectFn2 a b Unit
type EF3 a b c = EffectFn3 a b c Unit
type EF4 a b c d = EffectFn4 a b c d Unit

foreign import _setupInterface :: Effect Unit
foreign import _spawnWebScripter :: EF2 String (Effect Unit)
foreign import _killScripter :: EF1 String
foreign import _executeScripter :: EF4 String String (EF1 (Array Foreign)) (EF1 String)
foreign import _cancelScripter :: EF1 String
foreign import _showScripter :: EF1 String
foreign import _hideScripter :: EF1 String

foreign import _isDeviceSecure :: Effect Boolean
foreign import _isUserAuthenticated :: Effect Boolean
foreign import _authenticateUser :: EF2 (Effect Unit) (EF1 String)
foreign import _generateSecureKey :: EF3 String (Effect Unit) (EF1 String)
foreign import _generateSecureKeyWithUserAuth :: EF4 String Int (Effect Unit) (EF1 String)
foreign import _secureEncrypt :: EF4 String String (EF1 String) (EF1 String)
foreign import _secureDecrypt :: EF4 String String (EF1 String) (EF1 String)

foreign import _exit :: Effect Unit
