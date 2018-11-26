{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
module Cqrs.Aggregate.Events.Event where

import Cqrs.Aggregate.Ids.AggregateId
import Cqrs.Aggregate.Events.EventId
import Data.Aeson
import Data.Text
import Data.Time
import Cqrs.Aggregate.Core

type Pair = (Text, Value)
type EventName = String

data Event = Event { eventHeader :: EventHeader,
                     payload :: EventPayload}

data EventHeader =  EventHeader { aggregateId :: AggregateId,
                             eventId :: EventId ,
                             createdOn :: UTCTime ,
                             eventName :: EventName}
type EventPayload = [Pair]

instance AggregateJoinable Event where
  getAggregateId Event { eventHeader = EventHeader {aggregateId = aggregateId} } = aggregateId


instance ToJSON Event where
  toJSON (Event {eventHeader = eventHeader , payload = payload  } ) = object [
            "eventHeader" .= eventHeader,
            "payload" .= payload]

instance FromJSON Event where

  parseJSON (Object jsonObject) =
    Event <$> jsonObject .: "eventHeader"
            <*> jsonObject .: "payload"
  parseJSON _ =  error $ "Json format not expected"

instance ToJSON EventHeader where
  toJSON (EventHeader {aggregateId = aggregateId , eventId = eventId , createdOn = createdOn,  eventName = commandName} ) =
    object ["aggregateId" .= aggregateId,
            "eventId" .= eventId,
            "createdOn" .= createdOn,
            "eventName" .= commandName]

instance FromJSON EventHeader where

  parseJSON (Object jsonObject) =
     EventHeader <$> jsonObject .: "aggregateId"
              <*> jsonObject .: "eventId"
              <*> jsonObject .: "createdOn"
              <*> jsonObject .: "eventName"
  parseJSON _ =  error $ "Json format not expected"


