module Plugin.Home.UI.AddAccount where

import Prelude

import App ((<|>))
import App.Interface.Events (Event(..), on)
import App.Plugin.UI (modifyState, wait)
import Data.Maybe (Maybe(..))
import Effect.Aff (Aff)
import Plugin.Home.UI.HomeScreen (HomeScreenEvent(..), HomeScreenUi, _dialogs, _inputsDialog, _selectorDialog, _visible)
import Record (modify, set)

exitAddAccount :: HomeScreenUi -> Aff Unit
exitAddAccount ui =
  modifyState ui $ modify _dialogs (modify _selectorDialog (set _visible false))

addAccountClicked :: HomeScreenEvent -> Maybe Unit
addAccountClicked AddAccountClick = Just unit
addAccountClicked _ = Nothing

serviceSelected :: HomeScreenEvent -> Maybe String
serviceSelected (SelectorDialog service) = Just service
serviceSelected _ = Nothing

inputsDialogRendered :: HomeScreenEvent -> Maybe String
inputsDialogRendered (InputsDialogRendered id) = Just id
inputsDialogRendered _ = Nothing


selectService :: HomeScreenUi -> Aff Unit
selectService ui = on BackPressed (exitAddAccount ui) <|> do
  modifyState ui $ modify _dialogs (set _selectorDialog {
    visible: true
  , title: ""
  , label: "Select a Service..."
  , options: ["HDFC", "ICICI"]
  })
  service <- wait ui serviceSelected
  modifyState ui $ modify _dialogs (
    modify _selectorDialog (set _visible false) >>>
    set _inputsDialog {
      visible: true
    , serviceName: service
    })
  serviceInputs ui service

serviceInputs :: HomeScreenUi -> String -> Aff Unit
serviceInputs ui service = on BackPressed (selectService ui) <|> do
  modifyState ui $ modify _dialogs (
    modify _selectorDialog (set _visible false) >>>
    set _inputsDialog {
      visible: true
    , serviceName: service
    })
  divId <- wait ui inputsDialogRendered
  pure unit
