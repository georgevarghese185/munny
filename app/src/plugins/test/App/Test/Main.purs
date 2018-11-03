module App.Test.Main where

import Prelude

import App.Interface (setupInterface)
import App.Interface.Events (setupEvents)
import App.Interface.SecureDevice (DeviceSecureStatus(..), KeyAlias(..), authenticateUser, isDeviceSecure, secureDecrypt, secureEncrypt)
import App.Interface.WebScripter (Script(..), ScriptStep(..), ScripterId(..), createScripter, executeScripter, hideScripter, killScripter, showScripter)
import Data.Either (Either(..), either)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class.Console (error, log, logShow, warn)

main :: Effect Unit
main = do
  log "Setting up Interface" *> setupInterface
  log "Setting up Event listeners" *> setupEvents
  log "Startup complete"
  launchAff_ app

app :: Aff Unit
app = do
  scripterTest
  authTest
  encryptionTest
  deviceSecure <- isDeviceSecure
  warn $ "Device Secure: " <> show deviceSecure
  case deviceSecure of
    Secure -> authEncryptionTest
    _ -> error $ "Can't test auth encryption"

scripterTest :: Aff Unit
scripterTest = do
  let
    id = ScripterId "test"
    script = Script [
      URL "https://techradar.com",
      JS $    "var articleNames = Array.from(document.getElementsByClassName(\"article-name\")).map(h => h.innerHTML);"
          <>  "Interface.onCommandDone(JSON.stringify(articleNames));"
    ]
  warn "Creating scripter"
  createScripter id
  warn "Showing scripter"
  showScripter id
  warn "executing"
  result <- executeScripter id script
  warn "hiding scripter"
  hideScripter id
  either (\e -> error $ "Execution error: " <> e) (\r -> warn "Scripter result" *> logShow r) result
  warn "Killing scripter"
  killScripter id

authTest :: Aff Unit
authTest = do
  warn "User Auth Test (Success case)"
  authenticateUser >>= either (show >>> append "authentication error: " >>> error) (const $ warn "auth success")
  warn "User Auth Test (Failed case, give wrong auth/cancel the auth dialog)"
  authenticateUser >>= either (show >>> append "Result: " >>> warn) (const $ error "Authentication success.. this shouldn't happen!")

encryptionTest :: Aff Unit
encryptionTest = do
  let
    encryptData = "Im a test"
    key = KeyAlias "myKey"
  encryptResult <- secureEncrypt encryptData key false
  case encryptResult of
    Left e -> error $ "encrypt error: " <> show e
    Right cipher -> do
      warn $ "Encryption successful: " <> show cipher
      secureDecrypt cipher key false >>= either (show >>> append "decrypt error: " >>> error) (\d -> if d == encryptData then warn "Decryption Successful" else error ("Incorrect decrypt: " <> d))

authEncryptionTest :: Aff Unit
authEncryptionTest = do
  let
    authedKey = KeyAlias "authedKey"
    encryptData = "Im a test"
  authedEncryptResult <- secureEncrypt encryptData authedKey true
  case authedEncryptResult of
    Left e -> error $ "authed encrypt error: " <> show e
    Right cipher -> do
      warn $ "Authed Encryption successful" <> show cipher
      secureDecrypt cipher authedKey true >>= either (show >>> append "authed decrypt error: " >>> error) (\d -> if d == encryptData then warn "Authed Decryption Successful" else error ("Incorrect authed decrypt: " <> d))
