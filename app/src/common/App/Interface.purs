module App.Interface where

import Prelude

import Control.Monad.Except (runExcept)
import Data.Either (either)
import Data.Generic.Rep (class Generic)
import Data.Newtype (class Newtype, unwrap)
import Effect (Effect)
import Foreign.Class (class Decode, class Encode)
import Foreign.Generic (decodeJSON, defaultOptions, genericDecode, genericEncode)

foreign import setupInterface :: Effect Unit
foreign import exit :: Effect Unit

newtype ErrorResponse = ErrorResponse {
  errorCode :: Int
, errorMessage :: String
}

derive instance newtypeErrorResponse :: Newtype ErrorResponse _
derive instance genericErrorResponse :: Generic ErrorResponse _
instance showErrorResponse :: Show ErrorResponse where show = unwrap >>> _.errorMessage
instance encodeErrorResponse :: Encode ErrorResponse where encode = genericEncode defaultOptions{unwrapSingleConstructors = true}
instance decodeErrorResponse :: Decode ErrorResponse where decode = genericDecode defaultOptions{unwrapSingleConstructors = true}

toErrorResponse :: String -> ErrorResponse
toErrorResponse s = either
  (show >>> {errorCode: 0, errorMessage: _} >>> ErrorResponse)
  identity
  $ runExcept $ decodeJSON s
