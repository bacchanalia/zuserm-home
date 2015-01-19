{-# LANGUAGE OverloadedStrings #-}
module Klomp(klompW, main) where
import Clickable (clickable)
import Label (labelW, mainLabel)
import Utils (fgbg, padL, padR, isRunning, chompFile, readProc)

import Codec.Binary.UTF8.String (utf8Encode, decodeString)
import Control.Applicative ((<$>), (<*>))
import Data.Csv(decodeByName, FromNamedRecord, parseNamedRecord, (.:))
import Graphics.UI.Gtk (escapeMarkup)
import qualified Data.Vector as Vector
import qualified Data.Text.Lazy as T
import Data.Text.Lazy.Encoding (encodeUtf8)

main = mainLabel klompReader
klompW = clickable clickL clickM clickR =<< labelW klompReader

rowLength = 34
gapOffset = 3
sep = "…"
raspiPrefix = "ř"
n9Prefix = "ň"

clickL = Just "klomp-term --playlist"
clickM = Just "klomp-cmd reset"
clickR = Just "klomp-cmd stop"

getKlompInfo remoteHost = do
  let ipMagic = case remoteHost of
                  "n9" -> ["n9u"]
                  "raspi" -> ["pi"]
                  _ -> []
  str <- readProc $ ipMagic ++ klompInfoCmd
  return $ case decodeByName (encodeUtf8 $ T.pack $ coerceUtf8 str) of
    Left msg -> emptyKlompInfo {errorMsg = msg}
    Right (hdr, csv) -> if Vector.length csv /= 1
                        then emptyKlompInfo {errorMsg = "rowcount != 1"}
                        else Vector.head csv

coerceUtf8 = decodeString . utf8Encode

klompReader = do
  remoteHost <- chompFile "/tmp/klomp-bar"
  running <- isRunning "klomplayer"
  klompInfo <- getKlompInfo remoteHost
  let errFmt = errorMsg klompInfo
      titFmt = T.unpack $ title klompInfo
      artFmt = T.unpack $ artist klompInfo
      albFmt = T.unpack $ artist klompInfo
      numFmt = T.unpack $ artist klompInfo
      [posFmt, lenFmt] = formatTimes $ map round [pos klompInfo, len klompInfo]
      perFmt = percent klompInfo
      plsFmt = T.unpack $ playlist klompInfo
      endFmt = if null $ T.unpack $ ended klompInfo then "" else "*ENDED*"

  let topPrefix = case remoteHost of
                    "n9" -> n9Prefix
                    "raspi" -> raspiPrefix
                    _ -> if running then "" else "x"
      botPrefix = take 1 plsFmt

  let isPrefixed = not((null topPrefix) && (null botPrefix))
      topPrefixFmt = if isPrefixed then prefixFmt topPrefix else ""
      botPrefixFmt = if isPrefixed then prefixFmt botPrefix else ""
      rowLen = if isPrefixed then rowLength - 1 else rowLength

  let top = padSquishEsc rowLen $ posFmt ++ "-" ++ errFmt ++ artFmt
      bot = padSquishEsc rowLen $ lenFmt ++ "-" ++ endFmt ++ titFmt

  return $ topPrefixFmt ++ top ++ "\n" ++ botPrefixFmt ++ bot

prefixFmt = fgbg "green" "black" . padSquishEsc 1

infoColumns = ["title", "artist", "album", "number",
               "pos", "len", "percent", "playlist", "ended"]
klompInfoCmd = ["klomp-info", "-c", "-h", "-s"] ++ infoColumns

data KlompInfo = KlompInfo { errorMsg :: !String
                           , title    :: !T.Text
                           , artist   :: !T.Text
                           , album    :: !T.Text
                           , number   :: !T.Text
                           , pos      :: !Double
                           , len      :: !Double
                           , percent  :: !Int
                           , playlist :: !T.Text
                           , ended    :: !T.Text
                           } deriving Show
instance FromNamedRecord KlompInfo where
   parseNamedRecord m = KlompInfo <$> return "" <*>
                        m .: "title" <*>
                        m .: "artist" <*>
                        m .: "album" <*>
                        m .: "number" <*>
                        m .: "pos" <*>
                        m .: "len" <*>
                        m .: "percent" <*>
                        m .: "playlist" <*>
                        m .: "ended"

emptyKlompInfo = KlompInfo {errorMsg = "",
                            title = "", artist = "", album = "", number = "",
                            pos = 0.0, len = 0.0, percent = 0,
                            playlist = "", ended = ""}


formatTimes ts = map fmt ts 
  where maxH = (maximum ts) `div` (60^2)
        maxHLen = length $ show $ maxH
        fmt t = (if maxH > 0 then h t ++ ":" else "") ++ m t ++ ":" ++ s t
        h t = padL '0' maxHLen $ show $ t `div` 60^2
        m t = padL '0' 2 $ show $ (t `mod` 60^2) `div` 60
        s t = padL '0' 2 $ show $ t `mod` 60

padSquishEsc len s = escapeMarkup $ padSquish len s

padSquish len s = padR ' ' len $ sTrim
  where strLen = length s
        sTrim = if strLen > len then beforeGap ++ sep ++ afterGap else s
        sepLen = length sep
        gapStart = (len `div` 2) - (sepLen `div` 2) + gapOffset
        gapLength = strLen - len + sepLen
        beforeGap = take (gapStart-1) s
        afterGap = drop (gapStart - 1 + gapLength) s
