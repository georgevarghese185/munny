module Plugin.Home.Keys where

import Prelude

serviceSettings :: String -> String
serviceSettings serviceName = serviceName <> "_settings"

serviceEncryptMethod :: String -> String
serviceEncryptMethod serviceName = serviceName <> "_encrypt_method"
