module Nuri.Codegen.Stmt where

import           Control.Monad.RWS                        ( tell
                                                          , execRWS
                                                          )
import           Control.Lens                             ( view )

import           Text.Megaparsec.Pos                      ( SourcePos )

import qualified Data.Set.Ordered              as S

import           Nuri.Stmt
import           Nuri.ASTNode
import           Nuri.Codegen.Expr

import           Haneul.Builder
import           Haneul.Constant
import qualified Haneul.Instruction            as Inst

compileStmt :: Stmt -> Builder ()
compileStmt stmt@(ExprStmt expr) = do
  compileExpr expr
  tell [(srcPos stmt, Inst.Pop)]
compileStmt stmt@(Return expr) = do
  compileExpr expr
  tell [(srcPos stmt, Inst.Return)]
compileStmt (Assign pos ident expr) = do
  compileExpr expr
  storeVar pos ident
compileStmt If{}                                  = undefined
{- do
  compileExpr cond
  st <- get
  let (thenInternal, thenInsts) =
        execRWS (sequence_ (compileStmt <$> thenStmt)) () st
      (elseInternal, elseInsts) =
        execRWS (sequence_ (compileStmt <$> fromMaybe [] elseStmt)) () st
  tell [(pos, Inst.PopJmpIfFalse $ sum (getInstSize . snd <$> thenInsts))]
  put thenInternal
  tell thenInsts -}
compileStmt While{}                               = undefined
compileStmt (FuncDecl pos funcName argNames body) = do
  fileName <- ask
  let (internal, instructions) = execRWS
        (sequence_ (compileStmt <$> body))
        fileName
        (defaultInternal { _varNames = S.fromList argNames })
      funcObject = ConstFunc
        (FuncObject { _arity          = fromIntegral (length argNames)
                    , _insts          = instructions
                    , _funcConstTable = view constTable internal
                    , _funcVarNames   = view varNames internal
                    }
        )
  funcObjectIndex <- addConstant funcObject
  funcNameIndex   <- addVarName funcName
  tell [(pos, Inst.Push funcObjectIndex), (pos, Inst.Store funcNameIndex)]

storeVar :: SourcePos -> Text -> Builder ()
storeVar pos ident = do
  index <- addVarName ident
  tell [(pos, Inst.Store index)]


