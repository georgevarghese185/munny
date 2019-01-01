module App.Plugin.Meta where

import Prelude

import Affjax (get, printResponseFormatError)
import Affjax.ResponseFormat as ResponseFormat
import Control.Monad.Except (ExceptT, lift, runExcept, throwError)
import Data.Array (filter)
import Data.Either (Either(..))
import Data.Foldable (elem, find)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe)
import Data.Newtype (class Newtype)
import Effect.Aff (Aff, Error, error)
import Foreign.Class (class Decode, class Encode, decode)
import Foreign.Generic (defaultOptions, genericDecode, genericEncode)
import Foreign.Index (index)
import Foreign.JSON (parseJSON)

newtype Plugin = Plugin {
  name :: String
, type :: Array String
, inputs :: Array String
, outputs :: Array String
}

derive instance newtypePlugin :: Newtype Plugin _
derive instance genericPlugin :: Generic Plugin _
instance encodePlugin :: Encode Plugin where encode = genericEncode defaultOptions {unwrapSingleConstructors = true}
instance decodePlugin :: Decode Plugin where decode = genericDecode defaultOptions {unwrapSingleConstructors = true}


getPlugin :: String -> ExceptT Error Aff (Maybe Plugin)
getPlugin pluginName = do
  find (\(Plugin m) -> m.name == pluginName) <$> getPlugins

getPluginsByType :: String -> ExceptT Error Aff (Array Plugin)
getPluginsByType type' = do
  filter (\(Plugin m) -> elem type' m.type) <$> getPlugins

getPlugins :: ExceptT Error Aff (Array Plugin)
getPlugins = do
  response <- lift $ get (ResponseFormat.string) $ "plugins.json"
  jsonString <- case response.body of
    Right jsonString -> pure jsonString
    Left err -> throwError $ error $ "Failed to fetch plugin meta: " <> printResponseFormatError err

  case runExcept $ parseJSON jsonString >>= flip index "plugins" >>= decode of
    Right plugins -> pure plugins
    Left err -> throwError $ error $ "Failed to parse plugin meta: " <> show err
