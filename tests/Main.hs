{-# LANGUAGE ConstraintKinds       #-}
{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeApplications      #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE TypeOperators         #-}

module Main where

import           SizedGrid.Coord
import           SizedGrid.Coord.Class
import           SizedGrid.Coord.HardWrap
import           SizedGrid.Coord.Periodic
import           SizedGrid.Grid.Grid

import           Test.Utils

import           Data.Functor.Rep
import           Generics.SOP             hiding (S, Z)
import           GHC.TypeLits
import qualified GHC.TypeLits             as GHC
import           Hedgehog
import qualified Hedgehog.Gen             as Gen
import qualified Hedgehog.Range           as Range
import           Test.Tasty
import           Test.Tasty.Hedgehog

genPeriodic :: (1 <= n, GHC.KnownNat n) => Gen (Periodic n)
genPeriodic = Periodic <$> Gen.enumBounded

genCoord :: SListI cs => NP Gen cs -> Gen (Coord cs)
genCoord start = Coord <$> hsequence start

gridTests ::
       forall cs a.
       ( Show (Coord cs)
       , Eq (Coord cs)
       , All IsCoord cs
       , GHC.KnownNat (MaxCoordSize cs)
       , Show a
       , Eq a
       , AllGridSizeKnown cs
       )
    => Gen (Coord cs)
    -> Gen a
    -> [TestTree]
gridTests genC genA =
    let tabulateIndex =
            property $ do
                c <- forAll genC
                c === index (tabulate id :: Grid cs (Coord cs)) c
        collapseUnCollapse = property $ do
                g :: Grid cs a <- forAll (sequenceA $ pure genA)
                Just g === gridFromList (collapseGrid g)
    in [testProperty "Tabulate index" tabulateIndex, testProperty "Collapse UnCollapse" collapseUnCollapse]

main :: IO ()
main =
    let periodic =
            let g :: Gen (Periodic 10) = genPeriodic
            in [ semigroupLaws g
               , monoidLaws g
               , additiveGroupLaws g
               , affineSpaceLaws g
               , aesonLaws g
               ]
        hardWrap =
            let g :: Gen (HardWrap 10) = HardWrap <$> Gen.enumBounded
            in [semigroupLaws g, monoidLaws g, affineSpaceLaws g, aesonLaws g]
        coord =
            let g :: Gen (Coord '[ HardWrap 10, Periodic 20]) =
                    genCoord
                        ((HardWrap <$> Gen.enumBounded) :*
                         (Periodic <$> Gen.enumBounded) :*
                         Nil)
            in [semigroupLaws g, monoidLaws g, affineSpaceLaws g, aesonLaws g]
        coord2 =
            let g :: Gen (Coord '[ Periodic 10, Periodic 20]) =
                    genCoord
                        ((Periodic <$> Gen.enumBounded) :*
                         (Periodic <$> Gen.enumBounded) :*
                         Nil)
            in [ semigroupLaws g
               , monoidLaws g
               , affineSpaceLaws g
               , additiveGroupLaws g
               , aesonLaws g
               ]
    in defaultMain $
       testGroup
           "tests"
           [ testGroup "Periodic 20" periodic
           , testGroup "HardWrap 20" hardWrap
           , testGroup "Coord [HardWrap 10, Periodic 20]" coord
           , testGroup "Coord [Periodic 10, Periodic 20]" coord2
           , testGroup
                 "Grid"
                 ((gridTests @'[ Periodic 10, Periodic 10]
                   (genCoord $
                   (Periodic <$> Gen.enumBounded) :*
                   (Periodic <$> Gen.enumBounded) :*
                   Nil)) (Gen.int $ Range.linear 0 100) ++
                  [ applicativeLaws
                        (Proxy @(Grid '[ Periodic 10, Periodic 10]))
                        (Gen.int $ Range.linear 0 100)
                  , aesonLaws (sequenceA $ pure @(Grid '[Periodic 10, Periodic 10] ) $
                      Gen.int $ Range.linear 0 100)
                  ])
           ]
