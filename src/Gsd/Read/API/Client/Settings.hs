{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE RecordWildCards #-}
module Gsd.Read.API.Client.Settings where

import Logger.Core
import Network.Core

data Settings = Settings {loggerId :: LoggerId , url :: URL}