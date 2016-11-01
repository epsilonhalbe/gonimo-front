module Gonimo.UI.Socket.Internal where

import Prelude
import Data.Array as Arr
import Data.Map as Map
import Gonimo.Client.Effects as Console
import Gonimo.UI.Socket.Channel as ChannelC
import Gonimo.UI.Socket.Channel.Types as ChannelC
import Pux.Html.Attributes as A
import Pux.Html.Elements as H
import Pux.Html.Events as E
import WebRTC.MediaStream.Track as Track
import Control.Monad.Aff.Class (liftAff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.IO (IO)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Reader (ask, runReader)
import Control.Monad.Reader.Class (class MonadReader, ask)
import Control.Monad.State.Class (gets, modify, put, get, class MonadState)
import Data.Array (concat, fromFoldable)
import Data.Foldable (foldl)
import Data.Lens (use, to, (^?), (^.), _Just, (.=))
import Data.Map (Map)
import Data.Maybe (isNothing, isJust, maybe, fromMaybe, Maybe(Nothing, Just))
import Data.Monoid (mempty)
import Data.Profunctor (lmap)
import Data.Traversable (traverse_)
import Data.Tuple (uncurry, snd, Tuple(Tuple))
import Gonimo.Client.Types (toIO, Settings)
import Gonimo.Pux (wrapAction, noEffects, runGonimo, Component, liftChild, toParent, ComponentType, makeChildData, ToChild, onlyModify, Update, class MonadComponent)
import Gonimo.Server.DbEntities (Family(Family), Device(Device))
import Gonimo.Server.DbEntities.Helpers (runFamily)
import Gonimo.Types (Secret(Secret), Key(Key))
import Gonimo.UI.Socket.Lenses (streamURL, isAvailable, mediaStream, babyName, currentFamily, localStream, authData, newBabyName)
import Gonimo.UI.Socket.Message (decodeFromString)
import Gonimo.UI.Socket.Types (makeChannelId, toCSecret, toTheirId, ChannelId(ChannelId), channel, Props, State, Action(..))
import Gonimo.WebAPI (postSocketByFamilyIdByToDevice, deleteOnlineStatusByFamilyIdByDeviceId)
import Gonimo.WebAPI.Lenses (deviceId, _AuthData)
import Gonimo.WebAPI.Subscriber (receiveSocketByFamilyIdByToDevice, receiveSocketByFamilyIdByFromDeviceByToDeviceByChannelId)
import Gonimo.WebAPI.Types (AuthData(AuthData))
import Gonimo.WebAPI.Types.Helpers (runAuthData)
import Pux.Html (Html)
import Servant.Subscriber (Subscriptions)
import WebRTC.MediaStream (mediaStreamToBlob, createObjectURL, stopStream, MediaStreamConstraints(MediaStreamConstraints), getUserMedia, MediaStream, getTracks)
import WebRTC.RTC (RTCPeerConnection)

init :: AuthData-> State
init authData' = { authData : authData'
                 , currentFamily : Nothing
                 , channels : Map.empty
                 , isAvailable : false
                 , localStream : Nothing
                 , streamURL : Nothing
                 , babyName : "baby"
                 , newBabyName : "baby"
                 , constraints : MediaStreamConstraints { audio : true, video : true }
                 , previewEnabled : false
                 }

update :: forall ps. Update (Props ps) State Action
update action = case action of
  AcceptConnection channelId'                    -> handleAcceptConnection channelId'
  GetUserMedia                                   -> handleGetUserMedia
  StopUserMedia                                  -> handleStopUserMedia
  EnablePreview onoff                            -> onlyModify $ _ { previewEnabled = onoff }
  AddChannel channelId' cState                   -> do channel channelId' .= Just cState
                                                       updateChannel channelId' ChannelC.InitConnection
  ChannelA channelId' (ChannelC.ReportError err) -> pure [pure $ ReportError err]
  ChannelA channelId' action'                    -> updateChannel channelId' action'
  CloseChannel channelId'                        -> pure [ pure $ ChannelA channelId' ChannelC.CloseConnection
                                                         , pure $ RemoveChannel channelId'
                                                         ]
  CloseBabyChannel channelId'                    -> do
    isBabyStation' <- gets (_^?channel channelId' <<< _Just <<< to _.isBabyStation)
    case isBabyStation' of
         Just true                               -> pure $ wrapAction (CloseChannel channelId')
         _                                       -> pure []
  RemoveChannel channelId'                       -> channel channelId' .= Nothing
                                                    *> pure []
  SwitchFamily familyId'                       -> handleFamilySwitch familyId'
  ServerFamilyGoOffline familyId               -> handleServerFamilyGoOffline familyId
  SetAuthData auth                             -> handleSetAuthData auth
  StartBabyStation                             -> handleStartBabyStation
  InitBabyStation stream                       -> handleInitBabyStation stream
  SetStreamURL url                             -> streamURL .= url -- TODO: On Nothing we should free the url.
                                                  *> pure []

  SetBabyName name                               -> babyName .= name *> pure []
  SetNewBabyName name                            -> do
    newBabyName .= name
    babyName .= name
    pure []
  ConnectToBaby babyId                         -> handleConnectToBaby babyId
  StopBabyStation                                -> handleStopBabyStation
  ReportError _                                -> noEffects
  Nop                                            -> noEffects



toChannel :: forall ps. ChannelId -> ToChild (Props ps) State (ChannelC.Props {}) ChannelC.State
toChannel channelId' = do
  state <- get
  pProps <- ask
  let
    props :: ChannelC.Props {}
    props = mkChannelProps pProps state channelId'
  pure $ makeChildData (channel channelId' <<< _Just) props

handleGetUserMedia :: forall ps. ComponentType (Props ps) State Action
handleGetUserMedia = do
  state <- get :: Component (Props ps) State State
  case state.localStream of
    Nothing -> runGonimo $
        InitBabyStation <$> liftAff (getUserMedia state.constraints)
    Just _ -> pure []

handleStopUserMedia :: forall ps. ComponentType (Props ps) State Action
handleStopUserMedia = do
  state <- get :: Component (Props ps) State State
  let stream' = if state.isAvailable
                then Nothing
                else state.localStream
  case stream' of
    Nothing -> pure []
    Just stream' -> do
      localStream .= Nothing :: (Maybe MediaStream)
      pure [ do
                liftEff $ stopStream stream'
                pure Nop
           ]

handleStartBabyStation :: forall ps. ComponentType (Props ps) State Action
handleStartBabyStation = do
  state <- get :: Component (Props ps) State State
  if isJust state.localStream
    then isAvailable .= true
    else isAvailable .= false
  noEffects

handleInitBabyStation :: forall ps.
                          MediaStream
                       -> ComponentType (Props ps) State Action
handleInitBabyStation stream = do
  localStream .= Just stream
  pure [ do
            url <- liftEff <<< createObjectURL <<< mediaStreamToBlob $ stream
            pure $ SetStreamURL (Just url)
       ]

handleAcceptConnection :: forall ps. ChannelId -> ComponentType (Props ps) State  Action
handleAcceptConnection channelId' = do
  state <- get
  if state.isAvailable
    then pure [ AddChannel channelId' <$> ChannelC.init state.localStream ]
    else pure []


handleFamilySwitch :: forall ps. Key Family -> ComponentType (Props ps) State Action
handleFamilySwitch familyId' = do
    state <- get :: Component (Props ps) State State
    let oldFamily = state.currentFamily
    modify $ _ { currentFamily = Just familyId' }
    let action = fromFoldable
                 $ pure <<< ServerFamilyGoOffline
                 <$> oldFamily
    pure $ doCleanup state CloseChannel action

handleSetAuthData :: forall ps. AuthData -> ComponentType (Props ps) State Action
handleSetAuthData auth = do
  state <- get
  authData .= auth
  pure $ doCleanup state CloseChannel []

handleStopBabyStation :: forall ps. ComponentType (Props ps) State Action
handleStopBabyStation = do
  state <- get :: Component (Props ps) State State
  props <- ask :: Component (Props ps) State (Props ps)
  isAvailable .= false
  pure $ doCleanup state CloseBabyChannel []

handleServerFamilyGoOffline :: forall ps. Key Family -> ComponentType (Props ps) State Action
handleServerFamilyGoOffline familyId = do
    state <- get
    let deviceId = (runAuthData state.authData).deviceId
    runGonimo $ do
      deleteOnlineStatusByFamilyIdByDeviceId familyId deviceId
      pure Nop

handleConnectToBaby :: forall ps. Key Device -> ComponentType (Props ps) State Action
handleConnectToBaby babyId = do
  state <- get
  props <- ask
  let ourId = state ^. authData <<< to runAuthData <<< deviceId
  let actions = fromMaybe [] $ do
        familyId <- state.currentFamily
        pure [ toIO props.settings $ do
                  secret <- postSocketByFamilyIdByToDevice ourId familyId babyId
                  let channelId' = makeChannelId babyId secret
                  AddChannel channelId' <$> liftIO (ChannelC.init Nothing)
             ]
  pure actions

updateChannel :: forall ps. ChannelId -> ChannelC.Action -> ComponentType (Props ps) State Action
updateChannel channelId' = toParent [] (ChannelA channelId')
                           <<< liftChild (toChannel channelId')
                           <<< ChannelC.update

doCleanup :: State -> (ChannelId -> Action) -> Array (IO Action) -> Array (IO Action)
doCleanup state cleanup action =
    if Map.isEmpty state.channels
    then action
    else Arr.fromFoldable (pure <<< cleanup <$> Map.keys state.channels)
         <> action

getParentChannels :: State -> Array (Tuple ChannelId ChannelC.State)
getParentChannels =  Arr.filter (not _.isBabyStation <<< snd ) <<< Arr.fromFoldable
                     <<< Map.toList <<< _.channels

getSubscriptions :: forall ps. Props ps -> State -> Subscriptions Action
getSubscriptions props state =
  let
    authData' = state ^. authData <<< to runAuthData
    familyId' = state ^. currentFamily
    receiveAChannel deviceId' familyId'' =
      receiveSocketByFamilyIdByToDevice
        (maybe Nop (AcceptConnection <<< uncurry makeChannelId ) <<< join)
        familyId''
        deviceId'

    getChannelSubscriptions :: forall m. (MonadReader Settings m)
                                  => ChannelId -> m (Subscriptions Action)
    getChannelSubscriptions channelId' =
      let
        cProps = mkChannelProps props state channelId'
      in
      map (ChannelA channelId') <$> ChannelC.getSubscriptions cProps

    getChannelsSubscriptions :: forall m. (MonadReader Settings m)
                                => Map ChannelId ChannelC.State
                                -> Array (m (Subscriptions Action))
    getChannelsSubscriptions = Arr.fromFoldable <<< map getChannelSubscriptions <<< Map.keys

    subArray :: Array (Subscriptions Action)
    subArray = map (flip runReader props.settings)
                $ getChannelsSubscriptions state.channels
                <> ( if state.isAvailable
                     then fromFoldable $ do
                               familyId'' <- familyId'
                               pure $ receiveAChannel authData'.deviceId familyId''
                     else []
                   )
  in
     foldl append mempty subArray


mkChannelProps :: forall ps. Props ps -> State -> ChannelId -> ChannelC.Props {}
mkChannelProps props state channelId = { ourId : state ^. authData <<< to runAuthData <<< deviceId
                                       , theirId : toTheirId channelId
                                       , cSecret : toCSecret channelId
                                       , familyId : ChannelC.unsafeMakeFamilyId state.currentFamily
                                       , settings : props.settings
                                       , sendAction : lmap (ChannelA channelId) props.sendActionSocket
                                       , onlineDevices : props.onlineDevices
                                       }