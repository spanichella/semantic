{-# LANGUAGE OverloadedLists, TypeApplications #-}
module Analysis.Python.Spec (spec) where

import Data.Abstract.Value
import Data.Map

import SpecHelpers


spec :: Spec
spec = parallel $ do
  describe "evalutes Python" $ do
    it "imports" $ do
      env <- environment . snd <$> evaluate "main.py"
      env `shouldBe` [ (qualifiedName ["a", "foo"], addr 0)
                     , (qualifiedName ["b", "c", "baz"], addr 1)
                     ]

    it "imports with aliases" $ do
      env <- environment . snd <$> evaluate "main1.py"
      env `shouldBe` [ (qualifiedName ["b", "foo"], addr 0)
                     , (qualifiedName ["e", "baz"], addr 1)
                     ]

    it "imports using 'from' syntax" $ do
      env <- environment . snd <$> evaluate "main2.py"
      env `shouldBe` [ (qualifiedName ["foo"], addr 0)
                     , (qualifiedName ["bar"], addr 1)
                     ]

    it "subclasses" $ do
      v <- fst <$> evaluate "subclass.py"
      v `shouldBe` Right (Right (Right (injValue (String "\"bar\""))))

    it "handles multiple inheritance left-to-right" $ do
      v <- fst <$> evaluate "multiple_inheritance.py"
      v `shouldBe` Right (Right (Right (injValue (String "\"foo!\""))))

  where
    addr = Address . Precise
    fixtures = "test/fixtures/python/analysis/"
    evaluate entry = evaluateFiles pythonParser
      [ fixtures <> entry
      , fixtures <> "a.py"
      , fixtures <> "b/c.py"
      ]
