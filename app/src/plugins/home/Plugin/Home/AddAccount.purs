module Plugin.Home.AddAccount (
    addAccount
  ) where

import Prelude

import App ((<|>))
import App.Interface.Events (Event(..), on)
import App.Interface.SecureDevice (DeviceSecureStatus(..), KeyAlias(..), isDeviceSecure, secureEncrypt)
import App.Interface.Storage (store)
import App.Plugin (loadPlugin)
import App.Plugin.UI (wait)
import Control.Monad.Except (ExceptT, lift, runExceptT, throwError)
import Data.Bifunctor (bimap)
import Data.Either (Either(..), either)
import Data.Maybe (Maybe(..))
import Effect.Aff (Aff, Error, try)
import Effect.Aff as E
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Foreign (Foreign)
import Foreign.Generic (encodeJSON)
import Node.Crypto.Cipher (Algorithm(..))
import Node.Crypto.Cipher as Cipher
import Plugin.Home.Keys as Keys
import Plugin.Home.UI.HomeScreen (HomeScreenUi)
import Plugin.Home.UI.HomeScreen as Events
import Plugin.Home.UI.HomeScreen as UI
import Simple.JSON (write)

data EncryptionMethod =
    ScreenLock
  | Pin
  | Password
  | System

toUiString :: EncryptionMethod -> String
toUiString ScreenLock = "Encrypt using my screen lock"
toUiString Pin = "Encrypt with a PIN"
toUiString Password = "Encrypt with a password"
toUiString System = "Encrypt with a system key (insecure)"

fromUiString :: String -> Maybe EncryptionMethod
fromUiString "Encrypt using my screen lock" = Just ScreenLock
fromUiString "Encrypt with a PIN" = Just Pin
fromUiString "Encrypt with a password" = Just Password
fromUiString "Encrypt with a system key (insecure)" = Just System
fromUiString _ = Nothing

backable :: forall a. ExceptT (Aff a) Aff a -> Aff a
backable fn = runExceptT fn >>= either identity pure

onBack :: forall a b. Aff a -> ExceptT (Aff a) Aff b
onBack fn = lift (on BackPressed $ pure fn) >>= throwError

addAccount :: HomeScreenUi -> Array String -> Aff Unit
addAccount ui services = backable do
  lift $ UI.showSelectorDialog ui "" "Select a Service..." services
  service <- lift (wait ui Events.serviceSelected) <|> onBack (log "back pressed" *> UI.hideSelectorDialog ui)
  lift $ UI.hideSelectorDialog ui
  lift $ serviceInputs ui (addAccount ui services) service

serviceInputs :: HomeScreenUi -> (Aff Unit) -> String -> Aff Unit
serviceInputs ui back serviceName = backable do
  lift $ UI.showInputsDialog ui serviceName
  divId <- lift (wait ui Events.inputsDialogRendered) <|> onBack (UI.hideInputsDialog ui *> back)
  let inputs = write {inputs: {ui: divId}, outputs: ["serviceAccountSettings"]}
  let getSettings = either throwError pure =<< runExceptT (loadPlugin serviceName inputs)
  serviceSettings <- lift getSettings <|> onBack (UI.hideInputsDialog ui *> back)
  lift $ UI.hideInputsDialog ui
  lift $ encryptSettings ui (serviceInputs ui back serviceName) serviceSettings serviceName

encryptSettings :: HomeScreenUi -> (Aff Unit) -> Foreign -> String -> Aff Unit
encryptSettings ui back serviceSettings serviceName = backable do
  encryptOptions <- lift $ isDeviceSecure >>= case _ of
    Secure -> pure [ScreenLock, Pin, Password, System]
    Insecure -> pure [Pin, Password, System]
    _ -> pure [Pin, Password]
  lift $ UI.showEncryptDialog ui (toUiString <$> encryptOptions)
  encryptionMethodSelected <- lift (wait ui (Events.encryptOptionSelected >=> fromUiString)) <|> onBack (UI.hideEncryptDialog ui *> back)
  lift $ UI.hideEncryptDialog ui
  let chooseAgain = encryptSettings ui back serviceSettings serviceName
  encryptFn <- case encryptionMethodSelected of
    ScreenLock -> do
      lift $ UI.showSimpleDialog ui "Please authenticate the next screen"
      lift (wait ui Events.okClicked) <|> onBack (UI.hideSimpleDialog ui *> chooseAgain)
      lift $ UI.hideSimpleDialog ui
      pure $ encryptWithScreenLock serviceName
    System -> do
      lift $ UI.showSimpleDialog ui "Please authenticate the next screen"
      lift (wait ui Events.okClicked) <|> onBack (UI.hideSimpleDialog ui *> chooseAgain)
      lift $ UI.hideSimpleDialog ui
      pure $ encryptWithSystemKey serviceName
    Pin -> do
      lift $ UI.showPasswordDialog ui "Provide a password for encrypting your inputs" true
      password <- lift (wait ui Events.passwordEntered) <|> onBack (UI.hidePasswordDialog ui *> chooseAgain)
      lift $ UI.hidePasswordDialog ui
      pure $ encryptWithPassword password
    Password -> do
      lift $ UI.showPasswordDialog ui "Provide a password for encrypting your inputs" false
      password <- lift (wait ui Events.passwordEntered) <|> onBack (UI.hidePasswordDialog ui *> chooseAgain)
      lift $ UI.hidePasswordDialog ui
      pure $ encryptWithSystemKey password
  encryptedSettings <- lift $ encryptFn $ encodeJSON serviceSettings
  case encryptedSettings of
    Right s -> do
      lift $ store (Keys.serviceSettings serviceName) (encodeJSON s)
      lift $ UI.showSimpleDialog ui "Account added"
      lift (wait ui Events.okClicked)
      lift $ UI.hideSimpleDialog ui
    Left e -> do
      lift $ UI.showSimpleDialog ui ("Error while encrypting: " <> E.message e)
      lift $ (wait ui Events.okClicked)
      lift $ UI.hideSimpleDialog ui
  pure unit

encryptWithScreenLock :: String -> String -> Aff (Either Error String)
encryptWithScreenLock  serviceName data' =
  bimap (show >>> E.error) encodeJSON <$>
  secureEncrypt data' (KeyAlias $ Keys.serviceSettings serviceName) true

encryptWithSystemKey :: String -> String -> Aff (Either Error String)
encryptWithSystemKey serviceName data' =
  bimap (show >>> E.error) encodeJSON <$>
  secureEncrypt data' (KeyAlias $ Keys.serviceSettings serviceName) false

encryptWithPassword :: String -> String -> Aff (Either Error String)
encryptWithPassword password data' =
  try $ liftEffect $ Cipher.base64 AES256 password data'
