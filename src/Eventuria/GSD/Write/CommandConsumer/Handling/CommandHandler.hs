{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE NamedFieldPuns #-}
module Eventuria.GSD.Write.CommandConsumer.Handling.CommandHandler (commandHandler) where


import           Eventuria.Libraries.PersistedStreamEngine.Interface.PersistedItem

import           Eventuria.Libraries.CQRS.Write.CommandConsumption.Handling.CommandHandler
import           Eventuria.Libraries.CQRS.Write.CommandConsumption.Handling.ResponseDSL
import           Eventuria.Libraries.CQRS.Write.Aggregate.Commands.ValidationStates.ValidationState

import           Eventuria.GSD.Write.Model.State
import           Eventuria.GSD.Write.Model.Commands.Command
import           Eventuria.GSD.Write.CommandConsumer.Handling.CommandPredicates

import qualified Eventuria.GSD.Write.CommandConsumer.Handling.Commands.CreateWorkspace          as CreateWorkspace
import qualified Eventuria.GSD.Write.CommandConsumer.Handling.Commands.RenameWorkspace          as RenameWorkspace
import qualified Eventuria.GSD.Write.CommandConsumer.Handling.Commands.SetGoal                  as SetGoal
import qualified Eventuria.GSD.Write.CommandConsumer.Handling.Commands.RefineGoalDescription    as RefineGoalDescription
import qualified Eventuria.GSD.Write.CommandConsumer.Handling.Commands.StartWorkingOnGoal       as StartWorkingOnGoal
import qualified Eventuria.GSD.Write.CommandConsumer.Handling.Commands.PauseWorkingOnGoal       as PauseWorkingOnGoal
import qualified Eventuria.GSD.Write.CommandConsumer.Handling.Commands.NotifyGoalAccomplishment as NotifyGoalAccomplishment
import qualified Eventuria.GSD.Write.CommandConsumer.Handling.Commands.GiveUpOnGoal             as GiveUpOnGoal
import qualified Eventuria.GSD.Write.CommandConsumer.Handling.Commands.ActionizeOnGoal          as ActionizeOnGoal
import qualified Eventuria.GSD.Write.CommandConsumer.Handling.Commands.NotifyActionCompleted    as NotifyActionCompleted

import Eventuria.Libraries.PersistedStreamEngine.Interface.Offset

type GSDCommandHandler = Offset ->
                         GsdCommand ->
                         Maybe (ValidationState GsdState) ->
                         CommandHandlingResponse GsdState

commandHandler :: CommandHandler GsdState
commandHandler persistedCommand @ PersistedItem {offset , item = command }
               snapshotMaybe
  | isAlreadyProcessed offset snapshotMaybe = SkipCommandBecauseAlreadyProcessed
  | (isFirstCommand offset) && (not . isCreateWorkspaceCommand) command = RejectCommand "CreateWorkspace should be the first command"
  | otherwise =   gsdCommandHandler offset (fromCommand command)  snapshotMaybe

gsdCommandHandler :: GSDCommandHandler
gsdCommandHandler
        offset
        gsdCommand
        snapshotMaybe =
  case (snapshotMaybe, gsdCommand) of
     (Nothing      ,CreateWorkspace          {commandId, workspaceId, workspaceName})                   -> CreateWorkspace.handle          offset commandId workspaceId workspaceName
     (Just snapshot,RenameWorkspace          {commandId, workspaceId, workspaceNewName})                -> RenameWorkspace.handle          offset snapshot commandId workspaceId workspaceNewName
     (Just snapshot,SetGoal                  {commandId, workspaceId, goalId, goalDescription})         -> SetGoal.handle                  offset snapshot commandId workspaceId goalId goalDescription
     (Just snapshot,RefineGoalDescription    {commandId, workspaceId, goalId, refinedGoalDescription})  -> RefineGoalDescription.handle    offset snapshot commandId workspaceId goalId refinedGoalDescription
     (Just snapshot,StartWorkingOnGoal       {commandId, workspaceId, goalId})                          -> StartWorkingOnGoal.handle       offset snapshot commandId workspaceId goalId
     (Just snapshot,PauseWorkingOnGoal       {commandId, workspaceId, goalId})                          -> PauseWorkingOnGoal.handle       offset snapshot commandId workspaceId goalId
     (Just snapshot,NotifyGoalAccomplishment {commandId, workspaceId, goalId})                          -> NotifyGoalAccomplishment.handle offset snapshot commandId workspaceId goalId
     (Just snapshot,GiveUpOnGoal             {commandId, workspaceId, goalId, reason})                  -> GiveUpOnGoal.handle             offset snapshot commandId workspaceId goalId reason
     (Just snapshot,ActionizeOnGoal          {commandId, workspaceId, goalId, actionId, actionDetails}) -> ActionizeOnGoal.handle          offset snapshot commandId workspaceId goalId actionId actionDetails
     (Just snapshot,NotifyActionCompleted    {commandId, workspaceId, goalId, actionId})                -> NotifyActionCompleted.handle    offset snapshot commandId workspaceId goalId actionId
     (_            ,_)                                                                                  -> RejectCommand "Scenario not handle"






