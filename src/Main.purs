module Main where

import Prelude

import Control.Monad.Aff (runAff)
import Control.Monad.Eff (Eff())
import Control.Monad.Eff.Exception (throwException)

import Halogen
import Halogen.Util (appendToBody, onLoad)
import qualified Halogen.HTML.Indexed as H
import qualified Halogen.HTML.Events.Indexed as E

type Model = Unit


data Query a = Query a

helloC :: forall g . (Functor g) => Component Model Query g
helloC = component render eval
  where
    render ::  Model -> ComponentHTML Query
    render _ = H.span
                []
                [ H.text "Hello sailor!" ]
    eval :: Natural Query (ComponentDSL Model Query g)
    eval (Query next) = pure next


main :: Eff (HalogenEffects ()) Unit
main = runAff throwException (const (pure unit)) do
  app <- runUI helloC unit
  onLoad $ appendToBody app.node