module Interface.Events where

import Prelude

import Data.Foldable (traverse_)
import Effect (Effect)
import Effect.Class.Console (log)
import Effect.Uncurried (EffectFn1, EffectFn2, runEffectFn1, runEffectFn2)

foreign import setupEventsImpl :: EffectFn1 (Array String) Unit
foreign import addEventListener :: EffectFn2 String (Effect Unit) Unit
foreign import removeEventListener :: EffectFn2 String (Effect Unit) Unit

data Event = Pause | Resume | BackPressed

instance showEvents :: Show Event where
  show Pause = "onPause"
  show Resume = "onResume"
  show BackPressed = "onBackPressed"

events :: Array Event
events = [Pause, Resume, BackPressed]

setupEvents :: Effect Unit
setupEvents = do
  runEffectFn1 setupEventsImpl $ show <$> events
  traverse_ (\event -> runEffectFn2 addEventListener event (log event)) (show <$> events)
