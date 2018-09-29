module Interface.SecureDevice (
    KeyAlias(..)
  , Cipher
  , isDeviceSecure
  , isUserAuthenticated
  , authenticateUser
  , generateSecureKey
  , generateSecureKeyWithUserAuth
  , secureEncrypt
  , secureDecrypt
  ) where

import Prelude

import Data.Either (Either(..), fromRight)
import Data.Newtype (class Newtype)
import Data.String.Regex (Regex, regex, test)
import Data.String.Regex.Flags (noFlags)
import Effect (Effect)
import Effect.Aff (Aff, makeAff, nonCanceler)
import Effect.Class (liftEffect)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn3, EffectFn4, mkEffectFn1, runEffectFn2, runEffectFn3, runEffectFn4)
import Foreign (ForeignError(..), fail, readString)
import Foreign.Class (class Decode, class Encode, encode)
import Partial.Unsafe (unsafePartial)
import Unsafe.Coerce (unsafeCoerce)

newtype KeyAlias = KeyAlias String

derive instance newtypeKeyAlias :: Newtype KeyAlias _


foreign import data Cipher :: Type
foreign import isDeviceSecureImpl :: Effect Boolean
foreign import isUserAuthenticatedImpl :: Effect Boolean
foreign import authenticateUserImpl :: EffectFn2 (Effect Unit) (EffectFn1 String Unit) Unit
foreign import generateSecureKeyImpl :: EffectFn3 String (Effect Unit) (EffectFn1 String Unit) Unit
foreign import generateSecureKeyWithUserAuthImpl :: EffectFn4 String Int (Effect Unit) (EffectFn1 String Unit) Unit
foreign import secureEncryptImpl :: EffectFn4 String String (EffectFn1 String Unit) (EffectFn1 String Unit) Unit
foreign import secureDecryptImpl :: EffectFn4 String String (EffectFn1 String Unit) (EffectFn1 String Unit) Unit

toCipher :: String -> Cipher
toCipher = unsafeCoerce

fromCipher :: Cipher -> String
fromCipher = unsafeCoerce

instance showCipher :: Show Cipher where show = fromCipher
instance encodeCipher :: Encode Cipher where
  encode = fromCipher >>> encode
instance decodeCipher :: Decode Cipher where
  decode f = toCipher <$>
    (readString f >>= (\s -> if test cipherRegex s then pure s else fail notCipherError))
    where
      cipherRegex :: Regex
      cipherRegex = unsafePartial $ fromRight $ regex (base64Pattern <> "_" <> base64Pattern) noFlags

      base64Pattern :: String
      base64Pattern = "^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{4}|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/]{2}==)$"

      notCipherError :: ForeignError
      notCipherError = ForeignError "String does not match cipher pattern"



isDeviceSecure :: Aff Boolean
isDeviceSecure = liftEffect isDeviceSecureImpl

isUserAuthenticated :: Aff Boolean
isUserAuthenticated = liftEffect isUserAuthenticatedImpl

authenticateUser :: Aff (Either String Unit)
authenticateUser =
  makeAff (\cb -> runEffectFn2 authenticateUserImpl
                    (cb $ Right $ Right unit)
                    (mkEffectFn1 $ Left >>> Right >>> cb)
                    *> pure nonCanceler)

generateSecureKey :: KeyAlias -> Aff (Either String Unit)
generateSecureKey (KeyAlias keyAlias) =
  makeAff (\cb -> runEffectFn3 generateSecureKeyImpl
                    keyAlias
                    (cb $ Right $ Right unit)
                    (mkEffectFn1 $ Left >>> Right >>> cb)
                    *> pure nonCanceler)

generateSecureKeyWithUserAuth :: KeyAlias -> Int -> Aff (Either String Unit)
generateSecureKeyWithUserAuth (KeyAlias keyAlias) authValidSeconds =
 makeAff (\cb -> runEffectFn4 generateSecureKeyWithUserAuthImpl
                  keyAlias
                  authValidSeconds
                  (cb $ Right $ Right unit)
                  (mkEffectFn1 $ Left >>> Right >>> cb)
                  *> pure nonCanceler)

secureEncrypt :: String -> KeyAlias -> Aff (Either String Cipher)
secureEncrypt text (KeyAlias keyAlias) =
  makeAff (\cb -> runEffectFn4 secureEncryptImpl
                    text
                    keyAlias
                    (mkEffectFn1 $ toCipher >>> Right >>> Right >>> cb)
                    (mkEffectFn1 $ Left >>> Right >>> cb)
                    *> pure nonCanceler)

secureDecrypt :: Cipher -> KeyAlias -> Aff (Either String String)
secureDecrypt cipher (KeyAlias keyAlias) =
  makeAff (\cb -> runEffectFn4 secureDecryptImpl
                    (fromCipher cipher)
                    keyAlias
                    (mkEffectFn1 $ Right >>> Right >>> cb)
                    (mkEffectFn1 $ Left >>> Right >>> cb)
                    *> pure nonCanceler)
