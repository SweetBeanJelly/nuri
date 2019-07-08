module Nuri.Eval.Expr where

import           Prelude                           hiding ( lookup )

import           Control.Monad.State.Lazy
import           Control.Monad.Except

import           Data.Map

import           Text.Megaparsec.Pos

import           Nuri.Expr
import           Nuri.Eval.Val
import           Nuri.Eval.Error

evalExpr :: Expr -> Eval Val
evalExpr (Lit _   (LitInteger v)) = return $ IntegerVal v
evalExpr (Var pos ident         ) = do
  table <- get
  case lookup ident table of
    Just val -> return val
    Nothing  -> throwError $ UnboundSymbol pos ident
evalExpr (App pos func args) = do
  funcResult <- evalExpr func
  case funcResult of
    FuncVal funcVal -> do
      argsVal <- sequence $ fmap evalExpr args
      funcVal argsVal
    val -> throwError $ NotCallable pos (getTypeName val)
evalExpr (BinaryOp pos op lhs rhs) = do
  lhsVal <- evalExpr lhs
  rhsVal <- evalExpr rhs
  operateBinary pos op lhsVal rhsVal
evalExpr (UnaryOp _ _ _) = undefined

operateBinary
  :: SourcePos -> Op -> Val -> Val -> StateT SymbolTable (Except Error) Val
operateBinary _ Plus (IntegerVal v1) (IntegerVal v2) =
  return $ IntegerVal (v1 + v2)
operateBinary _ Minus (IntegerVal v1) (IntegerVal v2) =
  return $ IntegerVal (v1 - v2)
operateBinary _ Asterisk (IntegerVal v1) (IntegerVal v2) =
  return $ IntegerVal (v1 * v2)
operateBinary _ Slash (IntegerVal v1) (IntegerVal v2) =
  return $ IntegerVal (v1 `div` v2)
operateBinary pos _ lhs rhs =
  throwError $ OperateTypeError pos (getTypeName lhs) (getTypeName rhs)
