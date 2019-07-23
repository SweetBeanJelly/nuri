module Nuri.Spec.Eval.ExprSpec where

import           Test.Hspec

import           Data.Map

import           Nuri.Eval.Expr
import           Nuri.Eval.Error
import           Nuri.Expr
import           Nuri.Eval.Val

import           Nuri.Spec.Util
import           Nuri.Spec.Eval.Util

testEvalWith :: Expr -> SymbolTable -> IO (Either Error (Val, SymbolTable))
testEvalWith = runEval

testEval :: Expr -> IO (Either Error (Val, SymbolTable))
testEval expr = runEval expr empty

spec :: Spec
spec = do
  describe "리터럴 평가" $ do
    describe "정수 리터럴 평가" $ do
      it "LitInteger 10을 IntegerVal 10으로 평가" $ do
        testEval (litInteger 10) `shouldEval` (IntegerVal 10, empty)

  describe "변수 식별자 평가" $ do
    it "심볼 테이블에서 식별자 값 가져오기" $ do
      testEvalWith (var "나이") sampleTable
        `shouldEval` (IntegerVal 17, sampleTable)
    it "없는 심볼에 대해서 UnboundSymbol 에러" $ do
      testEvalWith (var "사과") sampleTable `shouldEvalError` unboundSymbol "사과"

  describe "이항 연산자 평가" $ do
    it "정수 두 개 더하기" $ do
      testEval (binaryOp Plus (litInteger 10) (litInteger 5))
        `shouldEval` (IntegerVal 15, empty)
    it "정수 두 개 곱하기" $ do
      testEval (binaryOp Asterisk (litInteger 10) (litInteger 5))
        `shouldEval` (IntegerVal 50, empty)
    it "정수 두 개 나누기" $ do
      testEval (binaryOp Slash (litInteger 10) (litInteger 5))
        `shouldEval` (IntegerVal 2, empty)
    it "0으로 나눌 시 DivideByZero 에러" $ do
      testEval (binaryOp Slash (litInteger 10) (litInteger 0))
        `shouldEvalError` divideByZero
    it "정수형 변수와 정수 리터럴 더하기" $ do
      testEvalWith (binaryOp Plus (var "나이") (litInteger 5)) sampleTable
        `shouldEval` (IntegerVal 22, sampleTable)
    it "정수와 함수 더했을 시 타입 에러" $ do
      testEvalWith (binaryOp Plus (litInteger 10) (var "십")) sampleTable
        `shouldEvalError` operateTypeError ["정수", "함수"]

  describe "단항 연산자 평가" $ do
    it "정수에 양수 단항 연산자" $ do
      testEval (unaryOp Plus (litInteger 10))
        `shouldEval` (IntegerVal 10, empty)
    it "정수에 음수 단항 연산자" $ do
      testEval (unaryOp Minus (litInteger 10))
        `shouldEval` (IntegerVal (-10), empty)
    it "함수에 양수 단항 연산자 적용 시 타입 에러" $ do
      testEvalWith (unaryOp Minus (var "십")) sampleTable
        `shouldEvalError` operateTypeError ["함수"]

  describe "함수 호출 평가" $ do
    it "인자 없는 함수 호출" $ do
      testEvalWith (app (var "십") []) sampleTable
        `shouldEval` (IntegerVal 10, sampleTable)
    it "인자가 하나인 함수 호출" $ do
      testEvalWith (app (var "늘리기") [litInteger 10]) sampleTable
        `shouldEval` (IntegerVal 20, sampleTable)
    it "호출 인수의 개수가 맞지 않으면 에러" $ do
      testEvalWith (app (var "늘리기") [litInteger 10, litInteger 20]) sampleTable
        `shouldEvalError` incorrectArgsNum 1 2
    it "호출할 수 없는 대상에 대해 에러" $ do
      testEvalWith (app (var "나이") []) sampleTable
        `shouldEvalError` notCallable "정수"

  describe "대입식 평가" $ do
    it "단순 정수 대입" $ do
      testEvalWith (assign "수" (litInteger 10)) sampleTable
        `shouldEval` (IntegerVal 10, insert "수" (IntegerVal 10) sampleTable)
    it "사칙연산식 대입" $ do
      testEvalWith
          (assign "수" (binaryOp Plus (litInteger 10) (litInteger 10)))
          sampleTable
        `shouldEval` (IntegerVal 20, insert "수" (IntegerVal 20) sampleTable)
    it "대입식 대입" $ do
      testEvalWith (assign "수" (assign "상자" (litInteger 10))) sampleTable
        `shouldEval` ( IntegerVal 10
                     , union
                       (fromList [("수", IntegerVal 10), ("상자", IntegerVal 10)])
                       sampleTable
                     )
    it "겹치는 식별자 대입" $ do
      testEvalWith (assign "십" (litInteger 10)) sampleTable
        `shouldEval` (IntegerVal 10, insert "십" (IntegerVal 10) sampleTable)