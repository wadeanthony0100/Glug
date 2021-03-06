{-# LANGUAGE FlexibleContexts #-}

module Glug.SrtExtract (
  parseSrtFromZip
)
where

import qualified Data.Text.Lazy as T
import qualified Data.Text.Lazy.Encoding as Enc
import qualified Data.Text.Encoding.Error as Enc
import qualified Data.ByteString.Lazy as B
import qualified Codec.Archive.Zip as Z
import qualified Text.Subtitles.SRT as SRT

import Data.List (find)
import Data.Attoparsec.Text (parseOnly)
import Control.Applicative ((<|>))
import Control.Exception (try, evaluate)
import Control.Monad.Except (MonadError, catchError, throwError)
import System.IO.Unsafe (unsafeDupablePerformIO)


parseSrtFromZip :: MonadError String m => B.ByteString -> m SRT.Subtitles
parseSrtFromZip zipbs = getSrtBS zipbs >>= bsToSubs


bsToSubs :: MonadError String m => B.ByteString -> m SRT.Subtitles
bsToSubs bs = do
    t <- tag "decoding" . fromEither . eitherShow . decode' $ bs
    tag "using srt parser" . fromEither . parseOnly SRT.parseSRT . T.toStrict $ t
  where bom = B.unpack $ B.take 3 bs
        decode | (take 2 bom) == [0xFE, 0xFF] = Enc.decodeUtf16BE . B.drop 2
               | (take 2 bom) == [0xFF, 0xFE] = Enc.decodeUtf16LE . B.drop 2
               | bom == [0xEF, 0xBB, 0xBF]    = Enc.decodeUtf8 . B.drop 3
               | otherwise                    = Enc.decodeUtf8
        decode' :: B.ByteString -> Either Enc.UnicodeException T.Text
        decode' = unsafeDupablePerformIO . try . evaluate . decode -- D:


getSrtBS :: MonadError String m => B.ByteString -> m B.ByteString
getSrtBS bs = do
    arch <- fromEither . tag "converting to archive" $ Z.toArchiveOrFail bs
    entry <- fromEither . tag "getting entry" $ getEntry arch
    return $ Z.fromEntry entry


getEntry :: MonadError String m => Z.Archive -> m Z.Entry
getEntry arch = do
    fname <- fromMaybe "could not find srt" $ fp <|> fp'
    fromMaybe "this shouldn't happen: no entry found" (Z.findEntryByPath fname arch)
  where fp = find (\s -> endsIn s "eng.srt") (Z.filesInArchive arch)
        fp' = find (\s -> endsIn s ".srt") (Z.filesInArchive arch)


endsIn :: String -> String -> Bool
endsIn []     [] = True
endsIn (_:_)  [] = False
endsIn []  (_:_) = False
endsIn (x:xs) (y:ys) = (x == y && endsIn xs ys) || endsIn xs (y:ys)


eitherShow :: Show a => Either a b -> Either String b
eitherShow (Left x) = Left (show x)
eitherShow (Right x) = Right x


tag :: MonadError String m => String -> m a -> m a
tag s m = m `catchError` (\e -> throwError $ "[" ++ s ++ "] " ++ e)


fromMaybe :: MonadError String m => String -> Maybe b -> m b
fromMaybe s Nothing = throwError s
fromMaybe _ (Just x) = return x


fromEither :: MonadError String m => Either String a -> m a
fromEither (Left e) = throwError e
fromEither (Right x) = return x
