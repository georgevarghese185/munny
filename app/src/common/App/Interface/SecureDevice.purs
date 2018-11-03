module App.Interface.SecureDevice (
    KeyAlias(..)
  , Cipher
  , DeviceSecureStatus(..)
  , isDeviceSecure
  , isUserAuthenticated
  , authenticateUser
  , secureEncrypt
  , secureDecrypt
  ) where

import Prelude

import App.Interface (ErrorResponse, toErrorResponse)
import Data.Either (Either(..), fromRight)
import Data.Generic.Rep (class Generic)
import Data.Newtype (class Newtype)
import Data.String.Regex (Regex, regex, test)
import Data.String.Regex.Flags (noFlags)
import Effect (Effect)
import Effect.Aff (Aff, makeAff, nonCanceler)
import Effect.Class (liftEffect)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn5, mkEffectFn1, runEffectFn2, runEffectFn5)
import Foreign (ForeignError(..), fail, readString)
import Foreign.Class (class Decode, class Encode, encode)
import Foreign.Generic (encodeJSON)
import Foreign.Generic.EnumEncoding (defaultGenericEnumOptions, genericEncodeEnum)
import Partial.Unsafe (unsafePartial)
import Unsafe.Coerce (unsafeCoerce)

newtype KeyAlias = KeyAlias String

derive instance newtypeKeyAlias :: Newtype KeyAlias _


foreign import data Cipher :: Type
foreign import isDeviceSecureImpl :: Effect Int
foreign import isUserAuthenticatedImpl :: Effect Boolean
foreign import authenticateUserImpl :: EffectFn2 (Effect Unit) (EffectFn1 String Unit) Unit
foreign import secureEncryptImpl :: EffectFn5 String String (EffectFn1 String Unit) (EffectFn1 String Unit) Boolean Unit
foreign import secureDecryptImpl :: EffectFn5 String String (EffectFn1 String Unit) (EffectFn1 String Unit) Boolean Unit

data DeviceSecureStatus = Secure | Insecure | NotSupported | Other

derive instance genericDeviceSecureStatus :: Generic DeviceSecureStatus _
instance encodeDeviceSecureStatus :: Encode DeviceSecureStatus where encode = genericEncodeEnum defaultGenericEnumOptions
instance showDeviceSecureStatus :: Show DeviceSecureStatus where show = encodeJSON

toDeviceSecureStatus :: Int -> DeviceSecureStatus
toDeviceSecureStatus -1 = Secure
toDeviceSecureStatus 1 = Insecure
toDeviceSecureStatus 2 = NotSupported
toDeviceSecureStatus _ = Other

noLockError :: Int
noLockError = 1

authNotSupportedError :: Int
authNotSupportedError = 2

keysInvalidatedError :: Int
keysInvalidatedError = 3

authFailedError :: Int
authFailedError = 4

tooManyAttemptsError :: Int
tooManyAttemptsError = 5

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



isDeviceSecure :: Aff DeviceSecureStatus
isDeviceSecure = toDeviceSecureStatus <$> liftEffect isDeviceSecureImpl

isUserAuthenticated :: Aff Boolean
isUserAuthenticated = liftEffect isUserAuthenticatedImpl

authenticateUser :: Aff (Either ErrorResponse Unit)
authenticateUser =
  makeAff (\cb -> runEffectFn2 authenticateUserImpl
                    (cb $ Right $ Right unit)
                    (mkEffectFn1 $ toErrorResponse >>> Left >>> Right >>> cb)
                    *> pure nonCanceler)

secureEncrypt :: String -> KeyAlias -> Boolean -> Aff (Either ErrorResponse Cipher)
secureEncrypt text (KeyAlias keyAlias) userAuthenticated =
  makeAff (\cb -> runEffectFn5 secureEncryptImpl
                    text
                    keyAlias
                    (mkEffectFn1 $ toCipher >>> Right >>> Right >>> cb)
                    (mkEffectFn1 $ toErrorResponse >>> Left >>> Right >>> cb)
                    userAuthenticated
                    *> pure nonCanceler)

secureDecrypt :: Cipher -> KeyAlias -> Boolean -> Aff (Either ErrorResponse String)
secureDecrypt cipher (KeyAlias keyAlias) userAuthenticated =
  makeAff (\cb -> runEffectFn5 secureDecryptImpl
                    (fromCipher cipher)
                    keyAlias
                    (mkEffectFn1 $ Right >>> Right >>> cb)
                    (mkEffectFn1 $ toErrorResponse >>> Left >>> Right >>> cb)
                    userAuthenticated
                    *> pure nonCanceler)
