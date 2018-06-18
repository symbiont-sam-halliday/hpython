{-# language DeriveFunctor #-}
{-# language TemplateHaskell #-}
module Language.Python.Internal.Token where

import Data.Deriving (deriveEq1)

import Language.Python.Internal.Syntax (StringPrefix(..))
import Language.Python.Internal.Syntax.Whitespace
  ( Newline(..) )

data QuoteType = SingleQuote | DoubleQuote
  deriving (Eq, Show)

data PyToken a
  = TkIf a
  | TkElse a
  | TkWhile a
  | TkDef a
  | TkReturn a
  | TkPass a
  | TkBreak a
  | TkContinue a
  | TkTrue a
  | TkFalse a
  | TkNone a
  | TkOr a
  | TkAnd a
  | TkIs a
  | TkNot a
  | TkGlobal a
  | TkNonlocal a
  | TkDel a
  | TkImport a
  | TkFrom a
  | TkAs a
  | TkRaise a
  | TkTry a
  | TkExcept a
  | TkFinally a
  | TkClass a
  | TkFor a
  | TkIn a
  | TkInt Integer a
  | TkFloat Integer (Maybe Integer) a
  | TkIdent String a
  | TkShortString (Maybe StringPrefix) QuoteType String a
  | TkLongString (Maybe StringPrefix) QuoteType String a
  | TkSpace a
  | TkTab a
  | TkNewline Newline a
  | TkLeftBracket a
  | TkRightBracket a
  | TkLeftParen a
  | TkRightParen a
  | TkLeftBrace a
  | TkRightBrace a
  | TkLt a
  | TkLte a
  | TkEq a
  | TkDoubleEq a
  | TkGt a
  | TkGte a
  | TkContinued Newline a
  | TkColon a
  | TkSemicolon a
  | TkComma a
  | TkDot a
  | TkPlus a
  | TkMinus a
  | TkComment String a
  | TkStar a
  | TkDoubleStar a
  | TkSlash a
  | TkDoubleSlash a
  | TkPercent a
  | TkShiftLeft a
  | TkShiftRight a
  deriving (Eq, Show, Functor)
deriveEq1 ''PyToken

pyTokenAnn :: PyToken a -> a
pyTokenAnn tk =
  case tk of
    TkDef a -> a
    TkReturn a -> a
    TkPass a -> a
    TkBreak a -> a
    TkContinue a -> a
    TkTrue a -> a
    TkFalse a -> a
    TkNone a -> a
    TkOr a -> a
    TkAnd a -> a
    TkIs a -> a
    TkNot a -> a
    TkGlobal a -> a
    TkNonlocal a -> a
    TkDel a -> a
    TkImport a -> a
    TkFrom a -> a
    TkAs a -> a
    TkRaise a -> a
    TkTry a -> a
    TkExcept a -> a
    TkFinally a -> a
    TkClass a -> a
    TkFor a -> a
    TkIn a -> a
    TkPlus a -> a
    TkMinus a -> a
    TkIf a -> a
    TkElse a -> a
    TkWhile a -> a
    TkInt _ a -> a
    TkFloat _ _ a -> a
    TkIdent _ a -> a
    TkShortString _ _ _ a -> a
    TkLongString _ _ _ a -> a
    TkSpace a -> a
    TkTab a -> a
    TkNewline _ a -> a
    TkLeftBracket a -> a
    TkRightBracket a -> a
    TkLeftParen a -> a
    TkRightParen a -> a
    TkLeftBrace a -> a
    TkRightBrace a -> a
    TkLt a -> a
    TkLte a -> a
    TkEq a -> a
    TkDoubleEq a -> a
    TkGt a -> a
    TkGte a -> a
    TkContinued _ a -> a
    TkColon a -> a
    TkSemicolon a -> a
    TkComma a -> a
    TkDot a -> a
    TkComment _ a -> a
    TkStar a -> a
    TkDoubleStar a -> a
    TkSlash a -> a
    TkDoubleSlash a -> a
    TkPercent a -> a
    TkShiftLeft a -> a
    TkShiftRight a -> a