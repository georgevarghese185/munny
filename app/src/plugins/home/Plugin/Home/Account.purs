module Plugin.Home.Account where

import Prelude

import App.Interface.Storage (getWith, store)
import Data.Array (catMaybes)
import Data.DateTime (DateTime)
import Data.Either (Either(..), either)
import Data.JSDate (fromDateTime, parse, toDateTime, toISOString)
import Data.List.NonEmpty (singleton)
import Data.Maybe (Maybe(..), maybe)
import Data.Traversable (sequence)
import Effect (Effect)
import Effect.Class (class MonadEffect, liftEffect)
import Effect.Class.Console (errorShow)
import Foreign (ForeignError(..), MultipleErrors)
import Plugin.Home.Keys as Keys
import Simple.JSON (readJSON, writeJSON)

type AccountSummary = {
  sectionName :: String
, sectionValue :: String
, details :: Array {
    name :: String
  , value :: String
  }
}

type Account = {
  name :: String
, serviceName :: String
, serviceSettings :: String
, summary :: Array AccountSummary
, lastUpdated :: Maybe DateTime
}


getAccounts :: forall m. MonadEffect m => m (Array Account)
getAccounts = liftEffect do
  accounts <- (join >>> maybe [] identity) <$> (logError =<< getWith readJSON Keys.accounts)
  catMaybes <$> (
    sequence $ accounts <#> \a ->
      readLastUpdated a.lastUpdated >>=
        either
        (\e -> errorShow e *> pure Nothing)
        (\lu -> pure $ Just $ a {lastUpdated = lu})
  )

saveAccounts :: forall m. MonadEffect m => (Array Account) -> m Unit
saveAccounts accounts = liftEffect do
  accounts' <- sequence $ accounts <#> \a ->
    writeLastUpdated a.lastUpdated >>= (\lu -> pure $ a {lastUpdated = lu})
  store Keys.accounts (writeJSON accounts')

readLastUpdated :: Maybe String -> Effect (Either MultipleErrors (Maybe DateTime))
readLastUpdated (Just s) =
  maybe (Left $ singleton $ ForeignError "Invalid Date") (Just >>> Right) <$> toDateTime <$> parse s
readLastUpdated Nothing = pure $ Right Nothing

writeLastUpdated :: Maybe DateTime -> Effect (Maybe String)
writeLastUpdated (Just d) = Just <$> toISOString (fromDateTime d)
writeLastUpdated Nothing = pure Nothing

logError :: forall a. Either MultipleErrors a -> Effect (Maybe a)
logError = either (errorShow >=> const (pure Nothing)) (Just >>> pure)
