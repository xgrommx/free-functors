{-# LANGUAGE FlexibleInstances #-}
module FreeNum where

import Data.Functor.Free

import Control.Applicative

instance Num (Free Num a) where
  Free l + Free r = Free $ (+) <$> l <*> r
  Free l * Free r = Free $ (*) <$> l <*> r
  Free l - Free r = Free $ (-) <$> l <*> r
  negate (Free f) = Free $ negate <$> f
  abs (Free f)    = Free $ abs <$> f
  signum (Free f) = Free $ signum <$> f
  fromInteger i   = Free $ pure (fromInteger i)

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