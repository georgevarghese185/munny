module SecureDevice (
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
import Effect.Aff (Aff, makeAff, nonCanceler)
import Effect.Class (liftEffect)
import Effect.Uncurried (mkEffectFn1, runEffectFn2, runEffectFn3, runEffectFn4)
import Foreign (ForeignError(..), fail, readString)
import Foreign.Class (class Decode, class Encode, encode)
import Interface (_authenticateUser, _generateSecureKey, _generateSecureKeyWithUserAuth, _isDeviceSecure, _isUserAuthenticated, _secureEncrypt)
import Partial.Unsafe (unsafePartial)
import Unsafe.Coerce (unsafeCoerce)

newtype KeyAlias = KeyAlias String

derive instance newtypeKeyAlias :: Newtype KeyAlias _


foreign import data Cipher :: Type

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
isDeviceSecure = liftEffect _isDeviceSecure

isUserAuthenticated :: Aff Boolean
isUserAuthenticated = liftEffect _isUserAuthenticated

authenticateUser :: Aff (Either String Unit)
authenticateUser =
  makeAff (\cb -> runEffectFn2 _authenticateUser
                    (cb $ Right $ Right unit)
                    (mkEffectFn1 $ Left >>> Right >>> cb)
                    *> pure nonCanceler)

generateSecureKey :: KeyAlias -> Aff (Either String Unit)
generateSecureKey (KeyAlias keyAlias) =
  makeAff (\cb -> runEffectFn3 _generateSecureKey
                    keyAlias
                    (cb $ Right $ Right unit)
                    (mkEffectFn1 $ Left >>> Right >>> cb)
                    *> pure nonCanceler)

generateSecureKeyWithUserAuth :: KeyAlias -> Int -> Aff (Either String Unit)
generateSecureKeyWithUserAuth (KeyAlias keyAlias) authValidSeconds =
 makeAff (\cb -> runEffectFn4 _generateSecureKeyWithUserAuth
                  keyAlias
                  authValidSeconds
                  (cb $ Right $ Right unit)
                  (mkEffectFn1 $ Left >>> Right >>> cb)
                  *> pure nonCanceler)

secureEncrypt :: String -> KeyAlias -> Aff (Either String Cipher)
secureEncrypt text (KeyAlias keyAlias) =
  makeAff (\cb -> runEffectFn4 _secureEncrypt
                    text
                    keyAlias
                    (mkEffectFn1 $ toCipher >>> Right >>> Right >>> cb)
                    (mkEffectFn1 $ Left >>> Right >>> cb)
                    *> pure nonCanceler)

secureDecrypt :: Cipher -> KeyAlias -> Aff (Either String String)
secureDecrypt cipher (KeyAlias keyAlias) =
  makeAff (\cb -> runEffectFn4 _secureEncrypt
                    (fromCipher cipher)
                    keyAlias
                    (mkEffectFn1 $ Right >>> Right >>> cb)
                    (mkEffectFn1 $ Left >>> Right >>> cb)
                    *> pure nonCanceler)
