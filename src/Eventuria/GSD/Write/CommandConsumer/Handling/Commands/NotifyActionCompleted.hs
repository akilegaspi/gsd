{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DataKinds #-}
module Eventuria.GSD.Write.CommandConsumer.Handling.Commands.NotifyActionCompleted where

import qualified Data.Set as Set
import qualified Data.UUID.V4 as Uuid
import qualified Data.Time as Time
import           Data.List hiding (union)
                 
import           Eventuria.Libraries.PersistedStreamEngine.Interface.Offset
                 
import           Eventuria.Libraries.CQRS.Write.CommandConsumption.Handling.CommandHandler
import           Eventuria.Libraries.CQRS.Write.Aggregate.Commands.CommandId
                 
import           Eventuria.GSD.Write.Model.Events.Event
import           Eventuria.GSD.Write.Model.WriteModel
import           Eventuria.GSD.Write.Model.Core


handle :: Offset ->
          GsdWriteModel ->
          CommandId ->
          WorkspaceId ->
          GoalId ->
          ActionId ->
          IO (CommandHandlerResult GsdWriteModel)
handle offset
       writeModel @ GsdWriteModel {goals}
       commandId
       workspaceId
       goalId
       actionId =
  case (findGoal goalId goals)  of
    Nothing -> return $ rejectCommand (Just writeModel) "Trying to notify an action completion on a goal that does not exist"
    Just goal @ Goal {workspaceId,goalId, actions,  description,status} ->
      case (findAction actionId actions)  of
        Nothing -> return $ rejectCommand (Just writeModel) "Trying to notify an action completion on a action that does not exist"
        Just action @ Action {actionId,index,details,status}  ->
          case status of
            Completed -> return $ rejectCommand (Just writeModel) "Trying to notify an action completion on a action already completed"
            Initiated -> do
               createdOn <- Time.getCurrentTime
               eventId <- Uuid.nextRandom
               return $ validateCommand
                            GsdWriteModel {goals = updateGoal goals (updateActions
                                                                        goal
                                                                        Action {actionId,
                                                                                index,
                                                                                details,
                                                                                status = Completed})}
                            [toEvent $ ActionCompleted {
                                               eventId ,
                                               createdOn,
                                               workspaceId ,
                                               goalId ,
                                               actionId}]

  where
      findGoal :: GoalId -> [Goal] -> Maybe Goal
      findGoal  goalIdToFind goals = find (\Goal{goalId} -> goalIdToFind == goalId ) goals

      findAction :: ActionId -> Set.Set Action -> Maybe Action
      findAction  actionIdToFind actions = find (\Action{actionId} -> actionIdToFind == actionId ) actions

      updateActionStatus :: ActionId -> ActionStatus -> Set.Set Action -> Set.Set Action
      updateActionStatus actionIdToUpdate newGoalStatus actions =
        Set.map (\action@Action{actionId, details,index } -> case (actionIdToUpdate == actionId) of
          True -> Action{actionId,details,index, status = Completed}
          False -> action
        ) $ actions

      updateGoal :: [Goal] -> Goal -> [Goal]
      updateGoal goals updatedGoal@Goal{goalId = goalIdToUpdate} =
        map (\goal@Goal{goalId} -> case (goalId == goalIdToUpdate) of
          True -> updatedGoal
          False -> goal
        ) $ goals

      updateActions :: Goal -> Action -> Goal
      updateActions Goal{workspaceId,goalId,description,status,actions} updatedAction @ Action {actionId = actionIdToUpdate} =
        Goal {workspaceId,goalId,description,status,
              actions = Set.map (\action@Action{actionId} -> case (actionId == actionIdToUpdate) of
                                  True -> updatedAction
                                  False -> action
                                ) $ actions}

