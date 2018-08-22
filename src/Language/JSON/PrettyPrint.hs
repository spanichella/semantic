module Language.JSON.PrettyPrint
  ( defaultBeautyOpts
  , defaultJSONPipeline
  , printingJSON
  , beautifyingJSON
  , minimizingJSON
  ) where

import Prologue hiding (throwError)

import Control.Arrow
import Control.Monad.Effect
import Control.Monad.Effect.Exception (Exc, throwError)
import Data.Machine
import Data.Reprinting.Errors
import Data.Reprinting.Splice
import Data.Reprinting.Token

defaultJSONPipeline :: (Member (Exc TranslationException) effs)
  => ProcessT (Eff effs) Datum Splice
defaultJSONPipeline
  = printingJSON
  ~> beautifyingJSON defaultBeautyOpts

printingJSON :: Monad m => ProcessT m Datum Datum
printingJSON = flattened <~ auto step where
  step :: Datum -> Seq Datum
  step s@(Raw el cs ) =
    let ins = insert el cs
    in case (el, listToMaybe cs) of
      (Truth True, _)  -> ins "true"
      (Truth False, _) -> ins "false"
      (Nullity, _)     -> ins "null"

      (TOpen,  Just TList) -> ins "["
      (TClose, Just TList) -> ins "]"
      (TOpen,  Just THash) -> ins "{"
      (TClose, Just THash) -> ins "}"

      (TSep, Just TList) -> ins ","
      (TSep, Just TPair) -> ins ":"
      (TSep, Just THash) -> ins ","

      _ -> pure s

  step x = pure x

-- | TODO: Fill out and implement configurable options like indentation count,
-- tabs vs. spaces, etc.
data JSONBeautyOpts = JSONBeautyOpts { jsonIndent :: Int, jsonUseTabs :: Bool }
  deriving (Eq, Show)

defaultBeautyOpts :: JSONBeautyOpts
defaultBeautyOpts = JSONBeautyOpts 2 False

beautifyingJSON :: (Member (Exc TranslationException) effs)
  => JSONBeautyOpts -> ProcessT (Eff effs) Datum Splice
beautifyingJSON _ = flattened <~ autoT (Kleisli step) where
  step (Raw el cs)        = throwError (NoTranslation el cs)
  step (Original txt)     = pure $ emit txt
  step (Insert el cs txt) = pure $ case (el, listToMaybe cs) of
    (TOpen,  Just THash) -> emit txt <> layouts [HardWrap, Indent]
    (TClose, Just THash) -> layout HardWrap <> emit txt
    (TSep, Just TList)   -> emit txt <> space
    (TSep, Just TPair)   -> emit txt <> space
    (TSep, Just THash)   -> emit txt <> layouts [HardWrap, Indent]
    _ -> emit txt

minimizingJSON :: (Member (Exc TranslationException) effs)
  => ProcessT (Eff effs) Datum Splice
minimizingJSON = flattened <~ autoT (Kleisli step) where
  step (Raw el cs)      = throwError (NoTranslation el cs)
  step (Original txt)   = pure $ emit txt
  step (Insert _ _ txt) = pure $ emit txt
