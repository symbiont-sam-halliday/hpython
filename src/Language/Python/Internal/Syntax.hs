{-|
Module      : Language.Python.Internal.Syntax
Copyright   : (C) CSIRO 2017-2018
License     : BSD3
Maintainer  : Isaac Elliott <isaace71295@gmail.com>
Stability   : experimental
Portability : non-portable
-}

module Language.Python.Internal.Syntax
  ( reservedWords
  , idStyle
  , reserved
  )
where

import Control.Applicative ((<|>))
import GHC.Exts (fromList)
import Text.Parser.Char (CharParsing, char, letter, digit)
import Text.Parser.Token (TokenParsing, IdentifierStyle(..), Unspaced(..), reserve)
import Text.Parser.Token.Highlight (Highlight(..))

reservedWords :: [String]
reservedWords =
  [ "False"
  , "class"
  , "finally"
  , "is"
  , "return"
  , "None"
  , "continue"
  , "for"
  , "lambda"
  , "try"
  , "True"
  , "def"
  , "from"
  , "nonlocal"
  , "while"
  , "and"
  , "del"
  , "global"
  , "not"
  , "with"
  , "as"
  , "elif"
  , "if"
  , "or"
  , "yield"
  , "assert"
  , "else"
  , "import"
  , "pass"
  , "break"
  , "except"
  , "in"
  , "raise"
  ]

idStyle :: CharParsing m => IdentifierStyle (Unspaced m)
idStyle =
  IdentifierStyle
  { _styleName = "identifier"
  , _styleStart = letter <|> char '_'
  , _styleLetter = letter <|> char '_' <|> digit
  , _styleReserved = fromList reservedWords
  , _styleHighlight = Identifier
  , _styleReservedHighlight = ReservedIdentifier
  }

reserved :: (TokenParsing m, Monad m) => String -> m ()
reserved s = runUnspaced $ reserve idStyle s
