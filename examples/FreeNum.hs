{-# LANGUAGE FlexibleInstances, TemplateHaskell, TypeFamilies, DeriveFunctor, DeriveFoldable, DeriveTraversable #-}
module FreeNum where

import Data.Functor.Free
import Data.Algebra


deriveInstance [t| () => Num (Free Num a) |]


x, y :: Free Num String
x = return "x"
y = return "y"

expr :: Free Num String
expr = 1 + x * (3 - y)

-- Monadic bind is variable substitution
subst :: Free Num String -> Free Num a
subst e = e >>= \v -> case v of 
  "x" -> 10
  _   -> 2

-- Closed expressions can be evaluated to any other instance of Num
result :: Int
result = convertClosed (subst expr)