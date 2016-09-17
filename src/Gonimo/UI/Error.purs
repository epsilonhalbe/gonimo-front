module Gonimo.UI.Error ( class ErrorAction
                       , resetDevice
                       , nop
                       , UserError(..)
                       , handleError
                       , handleSubscriber
                       , viewError ) where

import Gonimo.Client.Effects as Gonimo
import Gonimo.Server.Error as Server
import Pux.Html.Attributes as A
import Pux.Html.Events as E
import Servant.PureScript.Affjax as Affjax
import Data.Either (Either(Left, Right), either)
import Data.Generic (gShow)
import Data.Maybe (fromMaybe, maybe, Maybe(Just, Nothing))
import Gonimo.Client.Types (GonimoError(AjaxError, UnexpectedAction))
import Gonimo.Pux (onlyEffects, onlyEffect, EffModel)
import Gonimo.Server.Error (ServerError(NoSuchFamily, AlreadyFamilyMember))
import Pux.Html (div, button, p, h1, text, Html)
import Pux.Html.Attributes (offset)
import Servant.PureScript.Affjax (ErrorDescription, responseToString, unsafeToString, ErrorDescription(DecodingError, ParsingError, UnexpectedHTTPStatus))
import Servant.Subscriber.Connection (Notification(HttpRequestFailed, ParseError, WebSocketClosed, WebSocketError))
import Servant.Subscriber.Internal (doDecode)
import Servant.Subscriber.Request (HttpRequest)
import Servant.Subscriber.Response (HttpResponse(HttpResponse))
import Servant.Subscriber.Util (toUserType)
import Prelude hiding (div)

type State r = { userError :: UserError | r }

class ErrorAction action where
  resetDevice :: action
  nop :: action

-- | Errors which are of concern for the user and should be displayed.
data UserError = NoError
               | DeviceInvalid -- Server does not accept our device secret.
               | Crashed -- An unexpected error occurred - we can not continue. - The user obviously should never see this in production.

handleError :: forall eff r action. ErrorAction action
               => GonimoError -> State r -> EffModel eff (State r) action
handleError err state = case err of
  UnexpectedAction msg -> logErrorModel state "An unexpected action occurred: " msg
  AjaxError err -> handleAjaxError state err

handleAjaxError :: forall eff r action. ErrorAction action
                   => State r -> Affjax.AjaxError -> EffModel eff (State r) action
handleAjaxError state (Affjax.AjaxError err) = case err.description of
  ParsingError msg -> logErrorModel state "Parsing error in Ajax request: " msg
  DecodingError msg -> logErrorModel state "Decoding error in Ajax request: " msg
  UnexpectedHTTPStatus response ->
    handleEncodedServerError state "unknown" (responseToString response) response.response


handleSubscriber :: forall eff r action. ErrorAction action
                    => Notification -> State r -> EffModel eff (State r) action
handleSubscriber notification state =
  case notification of
    WebSocketError msg           -> logErrorModel state "A websocket error occurred: " msg
    WebSocketClosed msg          -> logErrorModel state "The websocket connection got closed: " msg
    ParseError msg               -> logErrorModel state "A parsing error occurred: " msg
    HttpRequestFailed req' resp' -> handleFailedHttpRequest state req' resp'

handleFailedHttpRequest :: forall eff r action. ErrorAction action
                           => State r -> HttpRequest -> HttpResponse -> EffModel eff (State r) action
handleFailedHttpRequest state req' fResp@(HttpResponse resp') = handleEncodedServerError state (gShow req') (gShow fResp) resp'.httpBody

handleEncodedServerError :: forall eff r action. ErrorAction action
                            => State r -> String -> String -> String -> EffModel eff (State r) action
handleEncodedServerError state req' resp' value = onlyEffects newState $ case decodingResult of
    Right _ -> [ do
                    Gonimo.log "Got server error!"
                    Gonimo.log $ "For request: " <> req'
                    Gonimo.log $ "Response was: " <> resp'
                    pure nop
               ]
    Left err -> [ do
                     Gonimo.log $ "Decoding error while handling failed http request: " <> err
                     Gonimo.log $ "For request: " <> req'
                     Gonimo.log $ "Response was: " <> resp'
                     pure nop
                ]
  where
    newState = case error of
        NoError -> state
        _       -> setError error state
    fromServer = fromMaybe NoError <<< ( fromServerError =<< _ )
    decodingResult = doDecode (toUserType fromServer) value
    error = either (const Crashed) id decodingResult


viewError :: forall r action. ErrorAction action
             => State r -> Html action
viewError state = case state.userError of
  NoError -> text "No error occurred - everything is fine!"
  DeviceInvalid ->
    div [ A.className "alert alert-danger", A.role "alert" ]
    [ h1 [] [ text "Your account is no longer valid!" ]
    , p []
      [ text  "We are sorry, but your account is no longer known by our server." ]
      , p []
        [ text
          $ "To proceed I would create a new account for you. You will have to rejoin any "
          <> "families you were in already."
        ]
    , p [] [ text "I am sorry for any inconveniences!" ]
    , div [ A.className "btn-group", A.role "group" ]
      [ button
        [ A.className "btn btn-danger btn-lg btn-block", E.onClick $ const resetDevice ]
        [ text "Proceed"]
      ]
    ]
  Crashed ->
    div [ A.className "alert alert-danger", A.role "alert"]
    [ h1 [] [ text "Your gonimo has crashed!"]
    , p []
      [ text $ "Something unexpected happened - and I don't know what to do!"
             <> "Please try again later - hopefully we have fixed the problem then!"
      ]
    ]

logErrorModel :: forall eff r action. ErrorAction action
                 => State r -> String -> String -> EffModel eff (State r) action
logErrorModel state prefix msg = onlyEffect state $ do
      Gonimo.log $ prefix <> msg
      pure nop

fromServerError :: ServerError -> Maybe UserError
fromServerError err = case err of
    Server.InvalidAuthToken -> Just DeviceInvalid
    _ -> Nothing

-- | Sets userError in state but only if it was NoError before. (Does not overwrite an existing error)
setError :: forall r. UserError -> (State r) -> (State r)
setError error state = case state.userError of
  NoError -> state { userError = error }
  _ -> state
