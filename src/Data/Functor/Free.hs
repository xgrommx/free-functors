{-# LANGUAGE
    ConstraintKinds
  , GADTs
  , RankNTypes
  , TypeOperators  
  , FlexibleInstances
  , MultiParamTypeClasses
  , UndecidableInstances
  , ScopedTypeVariables
  , DeriveFunctor
  , DeriveFoldable
  , DeriveTraversable
  #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Functor.Free
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  sjoerd@w3future.com
-- Stability   :  experimental
-- Portability :  non-portable
--
-- A free functor is left adjoint to a forgetful functor.
-- In this package the forgetful functor forgets class constraints.
-----------------------------------------------------------------------------
module Data.Functor.Free where
  
import Control.Applicative
import Control.Comonad

import Data.Constraint hiding (Class)
import Data.Constraint.Forall

import Data.Functor.Identity
import Data.Functor.Compose
import Data.Foldable
import Data.Traversable
import Data.Void

import Data.Algebra

-- | The free functor for constraint @c@.
newtype Free c a = Free { runFree :: forall b. c b => (a -> b) -> b }

unit :: a -> Free c a
unit a = Free $ \k -> k a

rightAdjunct :: c b => (a -> b) -> Free c a -> b
rightAdjunct f g = runFree g f

rightAdjunctF :: ForallF c f => (a -> f b) -> Free c a -> f b
rightAdjunctF = h instF rightAdjunct
  where
    h :: ForallF c f
      => (ForallF c f :- c (f b))
      -> (c (f b) => (a -> f b) -> Free c a -> f b)
      -> (a -> f b) -> Free c a -> f b
    h (Sub Dict) f = f

rightAdjunctT :: ForallT c t => (a -> t f b) -> Free c a -> t f b
rightAdjunctT = h instT rightAdjunct
  where
    h :: ForallT c t
      => (ForallT c t :- c (t f b))
      -> (c (t f b) => (a -> t f b) -> Free c a -> t f b)
      -> (a -> t f b) -> Free c a -> t f b
    h (Sub Dict) f = f

-- | @counit = rightAdjunct id@
counit :: c a => Free c a -> a
counit = rightAdjunct id

-- | @leftAdjunct f = f . unit@
leftAdjunct :: (Free c a -> b) -> a -> b
leftAdjunct f = f . unit

instance Functor (Free c) where
  fmap f (Free g) = Free (g . (. f))

instance Applicative (Free c) where
  pure = unit
  fs <*> as = Free $ \k -> runFree fs (\f -> runFree as (k . f))

instance ForallF c (Free c) => Monad (Free c) where
  return = unit
  (>>=) = flip rightAdjunctF

instance (ForallF c Identity, ForallF c (Free c), ForallF c (Compose (Free c) (Free c)))
  => Comonad (Free c) where
  extract = runIdentity . rightAdjunctF Identity
  extend g = fmap g . getCompose . rightAdjunctF (Compose . return . return)

instance c ~ Class f => Algebra f (Free c a) where
  algebra fa = Free $ \k -> evaluate (fmap (rightAdjunct k) fa)

newtype LiftAFree c f a = LiftAFree { getLiftAFree :: f (Free c a) }

instance (Applicative f, c ~ Class s) => Algebra s (LiftAFree c f a) where
  algebra = LiftAFree . fmap algebra . traverse getLiftAFree

instance ForallT c (LiftAFree c) => Foldable (Free c) where
  foldMap = foldMapDefault

instance ForallT c (LiftAFree c) => Traversable (Free c) where
  traverse f = getLiftAFree . rightAdjunctT (LiftAFree . fmap pure . f)

convert :: (c (f a), Applicative f) => Free c a -> f a
convert = rightAdjunct pure

convertClosed :: c r => Free c Void -> r
convertClosed = rightAdjunct absurd

type InitialObject c = Free c Void

initial :: c r => InitialObject c -> r
initial = rightAdjunct absurd

type Coproduct c m n = Free c (Either m n)

coproduct :: c r => (m -> r) -> (n -> r) -> Coproduct c m n -> r
coproduct m n = rightAdjunct (either m n)

inL :: c m => m -> Coproduct c m n
inL = unit . Left

inR :: c n => n -> Coproduct c m n
inR = unit . Right

product :: (r -> m) -> (r -> n) -> r -> Free c (m, n)
product m n r = unit (m r, n r)

fstP :: c m => Free c (m, n) -> m
fstP = rightAdjunct fst

sndP :: c n => Free c (m, n) -> n
sndP = rightAdjunct snd