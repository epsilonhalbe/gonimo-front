-- File auto generated by purescript-bridge! --
module Gonimo.Server.Error where


import Data.Generic (class Generic)


data ServerError =
    InvalidAuthToken 
  | InvitationAlreadyClaimed 
  | AlreadyFamilyMember 

derive instance genericServerError :: Generic ServerError

