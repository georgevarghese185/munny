module App where


import Control.Alternative (class Alternative)
import Control.Parallel (class Parallel, parOneOf)

appName :: String
appName = "Munny"

parallel :: forall f m a. Parallel f m => Alternative f => m a -> m a -> m a
parallel f1 f2 = parOneOf [f1, f2]

infixl 1 parallel as <|>
