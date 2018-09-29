module App.Plugin (
    initialize
  , loadPlugin
  , unloadPlugin
  , pluginReady
  ) where

import Prelude

import Control.Monad.Except (ExceptT, catchError, throwError)
import Control.Monad.Maybe.Trans (lift)
import Data.Either (Either(..), either)
import Data.Maybe (maybe)
import Effect (Effect)
import Effect.Aff (Aff, Error, error, makeAff, nonCanceler, runAff_)
import Effect.Class (liftEffect)
import Effect.Exception (throw)
import Effect.Uncurried (EffectFn1, EffectFn2, EffectFn3, mkEffectFn1, mkEffectFn2, mkEffectFn3, mkEffectFn4, runEffectFn1, runEffectFn2, runEffectFn3)
import Foreign (Foreign, unsafeToForeign)
import Web.DOM.Document (Document)
import Web.DOM.Document (createElement, toNode, toNonElementParentNode) as Document
import Web.DOM.Element (setId, toNode)
import Web.DOM.Node (appendChild, removeChild)
import Web.DOM.NonElementParentNode (getElementById)
import Web.Event.Event (EventType(..))
import Web.Event.EventTarget (addEventListener, eventListener)
import Web.HTML (HTMLScriptElement)
import Web.HTML as HTML
import Web.HTML.HTMLDocument (toDocument) as Document
import Web.HTML.HTMLScriptElement as Script
import Web.HTML.Window as Window


type PluginErrorFn = EffectFn1 Error Unit
type PluginSuccessFn = EffectFn1 Foreign Unit
type StartFn = EffectFn3 PluginErrorFn PluginSuccessFn Foreign Unit

foreign import waitForPluginReady :: EffectFn1 (EffectFn2 String StartFn Unit) Unit
foreign import setPluginsObjectImpl :: EffectFn1 Foreign Unit
foreign import pluginReadyImpl :: EffectFn2 String StartFn Unit

getDocument :: Effect Document
getDocument = Document.toDocument <$> (HTML.window >>= Window.document)



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
loadPlugin pluginName input = catchError (lift $ loadPlugin_ pluginName input) throwError


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
      Script.setSrc ("file:///android_asset/" <> pluginName <> "/index.js") script
      pure script
      where
      scriptElementErr :: String
      scriptElementErr = "Failed to create script element"

    loadPluginScript :: HTMLScriptElement -> (Either Error StartFn -> Effect Unit) -> Effect Unit
    loadPluginScript script cb = do
      document <- getDocument
      errorListener <- eventListener $ \_ -> cb $ Left $ scriptLoadErr
      addEventListener (EventType "error") errorListener true (Script.toEventTarget script)
      runEffectFn1 waitForPluginReady (mkEffectFn2 $
        \name startFn -> if name == pluginName then cb (Right startFn) else pure unit)
      void $ appendChild (Script.toNode script) (Document.toNode document)
      where
      scriptLoadErr :: Error
      scriptLoadErr = error "Failed to load script"

    startPlugin :: StartFn -> Aff Foreign
    startPlugin startFn = makeAff $ \cb -> do
      runEffectFn3 startFn
        (mkEffectFn1 $ Left >>> cb)
        (mkEffectFn1 $ Right >>> cb)
        input
      pure nonCanceler


unloadPlugin :: String -> Effect Unit
unloadPlugin pluginName = do
  document <- getDocument
  mScript <- getElementById pluginName (Document.toNonElementParentNode document)
  maybe (pure unit) (\s -> void $ removeChild (toNode s) (Document.toNode document)) mScript


pluginReady :: String -> (Foreign -> Aff Foreign) -> (Effect Unit)
pluginReady pluginName pluginStart =
  let handler errorCb successCb = either (runEffectFn1 errorCb) (runEffectFn1 successCb)
  in runEffectFn2
      pluginReadyImpl
      pluginName
      (mkEffectFn3 $ \error success input -> runAff_ (handler error success) (pluginStart input))
