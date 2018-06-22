{-# language DataKinds, TypeFamilies #-}
{-# language LambdaCase #-}
module Generators.General where

import Control.Applicative
import Control.Lens.Getter
import Control.Lens.Iso (from)

import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range

import Language.Python.Internal.Syntax

import Generators.Common
import Generators.Sized

genParam :: MonadGen m => m (Expr '[] ()) -> m (Param '[] ())
genParam genExpr =
  sizedRecursive
    [ StarParam () <$> genWhitespaces <*> genIdent
    , DoubleStarParam () <$> genWhitespaces <*> genIdent
    ]
    [ KeywordParam () <$> genIdent <*> genWhitespaces <*> genExpr ]

genArg :: MonadGen m => m (Expr '[] ()) -> m (Arg '[] ())
genArg genExpr =
  sizedRecursive
    [ PositionalArg () <$> genExpr
    , KeywordArg () <$> genIdent <*> genWhitespaces <*> genExpr
    , StarArg () <$> genWhitespaces <*> genExpr
    , DoubleStarArg () <$> genWhitespaces <*> genExpr
    ]
    []

genInt :: MonadGen m => m (Expr '[] ())
genInt = Int () <$> Gen.integral (Range.constant (-2^32) (2^32)) <*> genWhitespaces

genIdent :: MonadGen m => m (Ident '[] ())
genIdent =
  MkIdent () <$>
  liftA2 (:)
    (Gen.choice [Gen.alpha, pure '_'])
    (Gen.list (Range.constant 0 49) (Gen.choice [Gen.alphaNum, pure '_'])) <*>
  genWhitespaces

genModuleName :: MonadGen m => m (ModuleName '[] ())
genModuleName =
  Gen.recursive Gen.choice
  [ ModuleNameOne () <$> genIdent ]
  [ ModuleNameMany () <$>
    genIdent <*>
    genWhitespaces <*>
    genModuleName
  ]

genRelativeModuleName :: MonadGen m => m (RelativeModuleName '[] ())
genRelativeModuleName =
  Gen.choice
  [ Relative <$>
    Gen.nonEmpty (Range.constant 1 10) genDot
  , RelativeWithName <$>
    Gen.list (Range.constant 1 10) genDot <*>
    genModuleName
  ]

genImportTargets :: MonadGen m => m (ImportTargets '[] ())
genImportTargets =
  Gen.choice
  [ ImportAll () <$> genWhitespaces
  , ImportSome () <$>
    genSizedCommaSep1 (genImportAs genIdent genIdent)
  , ImportSomeParens () <$>
    genWhitespaces <*>
    genSizedCommaSep1' (genImportAs genIdent genIdent) <*>
    genWhitespaces
  ]

genBlock :: MonadGen m => m (Block '[] ())
genBlock =
  fmap Block .
  sizedNonEmpty $
  Gen.choice
    [ Right <$> genStatement
    , fmap Left $ (,,) <$> genWhitespaces <*> Gen.maybe genComment <*> genNewline
    ]

genCompFor :: MonadGen m => m (CompFor '[] ())
genCompFor =
  sized2M
    (\a b ->
        (\ws1 ws2 -> CompFor () ws1 a ws2 b) <$>
        genWhitespaces <*>
        genWhitespaces)
    genExpr
    genExpr

genCompIf :: MonadGen m => m (CompIf '[] ())
genCompIf =
  CompIf () <$>
  genWhitespaces <*>
  Gen.scale (max 0 . subtract 1) genExpr

genComprehension :: MonadGen m => m (Comprehension '[] ())
genComprehension =
  sized3
    (Comprehension ())
    genExpr
    genCompFor
    (sizedList $ Gen.choice [Left <$> genCompFor, Right <$> genCompIf])

genSubscript :: MonadGen m => m (Subscript '[] ())
genSubscript =
  sizedRecursive
    [ SubscriptExpr <$> genExpr
    , sized3M
        (\a b c -> (\ws -> SubscriptSlice a ws b c) <$> genWhitespaces)
        (sizedMaybe genExpr)
        (sizedMaybe genExpr)
        (sizedMaybe $ (,) <$> genWhitespaces <*> sizedMaybe genExpr)
    ]
    []

-- | This is necessary to prevent generating exponentials that will take forever to evaluate
-- when python does constant folding
genExpr :: MonadGen m => m (Expr '[] ())
genExpr = genExpr' False

genExpr' :: MonadGen m => Bool -> m (Expr '[] ())
genExpr' isExp =
  sizedRecursive
    [ genBool
    , if isExp then genSmallInt else genInt
    , Ident () <$> genIdent
    , String () <$>
      Gen.nonEmpty (Range.constant 1 5) (Gen.choice [genStringLiteral, genBytesLiteral])
    ]
    [ List () <$>
      genWhitespaces <*>
      Gen.maybe (genSizedCommaSep1' genExpr) <*>
      genWhitespaces
    , Dict () <$>
      genWhitespaces <*>
      sizedMaybe (genSizedCommaSep1' $ genDictItem genExpr) <*>
      genWhitespaces
    , Set () <$> genWhitespaces <*> genSizedCommaSep1' genExpr <*> genWhitespaces
    , ListComp () <$>
      genWhitespaces <*>
      genComprehension <*>
      genWhitespaces
    , Generator () <$> genComprehension
    , Gen.subtermM
        genExpr
        (\a ->
            Deref () <$>
            pure a <*>
            genWhitespaces <*>
            genIdent)
    , sized2M
        (\a b ->
           (\ws1 ws2 -> Call () a ws1 b ws2) <$>
           genWhitespaces <*>
           genWhitespaces)
        genExpr
        (sizedMaybe . genSizedCommaSep1' $ genArg genExpr)
    , sized2M
        (\a b ->
           (\ws1 ws2 -> Subscript () a ws1 b ws2) <$>
           genWhitespaces <*>
           genWhitespaces)
        genExpr
        (genSizedCommaSep1' genSubscript)
    , sizedBind genExpr $ \a -> do
        op <- genOp
        sizedBind (genExpr' $ case op of; Exp{} -> True; _ -> False) $ \b ->
          pure $ BinOp () a op b
    , Gen.subtermM
        (genExpr' isExp)
        (\a -> Parens () <$> genWhitespaces <*> pure a <*> genWhitespaces)
    , genTuple genExpr
    , Not () <$> genWhitespaces <*> genExpr
    , Negate () <$> genWhitespaces <*> genExpr
    ]

genSmallStatement :: MonadGen m => m (SmallStatement '[] ())
genSmallStatement =
  sizedRecursive
    (pure <$> [Pass (), Break (), Continue ()])
    [ Expr () <$> genExpr
    , sized2M
        (\a b -> (\ws1 -> Assign () a ws1 b) <$> genWhitespaces)
        genExpr
        genExpr
    , sized2M
        (\a b -> (\aa -> AugAssign () a aa b) <$> genAugAssign)
        genExpr
        genExpr
    , Global () <$>
        genWhitespaces1 <*>
        genSizedCommaSep1 genIdent
    , Del () <$>
      genWhitespaces1 <*>
      genSizedCommaSep1 genIdent
    , Nonlocal () <$>
      genWhitespaces1 <*>
      genSizedCommaSep1 genIdent
    , Return () <$>
      genWhitespaces <*>
      genExpr
    , Import () <$>
      genWhitespaces1 <*>
      genSizedCommaSep1 (genImportAs genModuleName genIdent)
    , From () <$>
      genWhitespaces <*>
      genRelativeModuleName <*>
      genWhitespaces <*>
      genImportTargets
    , Raise () <$>
      genWhitespaces <*>
      sizedMaybe ((,) <$> genExpr <*> Gen.maybe ((,) <$> genWhitespaces <*> genExpr))
    ]

genCompoundStatement
  :: MonadGen m
  => m (CompoundStatement '[] ())
genCompoundStatement =
  sizedRecursive
    [ sized2M
        (\a b ->
           Fundef <$> genIndents <*> pure () <*>
           genWhitespaces1 <*> genIdent <*> genWhitespaces <*> pure a <*>
           genWhitespaces <*> genWhitespaces <*> genNewline <*> pure b)
        (genSizedCommaSep $ genParam genExpr)
        genBlock
    , sized4M
        (\a b c d ->
           If <$> genIndents <*> pure () <*>
           genWhitespaces <*> pure a <*> genWhitespaces <*> genNewline <*>
           pure b <*> pure c <*> pure d)
        genExpr
        genBlock
        (sizedList $
         sized2M
           (\a b ->
              (,,,,,) <$>
              genIndents <*> genWhitespaces <*> pure a <*>
              genWhitespaces <*> genNewline <*> pure b)
           genExpr
           genBlock)
        (sizedMaybe $
         (,,,,) <$>
         genIndents <*> genWhitespaces <*> genWhitespaces <*> genNewline <*> genBlock)
    , sized2M
        (\a b ->
           While <$>
           genIndents <*>
           pure () <*> genWhitespaces <*> pure a <*>
           genWhitespaces <*> genNewline <*> pure b)
        genExpr
        genBlock
    , sized4M
        (\a b c d ->
           TryExcept <$> genIndents <*> pure () <*> genWhitespaces <*> genWhitespaces <*>
           genNewline <*> pure a <*> pure b <*> pure c <*> pure d)
        genBlock
        (sizedNonEmpty $
         sized2M
           (\a b ->
              (,,,,,) <$> genIndents <*> genWhitespaces <*>
              (ExceptAs () <$> pure a <*> Gen.maybe ((,) <$> genWhitespaces <*> genIdent)) <*>
              genWhitespaces <*> genNewline <*> pure b)
           genExpr
           genBlock)
        (sizedMaybe $
         (,,,,) <$> genIndents <*> genWhitespaces <*> genWhitespaces <*>
         genNewline <*> genBlock)
        (sizedMaybe $
         (,,,,) <$> genIndents <*> genWhitespaces <*> genWhitespaces <*>
         genNewline <*> genBlock)
    , sized2M
        (\a b -> 
           TryFinally <$>
           genIndents <*>
           pure () <*>
           genWhitespaces <*> genWhitespaces <*> genNewline <*>
           pure a <*>
           genIndents <*>
           genWhitespaces <*> genWhitespaces <*> genNewline <*>
           pure b)
        genBlock
        genBlock
    , sized2M
        (\a b ->
           ClassDef <$> genIndents <*> pure () <*> genWhitespaces1 <*> genIdent <*>
           Gen.maybe ((,,) <$> genWhitespaces <*> pure a <*> genWhitespaces) <*>
           genWhitespaces <*> genNewline <*> pure b)
        (sizedMaybe $ genSizedCommaSep1' $ genArg genExpr)
        genBlock
    , sized4M
        (\a b c d ->
           For <$> genIndents <*> pure () <*> genWhitespaces <*> pure a <*>
           genWhitespaces <*> pure b <*> genWhitespaces <*> genNewline <*>
           pure c <*> pure d)
        genExpr
        genExpr
        genBlock
        (sizedMaybe $
         (,,,,) <$>
         genIndents <*> genWhitespaces <*> genWhitespaces <*> genNewline <*> genBlock)
    ]
    []

genStatement :: MonadGen m => m (Statement '[] ())
genStatement =
  sizedRecursive
    [ sizedBind genSmallStatement $ \st ->
      sizedBind (sizedList $ (,) <$> genWhitespaces <*> genSmallStatement) $ \sts ->
      (\a -> SmallStatements a st sts) <$>
      genIndents <*>
      Gen.maybe genWhitespaces <*>
      Gen.maybe genNewline
    ]
    [ CompoundStatement <$> genCompoundStatement ]

genIndent :: MonadGen m => m Indent
genIndent =
  view (from indentWhitespaces) <$> genWhitespaces

genIndents :: MonadGen m => m (Indents ())
genIndents = (\is -> Indents is ()) <$> Gen.list (Range.constant 0 10) genIndent

genModule :: MonadGen m => m (Module '[] ())
genModule =
  Module <$>
  sizedList
    (Gen.choice
    [ fmap Left $ (,,) <$> genIndents <*> Gen.maybe genComment <*> Gen.maybe genNewline
    , Right <$> genStatement
    ])

genImportAs :: MonadGen m => m (e ()) -> m (Ident '[] ()) -> m (ImportAs e '[] ())
genImportAs me genIdent =
  sized2M
    (\a b -> ImportAs () a <$> pure b)
    me
    (sizedMaybe $ (,) <$> genWhitespaces1 <*> genIdent)
