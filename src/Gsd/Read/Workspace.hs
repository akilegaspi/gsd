{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE DuplicateRecordFields #-}
module Gsd.Read.Workspace where

import Gsd.Write.Core
import Data.Aeson
import Data.Text
import Gsd.Read.GoalStats

type WorkspaceName = Text
data Workspace = Workspace { workspaceId :: WorkspaceId , workspaceName :: WorkspaceName , goalStats :: GoalStats} deriving Show

instance ToJSON Workspace where
  toJSON (Workspace {workspaceId, workspaceName ,goalStats } ) = object [
            "workspaceId" .= workspaceId,
            "workspaceName" .= workspaceName,
            "goalStats" .= goalStats]

instance FromJSON Workspace  where

    parseJSON (Object jsonObject) = Workspace <$> jsonObject .: "workspaceId" <*>  jsonObject .: "workspaceName" <*>  jsonObject .: "goalStats"
    parseJSON _ =  error $ "Json format not expected"


