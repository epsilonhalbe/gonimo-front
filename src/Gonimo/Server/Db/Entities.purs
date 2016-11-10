-- File auto generated by purescript-bridge! --
module Gonimo.Server.Db.Entities where

import Data.Maybe (Maybe)
import Gonimo.Server.Types (AuthToken, InvitationDelivery)
import Gonimo.Types (Date, Key, Secret)
import Prim (Array, String)

import Data.Generic (class Generic)


data Account =
    Account {
      accountCreated :: Date
    }

derive instance genericAccount :: Generic Account

data Device =
    Device {
      deviceName :: String
    , deviceAuthToken :: AuthToken
    , deviceAccountId :: Key Account
    , deviceLastAccessed :: Date
    , deviceUserAgent :: String
    }

derive instance genericDevice :: Generic Device

data Invitation =
    Invitation {
      invitationSecret :: Secret
    , invitationFamilyId :: Key Family
    , invitationCreated :: Date
    , invitationDelivery :: InvitationDelivery
    , invitationSenderId :: Key Device
    , invitationReceiverId :: Maybe (Key Account)
    }

derive instance genericInvitation :: Generic Invitation

data Family =
    Family {
      familyName :: String
    , familyCreated :: Date
    , familyLastAccessed :: Date
    , familyLastUsedBabyNames :: Array String
    }

derive instance genericFamily :: Generic Family
