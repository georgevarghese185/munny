module App where

import Prelude

import Control.Parallel (parallel, sequential)
import Data.Foldable (oneOf)
import Effect.Aff (Aff)

appName :: String
appName = "Munny"

orAff :: forall a. Aff a -> Aff a -> Aff a
orAff aff1 aff2 = sequential $ oneOf [parallel aff1, parallel aff2]

infixl 1 orAff as <|>
