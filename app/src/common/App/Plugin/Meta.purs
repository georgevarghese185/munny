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

newtype PluginMeta = PluginMeta {
  name :: String
, type :: Array String
, inputs :: Array String
, outputs :: Array String
}

derive instance newtypePluginMeta :: Newtype PluginMeta _
derive instance genericPluginMeta :: Generic PluginMeta _
instance encodePluginMeta :: Encode PluginMeta where encode = genericEncode defaultOptions {unwrapSingleConstructors = true}
instance decodePluginMeta :: Decode PluginMeta where decode = genericDecode defaultOptions {unwrapSingleConstructors = true}


getPluginMeta :: String -> ExceptT Error Aff (Maybe PluginMeta)
getPluginMeta pluginName = do
  find (\(PluginMeta m) -> m.name == pluginName) <$> getPlugins

getPluginsByType :: String -> ExceptT Error Aff (Array PluginMeta)
getPluginsByType type' = do
  filter (\(PluginMeta m) -> elem type' m.type) <$> getPlugins

getPlugins :: ExceptT Error Aff (Array PluginMeta)
getPlugins = do
  response <- lift $ get (ResponseFormat.string) $ "meta.json"
  jsonString <- case response.body of
    Right jsonString -> pure jsonString
    Left err -> throwError $ error $ "Failed to fetch plugin meta: " <> printResponseFormatError err

  case runExcept $ parseJSON jsonString >>= flip index "plugins" >>= decode of
    Right plugins -> pure plugins
    Left err -> throwError $ error $ "Failed to parse plugin meta: " <> show err
