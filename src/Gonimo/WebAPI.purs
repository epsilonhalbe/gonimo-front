-- File auto generated by servant-purescript! --
module Gonimo.WebAPI where

import Prelude

import Control.Monad.Aff.Class (class MonadAff, liftAff)
import Control.Monad.Error.Class (class MonadError)
import Control.Monad.Reader.Class (ask, class MonadReader)
import Data.Argonaut.Generic.Aeson (decodeJson, encodeJson)
import Data.Argonaut.Printer (printJson)
import Data.Maybe (Maybe, Maybe(..))
import Data.Nullable (Nullable(), toNullable)
import Data.Tuple (Tuple)
import Global (encodeURIComponent)
import Gonimo.Server.Db.Entities (Account, Device, Family, Invitation)
import Gonimo.Server.State.Types (MessageNumber, SessionId)
import Gonimo.Server.Types (AuthToken, Coffee, DeviceType)
import Gonimo.Types (Key, Secret)
import Gonimo.WebAPI.Types (AuthData, DeviceInfo, InvitationInfo, InvitationReply, SendInvitation)
import Network.HTTP.Affjax (AJAX)
import Prelude (Unit)
import Prim (Array, String)
import Servant.PureScript.Affjax (AjaxError(..), affjax, defaultRequest)
import Servant.PureScript.Settings (SPSettings_(..), gDefaultToURLPiece)
import Servant.PureScript.Util (encodeHeader, encodeListQuery, encodeQueryItem, encodeURLPiece, getResult)

newtype SPParams_ = SPParams_ { authorization :: AuthToken
                              , baseURL :: String
                              }

postAccounts :: forall eff m.
                (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                => m AuthData
postAccounts = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let baseURL = spParams_.baseURL
  let httpMethod = "POST"
  let reqUrl = baseURL <> "accounts"
  let reqHeaders =
        []
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
postInvitationsByFamilyId :: forall eff m.
                             (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                             => Key Family
                             -> m (Tuple (Key Invitation) Invitation)
postInvitationsByFamilyId familyId = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "POST"
  let reqUrl = baseURL <> "invitations"
        <> "/" <> encodeURLPiece spOpts_' familyId
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
deleteInvitationsByInvitationSecret :: forall eff m.
                                       (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                                       => InvitationReply -> Secret
                                       -> m (Maybe (Key Family))
deleteInvitationsByInvitationSecret reqBody invitationSecret = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "DELETE"
  let reqUrl = baseURL <> "invitations"
        <> "/" <> encodeURLPiece spOpts_' invitationSecret
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 , content = toNullable <<< Just <<< printJson <<< encodeJson $ reqBody
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
postInvitationsOutbox :: forall eff m.
                         (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                         => SendInvitation -> m Unit
postInvitationsOutbox reqBody = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "POST"
  let reqUrl = baseURL <> "invitations" <> "/" <> "outbox"
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 , content = toNullable <<< Just <<< printJson <<< encodeJson $ reqBody
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
putInvitationsInfoByInvitationSecret :: forall eff m.
                                        (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                                        => Secret -> m InvitationInfo
putInvitationsInfoByInvitationSecret invitationSecret = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "PUT"
  let reqUrl = baseURL <> "invitations" <> "/" <> "info"
        <> "/" <> encodeURLPiece spOpts_' invitationSecret
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
getAccountsByAccountIdFamilies :: forall eff m.
                                  (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                                  => Key Account -> m (Array (Key Family))
getAccountsByAccountIdFamilies accountId = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "GET"
  let reqUrl = baseURL <> "accounts" <> "/" <> encodeURLPiece spOpts_' accountId
        <> "/" <> "families"
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
postFamilies :: forall eff m.
                (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                => m (Key Family)
postFamilies = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "POST"
  let reqUrl = baseURL <> "families"
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
getFamiliesByFamilyId :: forall eff m.
                         (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                         => Key Family -> m Family
getFamiliesByFamilyId familyId = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "GET"
  let reqUrl = baseURL <> "families" <> "/" <> encodeURLPiece spOpts_' familyId
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
getFamiliesByFamilyIdDeviceInfos :: forall eff m.
                                    (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                                    => Key Family
                                    -> m (Array (Tuple (Key Device) DeviceInfo))
getFamiliesByFamilyIdDeviceInfos familyId = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "GET"
  let reqUrl = baseURL <> "families" <> "/" <> encodeURLPiece spOpts_' familyId
        <> "/" <> "deviceInfos"
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
postSocketByFamilyIdByToDevice :: forall eff m.
                                  (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                                  => Key Device -> Key Family -> Key Device
                                  -> m Secret
postSocketByFamilyIdByToDevice reqBody familyId toDevice = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "POST"
  let reqUrl = baseURL <> "socket" <> "/" <> encodeURLPiece spOpts_' familyId
        <> "/" <> encodeURLPiece spOpts_' toDevice
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 , content = toNullable <<< Just <<< printJson <<< encodeJson $ reqBody
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
getSocketByFamilyIdByToDevice :: forall eff m.
                                 (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                                 => Key Family -> Key Device
                                 -> m (Maybe (Tuple (Key Device) Secret))
getSocketByFamilyIdByToDevice familyId toDevice = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "GET"
  let reqUrl = baseURL <> "socket" <> "/" <> encodeURLPiece spOpts_' familyId
        <> "/" <> encodeURLPiece spOpts_' toDevice
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
deleteSocketByFamilyIdByToDeviceByFromDeviceByChannelId :: forall eff m.
                                                           (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                                                           => Key Family
                                                           -> Key Device
                                                           -> Key Device
                                                           -> Secret -> m Unit
deleteSocketByFamilyIdByToDeviceByFromDeviceByChannelId familyId toDevice
                                                        fromDevice
                                                        channelId = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "DELETE"
  let reqUrl = baseURL <> "socket" <> "/" <> encodeURLPiece spOpts_' familyId
        <> "/" <> encodeURLPiece spOpts_' toDevice
        <> "/" <> encodeURLPiece spOpts_' fromDevice
        <> "/" <> encodeURLPiece spOpts_' channelId
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
putSocketByFamilyIdByFromDeviceByToDeviceByChannelId :: forall eff m.
                                                        (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                                                        => Array String
                                                        -> Key Family
                                                        -> Key Device
                                                        -> Key Device -> Secret
                                                        -> m Unit
putSocketByFamilyIdByFromDeviceByToDeviceByChannelId reqBody familyId fromDevice
                                                     toDevice channelId = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "PUT"
  let reqUrl = baseURL <> "socket" <> "/" <> encodeURLPiece spOpts_' familyId
        <> "/" <> encodeURLPiece spOpts_' fromDevice
        <> "/" <> encodeURLPiece spOpts_' toDevice
        <> "/" <> encodeURLPiece spOpts_' channelId
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 , content = toNullable <<< Just <<< printJson <<< encodeJson $ reqBody
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
getSocketByFamilyIdByFromDeviceByToDeviceByChannelId :: forall eff m.
                                                        (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                                                        => Key Family
                                                        -> Key Device
                                                        -> Key Device -> Secret
                                                        -> m (Maybe (Tuple MessageNumber (Array String)))
getSocketByFamilyIdByFromDeviceByToDeviceByChannelId familyId fromDevice
                                                     toDevice channelId = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "GET"
  let reqUrl = baseURL <> "socket" <> "/" <> encodeURLPiece spOpts_' familyId
        <> "/" <> encodeURLPiece spOpts_' fromDevice
        <> "/" <> encodeURLPiece spOpts_' toDevice
        <> "/" <> encodeURLPiece spOpts_' channelId
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
deleteSocketByFamilyIdByFromDeviceByToDeviceByChannelIdMessagesByMessageNumber :: forall eff m.
                                                                                  (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                                                                                  =>
                                                                                  Key Family
                                                                                  -> Key Device
                                                                                  -> Key Device
                                                                                  -> Secret
                                                                                  -> MessageNumber
                                                                                  -> m Unit
deleteSocketByFamilyIdByFromDeviceByToDeviceByChannelIdMessagesByMessageNumber familyId
                                                                               fromDevice
                                                                               toDevice
                                                                               channelId
                                                                               messageNumber = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "DELETE"
  let reqUrl = baseURL <> "socket" <> "/" <> encodeURLPiece spOpts_' familyId
        <> "/" <> encodeURLPiece spOpts_' fromDevice
        <> "/" <> encodeURLPiece spOpts_' toDevice
        <> "/" <> encodeURLPiece spOpts_' channelId <> "/" <> "messages"
        <> "/" <> encodeURLPiece spOpts_' messageNumber
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
postSessionByFamilyIdByDeviceId :: forall eff m.
                                   (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                                   => DeviceType -> Key Family -> Key Device
                                   -> m SessionId
postSessionByFamilyIdByDeviceId reqBody familyId deviceId = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "POST"
  let reqUrl = baseURL <> "session" <> "/" <> encodeURLPiece spOpts_' familyId
        <> "/" <> encodeURLPiece spOpts_' deviceId
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 , content = toNullable <<< Just <<< printJson <<< encodeJson $ reqBody
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
putSessionByFamilyIdByDeviceIdBySessionId :: forall eff m.
                                             (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                                             => DeviceType -> Key Family
                                             -> Key Device -> SessionId
                                             -> m Unit
putSessionByFamilyIdByDeviceIdBySessionId reqBody familyId deviceId
                                          sessionId = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "PUT"
  let reqUrl = baseURL <> "session" <> "/" <> encodeURLPiece spOpts_' familyId
        <> "/" <> encodeURLPiece spOpts_' deviceId
        <> "/" <> encodeURLPiece spOpts_' sessionId
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 , content = toNullable <<< Just <<< printJson <<< encodeJson $ reqBody
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
deleteSessionByFamilyIdByDeviceIdBySessionId :: forall eff m.
                                                (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                                                => Key Family -> Key Device
                                                -> SessionId -> m Unit
deleteSessionByFamilyIdByDeviceIdBySessionId familyId deviceId sessionId = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "DELETE"
  let reqUrl = baseURL <> "session" <> "/" <> encodeURLPiece spOpts_' familyId
        <> "/" <> encodeURLPiece spOpts_' deviceId
        <> "/" <> encodeURLPiece spOpts_' sessionId
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
getSessionByFamilyId :: forall eff m.
                        (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                        => Key Family
                        -> m (Array (Tuple (Key Device) DeviceType))
getSessionByFamilyId familyId = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authorization = spParams_.authorization
  let baseURL = spParams_.baseURL
  let httpMethod = "GET"
  let reqUrl = baseURL <> "session" <> "/" <> encodeURLPiece spOpts_' familyId
  let reqHeaders =
        [{ field : "Authorization" , value : encodeHeader spOpts_' authorization
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
getCoffee :: forall eff m.
             (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
             => m Coffee
getCoffee = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let baseURL = spParams_.baseURL
  let httpMethod = "GET"
  let reqUrl = baseURL <> "coffee"
  let reqHeaders =
        []
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
