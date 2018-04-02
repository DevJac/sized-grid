module Test.Utils where

import           Data.AdditiveGroup
import           Data.Semigroup
import           Hedgehog
import qualified Hedgehog.Gen        as Gen
import qualified Hedgehog.Range      as Range
import           Test.Tasty
import           Test.Tasty.Hedgehog

semigroupLaws :: (Show a, Eq a, Semigroup a) => Gen a -> TestTree
semigroupLaws gen =
  let assoc = property $ do
         a <- forAll gen
         b <- forAll gen
         c <- forAll gen
         a <> (b <> c) === (a <> b) <> c
  in testGroup "Semigroup Laws" [testProperty "Associative" assoc]

monoidLaws :: (Show a, Eq a, Monoid a) => Gen a -> TestTree
monoidLaws gen =
  let assoc =
        property $ do
          a <- forAll gen
          b <- forAll gen
          c <- forAll gen
          mappend a (mappend b c) === mappend (mappend a b) c
      memptyId =
        property $ do
          a <- forAll gen
          a === mappend mempty a
          a === mappend a mempty
      concatIsFold =
        property $ do
          as <- forAll $ Gen.list (Range.linear 0 100) gen
          mconcat as === foldr mappend mempty as
  in testGroup
       "Monoid laws"
       [ testProperty "Associative" assoc
       , testProperty "Mempty Id" memptyId
       , testProperty "Concat is Fold" concatIsFold
       ]

additiveGroupLaws :: (Show a, Eq a, AdditiveGroup a) => Gen a -> TestTree
additiveGroupLaws gen =
  let assoc =
        property $ do
          a <- forAll gen
          b <- forAll gen
          c <- forAll gen
          a ^+^  (b ^+^ c) === (a ^+^  b) ^+^ c
      zeroId =
        property $ do
          a <- forAll gen
          a === zeroV ^+^ a
          a === a ^+^ zeroV
      inverseId = property $ do
          a <- forAll gen
          a ^-^ a === zeroV
      takeLeaves = property $ do
          a <- forAll gen
          b <- forAll gen
          a ^-^ (a ^-^ b) === b
  in testGroup
       "AdditiveGroup laws"
       [ testProperty "Associative" assoc
       , testProperty "Zero Id" zeroId
       , testProperty "Inverse id is zeroV" inverseId
       , testProperty "a - (a - b) = b" takeLeaves
       ]