{-# language DeriveFoldable #-}
{-# language DeriveFunctor #-}
{-# language DeriveTraversable #-}
{-# language TemplateHaskell #-}
module Language.Python.AST.Float where

import Papa
import Data.Deriving
import Data.Functor.Compose
import Data.Separated.Before

import Language.Python.AST.Digits
import Language.Python.AST.Symbols

data Float' a
  = FloatNoDecimal
  { _floatNoDecimal_base :: NonEmpty Digit
  , _float_exponent
    :: Maybe (Before (Either Char_e Char_E) (NonEmpty Digit))
  , _float_ann :: a
  }
  | FloatDecimalNoBase
  { _floatDecimalNoBase_fraction :: NonEmpty Digit
  , _float_exponent
    :: Maybe (Before (Either Char_e Char_E) (NonEmpty Digit))
  , _float_ann :: a
  }
  | FloatDecimalBase
  { _floatDecimalBase_base :: NonEmpty Digit
  , _floatDecimalBase_fraction :: Compose Maybe NonEmpty Digit
  , _float_exponent
    :: Maybe (Before (Either Char_e Char_E) (NonEmpty Digit))
  , _float_ann :: a
  }
  deriving (Functor, Foldable, Traversable)

deriveEq1 ''NonEmpty
deriveShow1 ''NonEmpty

deriveEq ''Float'
deriveShow ''Float'
deriveEq1 ''Float'
deriveShow1 ''Float'
makeLenses ''Float'