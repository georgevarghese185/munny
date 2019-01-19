module App.Plugin (
    Plugin(..)
  , getPlugin
  , getPluginsByType
  , getPlugins
  , initialize
  , loadPlugin
  , unloadPlugin
  , pluginReady
  ) where

import Prelude

import Affjax (get, printResponseFormatError)
import Affjax.ResponseFormat as ResponseFormat
import Control.Monad.Except (ExceptT(..), catchError, runExcept, throwError)
import Control.Monad.Maybe.Trans (MaybeT(..), lift, runMaybeT)
import Data.Array (elem, filter)
import Data.Either (Either(..), either)
import Data.Foldable (find)
import Data.Generic.Rep (class Generic)
import Data.Maybe (Maybe, maybe)
import Data.Newtype (class Newtype)
import Effect (Effect)
import Effect.Aff (Aff, Error, cancelWith, effectCanceler, error, makeAff, nonCanceler, runAff_)
import Effect.Class (liftEffect)
import Effect.Exception (throw, throwException)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn3, mkEffectFn1, mkEffectFn2, mkEffectFn3, mkEffectFn4, runEffectFn1, runEffectFn2, runEffectFn3)
import Foreign (Foreign, unsafeToForeign)
import Foreign.Class (class Decode, class Encode, decode)
import Foreign.Generic (defaultOptions, genericDecode, genericEncode)
import Foreign.Index (index)
import Foreign.JSON (parseJSON)
import Web.DOM.Document (Document)
import Web.DOM.Document (createElement, toNonElementParentNode, toParentNode) as Document
import Web.DOM.Element (setId, toNode)
import Web.DOM.Node (appendChild, removeChild)
import Web.DOM.NonElementParentNode (getElementById)
import Web.DOM.ParentNode (QuerySelector(..), querySelector)
import Web.Event.Event (EventType(..))
import Web.Event.EventTarget (addEventListener, eventListener)
import Web.HTML (HTMLHeadElement, HTMLScriptElement)
import Web.HTML as HTML
import Web.HTML.HTMLDocument (toDocument) as Document
import Web.HTML.HTMLHeadElement as Head
import Web.HTML.HTMLScriptElement as Script
import Web.HTML.Window as Window

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

type PluginErrorFn = EffectFn1 Error Unit
type PluginSuccessFn = EffectFn1 Foreign Unit
type StartFn = EffectFn3 PluginErrorFn PluginSuccessFn Foreign Unit

foreign import waitForPluginReady :: EffectFn1 (EffectFn2 String StartFn Unit) Unit
foreign import setPluginsObjectImpl :: EffectFn1 Foreign Unit
foreign import pluginReadyImpl :: EffectFn2 String StartFn Unit

getDocument :: Effect Document
getDocument = Document.toDocument <$> (HTML.window >>= Window.document)

getHead :: Document -> Effect (Maybe HTMLHeadElement)
getHead document = runMaybeT do
  element <- MaybeT $ querySelector (QuerySelector "head") (Document.toParentNode document)
  MaybeT $ pure $ Head.fromElement element

initialize :: Effect Unit
initialize = runEffectFn1 setPluginsObjectImpl $ unsafeToForeign {
    loadPlugin: mkEffectFn4 load,
    unload: mkEffectFn1 unloadPlugin
  }
  where
  load :: String -> PluginErrorFn -> PluginSuccessFn -> Foreign -> Effect Unit
  load pluginName errorCb successCb input =
    let errorHandler = either (runEffectFn1 errorCb) (runEffectFn1 successCb)
    in runAff_ errorHandler (loadPlugin_ pluginName input)


loadPlugin :: String -> Foreign -> ExceptT Error Aff Foreign
loadPlugin pluginName input = ExceptT $ flip cancelWith
  (effectCanceler $ unloadPlugin pluginName)
  do
    result <- catchError (Right <$> loadPlugin_ pluginName input) (Left >>> pure)
    liftEffect $ unloadPlugin pluginName
    pure result


loadPlugin_ :: String -> Foreign -> Aff Foreign
loadPlugin_ pluginName input = do
  script <- createPluginScript
  pluginStartFn <- makeAff (\cb -> loadPluginScript script cb *> pure nonCanceler)
  startPlugin pluginStartFn
  where
    createPluginScript :: Aff HTMLScriptElement
    createPluginScript = liftEffect $ do
      document <- getDocument
      mScript <- Script.fromElement <$> Document.createElement "script" document
      script <- maybe (throw scriptElementErr) pure mScript
      setId pluginName (Script.toElement script)
      Script.setSrc (pluginName <> "/index.js") script
      pure script
      where
      scriptElementErr :: String
      scriptElementErr = "Failed to create script element"

    loadPluginScript :: HTMLScriptElement -> (Either Error StartFn -> Effect Unit) -> Effect Unit
    loadPluginScript script cb = do
      document <- getDocument
      errorListener <- eventListener $ \_ -> cb $ Left $ scriptLoadErr
      head <- maybe (throwException headError) pure =<< getHead document
      addEventListener (EventType "error") errorListener true (Script.toEventTarget script)
      runEffectFn1 waitForPluginReady (mkEffectFn2 $
        \name startFn -> if name == pluginName then cb (Right startFn) else pure unit)
      void $ appendChild (Script.toNode script) (Head.toNode head)
      where
      scriptLoadErr :: Error
      scriptLoadErr = error "Failed to load script"

      headError :: Error
      headError = error "Failed to get head element"

    startPlugin :: StartFn -> Aff Foreign
    startPlugin startFn = makeAff $ \cb -> do
      runEffectFn3 startFn
        (mkEffectFn1 $ Left >>> cb)
        (mkEffectFn1 $ Right >>> cb)
        input
      pure nonCanceler


unloadPlugin :: String -> Effect Unit
unloadPlugin pluginName = void $ runMaybeT do
  document <- lift $ getDocument
  head <- MaybeT $ getHead document
  script <- MaybeT $ getElementById pluginName (Document.toNonElementParentNode document)
  lift $ removeChild (toNode script) (Head.toNode head)


pluginReady :: String -> (Foreign -> Aff Foreign) -> (Effect Unit)
pluginReady pluginName pluginStart =
  let handler errorCb successCb = either (runEffectFn1 errorCb) (runEffectFn1 successCb)
  in runEffectFn2
      pluginReadyImpl
      pluginName
      (mkEffectFn3 $ \error success input -> runAff_ (handler error success) (pluginStart input))
