-- TODO: Encapsulation between Loaded and Socket is very very weak! Some parts are here, some parts are there- this should be fixed!
-- | Loaded application ui logic
module Gonimo.UI.Loaded where

import Gonimo.UI.Html
import Data.Array as Arr
import Data.List as List
import Data.Map as Map
import Data.Tuple as Tuple
import Gonimo.Client.Effects as Gonimo
import Gonimo.Client.LocalStorage as Key
import Gonimo.Client.LocalStorage as Key
import Gonimo.Client.Router as Router
import Gonimo.Client.Types as Gonimo
import Gonimo.UI.AcceptInvitation as AcceptC
import Gonimo.UI.Error as Error
import Gonimo.UI.Invite as InviteC
import Gonimo.UI.Overview as OverviewC
import Gonimo.UI.Socket as SocketC
import Gonimo.UI.Socket.Channel as ChannelC
import Gonimo.UI.Socket.Lenses as SocketC
import Gonimo.UI.Socket.Types as SocketC
import Gonimo.WebAPI.MakeRequests as Reqs
import Gonimo.WebAPI.Subscriber as Sub
import Pux.Html as H
import Pux.Html.Attributes as A
import Pux.Html.Attributes.Aria as A
import Pux.Html.Attributes.Bootstrap as A
import Pux.Html.Events as E
import Servant.PureScript.Affjax as Affjax
import Servant.Subscriber as Sub
import Servant.Subscriber.Connection as Sub
import Control.Alt ((<|>))
import Control.Monad.Aff (Aff)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Error.Class (throwError, catchError)
import Control.Monad.Except.Trans (runExceptT)
import Control.Monad.Reader (runReader)
import Control.Monad.Reader.Class (class MonadReader)
import Control.Monad.Reader.Trans (runReaderT)
import Control.Monad.State.Class (gets, get, modify, put)
import DOM.WebStorage.Generic (setItem, getItem, removeItem)
import DOM.WebStorage.Storage (getLocalStorage)
import Data.Argonaut.Generic.Aeson (decodeJson)
import Data.Array (zip, fromFoldable, concat, catMaybes, head)
import Data.Bifunctor (bimap)
import Data.Either (either, Either(Right, Left))
import Data.Foldable (maximumBy, foldl)
import Data.Generic (class Generic)
import Data.Generic (gShow)
import Data.Lens (_Just, (.=), to, (^.), (^?), use)
import Data.Map (Map)
import Data.Maybe (fromMaybe, isNothing, maybe, Maybe(..))
import Data.Monoid (mempty)
import Data.Profunctor (lmap)
import Data.Semigroup (append)
import Data.String (takeWhile)
import Data.Traversable (traverse)
import Data.Tuple (snd, uncurry, fst, Tuple(Tuple))
import Debug.Trace (trace)
import Gonimo.Client.Types (toIO, Settings, GonimoError(AjaxError, RegisterSessionFailed), class ReportErrorAction, Gonimo)
import Gonimo.Pux (noEffects, Component, toParent, runGonimo, liftChild, ComponentType, makeChildData, ToChild, onlyModify, Update, wrapAction)
import Gonimo.Server.Db.Entities (Device(Device), Family(Family))
import Gonimo.Server.Db.Entities.Helpers (runFamily)
import Gonimo.Server.Error (ServerError(InvalidAuthToken))
import Gonimo.Server.Types (DeviceType(Baby, NoBaby), AuthToken, AuthToken(GonimoSecret))
import Gonimo.Server.Types.Lenses (familyName)
import Gonimo.Types (dateToString, Key(Key), Secret(Secret))
import Gonimo.UI.AcceptInvitation (isAccepted)
import Gonimo.UI.Error (handleError, viewError, class ErrorAction, UserError(NoError, DeviceInvalid))
import Gonimo.UI.Loaded.Central (CentralItem, getCentrals)
import Gonimo.UI.Loaded.Types (babiesOnlineCount, CentralReq(..), mkInviteProps, mkSettings, mkProps, central, familyIds, authData, currentFamily, socketS, overviewS, Props, acceptS, inviteS, State, Action(..), Central(..), InviteProps)
import Gonimo.UI.Socket.Lenses (sessionId)
import Gonimo.Util (userShow, toString, fromString)
import Gonimo.WebAPI (getFamiliesByFamilyIdDeviceInfos, postSessionByFamilyIdByDeviceId, postInvitationsByFamilyId, postFamilies, getFamiliesByFamilyId, SPParams_(SPParams_), postAccounts)
import Gonimo.WebAPI.Types (DeviceInfo(DeviceInfo), AuthData(AuthData))
import Gonimo.WebAPI.Types.Helpers (runAuthData)
import Partial.Unsafe (unsafeCrashWith)
import Pux (renderToDOM, fromSimple, start)
import Pux.Html (text, small, script, li, i, a, nav, h3, h2, td, tbody, th, tr, thead, table, ul, p, button, input, h1, span, Html, img, div)
import Pux.Html.Attributes (offset, letterSpacing)
import Pux.Html.Events (FormEvent, FocusEvent)
import Pux.Router (navigateTo)
import Servant.PureScript.Affjax (ErrorDescription(ConnectionError), errorToString, AjaxError)
import Servant.PureScript.Settings (defaultSettings, SPSettings_(SPSettings_))
import Servant.Subscriber (Subscriber)
import Servant.Subscriber.Connection (Notification(WebSocketOpened, HttpRequestFailed, ParseError, WebSocketClosed, WebSocketError))
import Servant.Subscriber.Internal (doDecode, coerceEffects)
import Servant.Subscriber.Request (HttpRequest(HttpRequest))
import Servant.Subscriber.Response (HttpResponse(HttpResponse))
import Servant.Subscriber.Subscriptions (Subscriptions)
import Servant.Subscriber.Util (toUserType)
import Signal (constant, Signal)
import Prelude hiding (div)


update :: Update Unit State Action
update Init                                    = handleInit
update (SetState state)                        = put state *> pure []
update (ReportError err)                       = handleError err
update (InviteA InviteC.GoToOverview)          = handleRequestCentral ReqCentralOverview
update (InviteA InviteC.GoToBabyStation)       = handleRequestCentral ReqCentralBaby
update (InviteA (InviteC.ReportError err))     = handleError err
update (InviteA action)                        = updateInvite action
update (AcceptA AcceptC.GoToBabyStation)       = handleRequestCentral ReqCentralBaby
update (AcceptA (AcceptC.ReportError err))     = handleError err
update (AcceptA action)                        = updateAccept action
update (SocketA a@(SocketC.ReportError err))   = append <$> handleError err <*> updateSocket a
update (SocketA action)                        = updateSocket action
update (OverviewA (OverviewC.SocketA socketA)) = updateSocket socketA
update (OverviewA OverviewC.GoToInviteView)    = handleRequestCentral ReqCentralInvite
update (OverviewA action)                      = updateOverview action
update (SetFamilyIds ids)                      = handleSetFamilyIds ids
update (UpdateFamily familyId' family')        = onlyModify $ \state ->  state { families = Map.insert familyId' family' state.families }
update (RequestCentral c)                      = handleRequestCentral c
update (SetCentral c)                          = handleSetCentral c
update (SetOnlineDevices devices)              = handleSetOnlineDevices devices
update (SetDeviceInfos devices)                = handleSetDeviceInfos devices
update (SetURL url)                            = handleSetURL url
update (HandleSubscriber msg)                  = handleSubscriber msg
update ResetDevice                             = handleResetDevice
update ClearError                              = handleClearError
update Nop                                     = noEffects


toInvite :: ToChild Unit State InviteProps InviteC.State
toInvite = do
  props <- mkInviteProps <$> get
  pure $ makeChildData inviteS props

toAccept :: ToChild Unit State Props AcceptC.State
toAccept = do
  props <- mkProps <$> get
  pure $ makeChildData acceptS props

toOverview :: ToChild Unit State Props OverviewC.State
toOverview = do
  props <- mkProps <$> get
  pure $ makeChildData overviewS props

toSocket :: ToChild Unit State Props SocketC.State
toSocket = do
  props <- mkProps <$> get
  pure $ makeChildData socketS props

updateInvite :: InviteC.Action -> ComponentType Unit State Action
updateInvite iAction = do
  state <- get :: Component Unit State State
  let props = mkInviteProps state
  toParent [] InviteA <<< liftChild toInvite <<< InviteC.update $ iAction


updateAccept :: AcceptC.Action -> ComponentType Unit State Action
updateAccept action = do
  case action of
    AcceptC.EnteredFamily familyId' -> currentFamily .= familyId'
    _                               -> pure unit
  toParent [] AcceptA <<< liftChild toAccept <<< AcceptC.update $ action

updateOverview :: OverviewC.Action -> ComponentType Unit State Action
updateOverview = toParent [] OverviewA <<< liftChild toOverview <<< OverviewC.update

updateSocket :: SocketC.Action -> ComponentType Unit State Action
updateSocket action = do
  case action of
    SocketC.SetAuthData _ -> handleSetAuthData
    _ -> pure unit
  toParent [] SocketA <<< liftChild toSocket $ SocketC.update action

inviteEffect :: forall m. Monad m => Secret -> m Action
inviteEffect = pure <<< AcceptA <<< AcceptC.LoadInvitation


handleInit :: ComponentType Unit State Action
handleInit = pure []

handleSubscriber :: Notification -> ComponentType Unit State Action
handleSubscriber notification = do
  append <$> Error.handleSubscriber notification
         <*> updateSocket (SocketC.HandleSubscriber notification)

handleSetDeviceInfos :: Array (Tuple (Key Device) DeviceInfo) -> ComponentType Unit State Action
handleSetDeviceInfos devices = do
  modify $ _ { deviceInfos = devices }
  if Arr.length devices == 1
    then doAutoSwitchCentral ReqCentralInvite
    else pure []

handleSetOnlineDevices :: Array (Tuple (Key Device) DeviceType) -> ComponentType Unit State Action
handleSetOnlineDevices devices = do
  modify $ _ { onlineDevices = devices }
  let isBaby dev = case dev of
        Baby _ -> true
        _    -> false
  let babies = Arr.filter (isBaby <<< snd) devices
  let babyCount = Arr.length babies
  prevBabyCount <- use babiesOnlineCount
  weAreBaby <- use (socketS<<<to SocketC.toDeviceType <<< to isBaby)
  babiesOnlineCount .= babyCount
  if babyCount > prevBabyCount && not weAreBaby
    then doAutoSwitchCentral ReqCentralOverview
    else pure []

handleResetDevice :: ComponentType Unit State Action
handleResetDevice = do
  props <- mkProps <$> get :: Component Unit State State
  pure $ [ toIO props.settings $ do
              localStorage <- liftEff $ getLocalStorage
              liftEff $ removeItem localStorage Key.authData
              SocketA <<< SocketC.SetAuthData <$> getAuthData
         ]

handleRequestCentral :: CentralReq -> ComponentType Unit State Action
handleRequestCentral c = do
  state <- get
  r <- case c of
    ReqCentralInvite   -> do
      case state^?currentFamily of
        Nothing    -> pure
                   [ toIO (mkSettings $ state^.authData) $ do
                        fid' <- postFamilies
                        invData <- postInvitationsByFamilyId fid'
                        pure <<< SetCentral <<< CentralInvite $ InviteC.init invData
                   ]
        Just fid' -> pure
                   [ toIO (mkSettings $ state^.authData) $ do
                         invData <- postInvitationsByFamilyId fid'
                         pure <<< SetCentral <<< CentralInvite $ InviteC.init invData
                   ]
    ReqCentralOverview -> handleSetCentral CentralOverview
    ReqCentralBaby     -> handleSetCentral CentralBaby
  case Tuple state.central c of
    Tuple CentralBaby ReqCentralBaby -> pure r
    Tuple CentralBaby _              -> pure $ [ pure $ SocketA SocketC.StopUserMedia ] <> r
    Tuple _ _                        -> pure r

handleSetCentral :: Central -> ComponentType Unit State Action
handleSetCentral central' = central .= central' *> noEffects

handleSetAuthData :: Component Unit State Unit
handleSetAuthData = modify $ \state -> state
                                  {
                                   userError = case state.userError of
                                      DeviceInvalid -> NoError
                                      _ -> state.userError
                                  }
handleSetFamilyIds :: Array (Key Family) -> ComponentType Unit State Action
handleSetFamilyIds ids = do
    familyIds .= ids
    state <- get :: Component Unit State State
    let switchFamily
          = if isNothing state.socketS.currentFamily
            then pure [ toIO (mkSettings $ state^.authData) switchToBestFamily ]
            else pure []
    if Arr.null ids
      then doAutoSwitchCentral ReqCentralInvite
      else switchFamily
  where -- Only needed for fixing old clients:
    switchToBestFamily :: Gonimo Action
    switchToBestFamily = do
      devices <- traverse getFamiliesByFamilyIdDeviceInfos ids
      let deviceCount = Arr.length <$> devices
      let familyDevices = zip ids deviceCount
      let family = map fst <<< maximumBy (\(Tuple _ a) (Tuple _ b) -> compare a b) $ familyDevices
      let mAction = map (SocketA <<< SocketC.SwitchFamily) family
      pure $ fromMaybe Nop mAction



handleSetURL :: String -> ComponentType Unit State Action
handleSetURL url = do
  let
    route = Router.match url
    withoutQuery = takeWhile (_ /= '?') url
  case route of
    Router.Home -> onlyModify $ _ { url = url }
    Router.AcceptInvitation s -> do
      modify $ _ { url = withoutQuery
                 }
      actions <- handleSetCentral $ CentralAccept (AcceptC.init)
      pure $ [ do
               liftEff $ navigateTo withoutQuery
               inviteEffect s
             ] <> actions

handleClearError :: ComponentType Unit State Action
handleClearError = do
  state <- (get :: Component Unit State State)
  let
    newCentral = case state.central of
      CentralAccept (Just _) -> state.central
      _                     -> CentralOverview

  onlyModify $ _ { userError = NoError
                 , central = newCentral
                 }

-- Switch central if it is safe to do so. Use this function if you want to switch the central
-- automatically - not by user request.
doAutoSwitchCentral :: CentralReq -> ComponentType Unit State Action
doAutoSwitchCentral req = do
  mycentral <- use central
  case mycentral of
    CentralAccept acceptS' -> if isAccepted acceptS'
                              then handleRequestCentral req
                              else pure []
    _               -> handleRequestCentral req

--------------------------------------------------------------------------------

view :: State -> Html Action
view state =
  let
    numDevices = Arr.length state.onlineDevices
  in
    case state.userError of
      NoError ->
        div []
        [ viewHeader state
        , viewCentral state
        , div []
          [ h3 [] [ text $ show numDevices <> " Device(s) currently online:" ]
          , div [] [ viewOnlineDevices state ]
          ]
        ]
      err -> viewError state

viewHeader :: State -> Html Action
viewHeader state =
      nav [ A.className "navbar navbar-default" ]
      [ div [ A.className "container"]
    -- Brand and toggle get grouped for better mobile display --
          [ div [ A.className "navbar-header"]
            [ burgerButton
            , a [ A.className "navbar-brand"]
              [ img [ A.alt "gonimo"
                    -- , A.src "./pix/gonimo-brand-01.svg"
                    , A.src "./pix/gonimo-Weihnachts-Logo_2_app-12.svg"
                    -- , A.width "45px"
                    , A.height "50px"
                    , A.style [Tuple "padding" "2px 3.5px 0px 3.5px"]
                    -- , A.style [Tuple "padding" "5px 7.5px 0px 7.5px"]
                    ] []
              ]
            ]

    -- Collect the nav links, forms, and other content for toggling --
          , div [ A.className "collapse navbar-collapse"
                , A.id_ "navbarmenu"
                , A.style [Tuple "width" "100%"]
                , A.dataToggle "collapse"
                , A.dataTarget ".navbar-collapse.in"
                ]
            [ ul [ A.className "nav navbar-nav"] $ (viewCentralItem <$> getCentrals state) <>
              [ viewFamilyChooser state
        --      , viewUserSettings
              ]
            ]
          ]
        ]

  where
    burgerButton :: Html Action
    burgerButton = button [ A.type_ "button"
                          , A.className "navbar-toggle collapsed"
                          , A.dataToggle "collapse"
                          , A.dataTarget "#navbarmenu"
                          , A.ariaExpanded "false"
                          ]
                   [ span [A.className "sr-only"] [text "Toggle navigation"]
                   , span [A.className "icon-bar"] []
                   , span [A.className "icon-bar"] []
                   , span [A.className "icon-bar"] []
                   ]
    viewCentralItem :: CentralItem -> Html Action
    viewCentralItem item =
      if item.enabled
      then
        li (if item.selected then [ A.className "active" ] else []
            <>    [ A.dataToggle "collapse"
                  , A.dataTarget ".navbar-collapse.in"
                  ]
          )
          [ a [ E.onClick <<< const $ RequestCentral item.req
              , A.type_ "button", A.role "button"
              ]
            [ text $ userShow item.req ]
          ]
      else span [] []

viewUserSettings :: Html Action
viewUserSettings =
  li [A.className "dropdown navbar-right"]
  [ a [ A.className "dropdown-toggle"
      , A.href "#"
      , A.role "button"
      , A.dataToggle "dropdown"
      , A.type_ "button"
      ]
    [ i [A.className "fa fa-fw fa-user"] []
    , text " "
    , text "Max Mustermann"
    , text " "
    , span [A.className "caret"] []
    ]
  , ul [A.className "dropdown-menu", A.style [Tuple "minWidth" "180px"]]
    [ li [A.dataToggle "collapse"] [div [A.className "dropdown-header"] [text "Change user settings (WIP)"]]
    , li [A.className "disabled"] [a [] [text " User settings "
                  ,i [A.className "fa fa-fw fa-cog pull-right"] []]]
    , li [A.className "disabled"] [ a [] [ text "Change password "
                   , i [A.className "fa fa-fw fa-lock pull-right" ][]
                   ]]
    , li [A.className "divider", A.role "separator"] []
    , li [A.className "disabled"] [a [] [ text "Log-Out "
                  , i [A.className "fa fa-fw fa-sign-out pull-right"] []
                  ]]
    ]
  ]

viewCentral :: State -> Html Action
viewCentral state =
  let
    props = mkProps state
    invProps = mkInviteProps state
  in
   case state.central of
    CentralInvite s -> map InviteA $ InviteC.view invProps s
    CentralAccept s -> map AcceptA $ AcceptC.view props s
    CentralOverview     -> map OverviewA   $ OverviewC.view props state.overviewS
    CentralBaby     -> map SocketA   $ SocketC.view props state.socketS


viewOnlineDevices :: State -> Html Action
viewOnlineDevices state = table [ A.className "table table-striped"]
                          [ head
                          , body
                          ]
  where
    head = thead []
           [ tr []
             [
               -- th [ A.className "centered"] [ text "Online" ]
             -- , th [ A.className "centered"] [ text "Type" ]
               th [] [ text "Name" ]
             , th [] [ text "Last Seen"]
             -- , th [] []
             -- , th [] []
             -- , th [] []
             ]
           ]
    body = tbody []
           <<< Arr.mapMaybe viewOnlineDevice
           $ map fst state.onlineDevices
    viewOnlineDevice deviceId = do
        (DeviceInfo info) <- Tuple.lookup deviceId state.deviceInfos
        let name = info.deviceInfoName
        let lastAccessed = dateToString info.deviceInfoLastAccessed
        pure $ tr []
               [
                 -- td [A.className "centered"] [ i [ A.className ("fa fa-" <> "circle-o") -- "check-circle"
                 --       , A.dataToggle "tooltip"
                 --       , A.dataPlacement "right"
                 --       , A.title "offline" ] []]
                 --       --, A.title "online" ] []]
               -- , td [A.className "centered"]
               --     [ i [ A.className ("fa fa-fw fa-" <> "mobile")
               --         , A.dataToggle "tooltip"
               --         , A.dataPlacement "right"
               --         , A.title "edit device name" ] []
               --         ]
                 td [] [ text name ]
               , td [] [ text lastAccessed ]
               -- , td [] [ i [ A.className "fa fa-fw fa-pencil"
               --         , A.dataToggle "tooltip"
               --         , A.dataPlacement "right"
               --         , A.title "edit device name" ] []
               --         ]
               -- , td [] [ i [ A.className "fa fa-fw fa-trash"
               --         , A.dataToggle "tooltip"
               --         , A.dataPlacement "right"
               --         , A.title "delete device from family" ] []]
               --
               ]

viewFamilyChooser :: State -> Html Action
viewFamilyChooser state =
  li [ A.className "dropdown"
     , A.dataToggle "collapse"
     ]
  [ a [ A.className "dropdown-toggle"
      , A.href "#"
      , A.role "button"
      , A.dataToggle "dropdown"
      , A.type_ "button"
      ]
    [ i [A.className "fa fa-fw fa-users"] []
    , text " "
    , text $ fromMaybe "" $ getFamilyName <$> (state.socketS.currentFamily >>= flip Map.lookup state.families)
    {--, span [] [text $ fromMaybe "" $ _.familyName <<< runFamily <$> (state.socketS.currentFamily >>= flip Map.lookup state.families)]--}
    , text " "
    , span [A.className "caret"] [] ]
    , H.ul [A.className "dropdown-menu"] $
        [li [A.dataToggle "collapse"] [div [A.className "dropdown-header"] [text "Change family to"]]]
        <> (fromFoldable <<< map (uncurry (viewFamily state.socketS.currentFamily))
                         <<< Map.toList $ state.families)
  ]
  where
    getFamilyName (Family f) = f.familyName^.familyName

    doSwitchFamily :: Key Family -> Action
    doSwitchFamily = SocketA <<< SocketC.SwitchFamily

    viewFamily :: Maybe (Key Family) -> Key Family -> Family -> Html Action
    viewFamily currentFamilyId familyId (Family family) =
        li [] [a [E.onClick $ const $ doSwitchFamily familyId ] $
                 [text (family.familyName^.familyName)] <> if Just familyId == currentFamilyId
                                                then [text " ✔"]
                                                else []
              ]

--------------------------------------------------------------------------------
getSubscriptions :: State -> Subscriptions Action
getSubscriptions state =
  let
    familyId = state^?currentFamily
    sessionId' = state^.socketS<<<sessionId
    --subscribeGetFamily :: forall m. MonadReader Settings m => Key Family -> m (Subscriptions Action)
    subscribeGetFamily familyId' =
      Sub.getFamiliesByFamilyId (maybe Nop (UpdateFamily familyId')) familyId'

    subArray :: Array (Subscriptions Action)
    subArray = map (flip runReader (mkSettings $ state^.authData)) <<< concat $
      [ [ Sub.getAccountsByAccountIdFamilies (maybe Nop SetFamilyIds)
                                          (runAuthData $ state^.authData).accountId
        ]
      , fromFoldable $ do
           _ <- sessionId' -- Avoid error message `FamilyNotOnline` when not yet ready.
           Sub.getSessionByFamilyId (maybe Nop SetOnlineDevices) <$> familyId
      , fromFoldable $
        Sub.getFamiliesByFamilyIdDeviceInfos (maybe Nop SetDeviceInfos) <$> familyId
      , map subscribeGetFamily state.familyIds
      ]
  in
   case state.userError of
     NoError -> foldl append mempty subArray <> map SocketA (SocketC.getSubscriptions (mkProps state) state.socketS)
     _       -> mempty

getPongRequest :: State -> Maybe HttpRequest
getPongRequest state =
  let
    deviceId = (runAuthData $ state^.authData).deviceId
    onlineStatus' = state ^. socketS <<< to SocketC.toDeviceType
    sessionId'    = state ^. socketS <<< to _.sessionId
    familyId = state^?currentFamily
  in
   case state.userError of
     NoError -> flip runReader (mkSettings $ state^.authData) <$>
                ( Reqs.putSessionByFamilyIdByDeviceIdBySessionId onlineStatus'
                  <$> familyId
                  <*> pure deviceId
                  <*> sessionId'
                )
     _       -> Nothing

getCloseRequest :: State -> Maybe HttpRequest
getCloseRequest state =
  let
    deviceId = (runAuthData $ state^.authData).deviceId
    familyId = state^?currentFamily
    sessionId' = state ^. socketS <<< to _.sessionId
  in
   case state.userError of
     NoError -> flip runReader (mkSettings $ state^.authData) <$>
                ( Reqs.deleteSessionByFamilyIdByDeviceIdBySessionId
                  <$> familyId
                  <*> pure deviceId
                  <*> sessionId'
                )
     _ -> Nothing



-- | Retrieve AuthData from local storage or if not present get new one from server
getAuthData :: Gonimo AuthData
getAuthData = do
  localStorage <- liftEff getLocalStorage
  md <- liftEff $ getItem localStorage Key.authData
  Gonimo.log $ "Got authdata from local storage: " <> gShow md
  case md of
    Nothing -> do
      auth <- postAccounts
      Gonimo.log $ "Got Nothing - called postAccounts and got: " <> gShow auth
      Gonimo.log $ "Calling setItem with : " <> gShow Key.authData
      liftEff $ setItem localStorage Key.authData auth
      pure auth
    Just d  -> pure d

