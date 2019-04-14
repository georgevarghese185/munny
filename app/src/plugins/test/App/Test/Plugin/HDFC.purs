module App.Test.Plugin.HDFC where

import Prelude

import App.Interface (setupInterface)
import App.Interface.Events (setupEvents)
import App.Interface.WebScripter (ScripterId(..), createScripter, executeScripter)
import Control.Monad.Except (ExceptT(..), lift, runExceptT, throwError)
import Data.Array (last)
import Data.Either (Either(..), note)
import Data.Maybe (Maybe)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_, makeAff, nonCanceler)
import Effect.Class (liftEffect)
import Effect.Class.Console (logShow)
import Effect.Uncurried (EffectFn1, EffectFn2, mkEffectFn1, runEffectFn2)
import Plugin.HDFC.Script (accountBalancesScript, loginScript, sendOtpScript, submitOtpScript)

id = ScripterId "test"

foreign import askImpl :: EffectFn2 String (EffectFn1 String Unit) Unit

main :: Effect Unit
main = launchAff_ do
  liftEffect do
    setupInterface
    setupEvents
  createScripter id
  username <- ask "username"
  password <- ask "password"
  result <- runExceptT do
    isOtpPage <- (ExceptT $ executeScripter id $ loginScript username password) >>= lastResult "login"
    case isOtpPage of
      "true" -> otpPage
      "false" -> pure unit
      e -> throwError e
    (ExceptT $ executeScripter id accountBalancesScript) >>= lastResult "account balance"
  logShow result

otpPage :: ExceptT String Aff Unit
otpPage = do
  isOtpEntryPage <- (ExceptT $ executeScripter id sendOtpScript) >>= lastResult "send otp"
  when (isOtpEntryPage == "false") $ throwError "Didn't reach otp entry page"
  otp <- lift $ ask "otp"
  void $ ExceptT $ executeScripter id (submitOtpScript otp)

ask :: String -> Aff String
ask question = makeAff \cb -> runEffectFn2 askImpl question (mkEffectFn1 (Right >>> cb)) *> pure nonCanceler

lastResult :: forall m. Applicative m => String -> Array (Maybe String) -> ExceptT String m String
lastResult stepName = last >>> join >>> note ("Empty result from " <> stepName) >>> pure >>> ExceptT
