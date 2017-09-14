module Test.Language.Python.AST.EscapeSeq (escapeSeqTests) where

import Papa
import Hedgehog
import Test.Tasty
import Test.Tasty.Hedgehog
import Text.Trifecta

import Language.Python.AST.EscapeSeq
import Language.Python.Parser.EscapeSeq

import Test.Language.Python.AST.Gen (genEscapeSeq)

prop_parse_prism_congruent :: Property
prop_parse_prism_congruent =
  property $ do
    esc <- forAll genEscapeSeq
    let escStr = _Escape # esc

    footnote $ "esc = " <> show esc
    footnote $ "escStr = " <> show escStr
    escStr ^? _Escape === Just esc

    case parseString parseEscapeSeq mempty escStr of
      Success esc' -> esc' === esc
      Failure _ -> do
        failure

escapeSeqTests :: [TestTree]
escapeSeqTests =
  [ testProperty
    "escape sequence prism and parser agree"
    prop_parse_prism_congruent 
  ]
