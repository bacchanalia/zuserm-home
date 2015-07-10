#!/usr/bin/runghc
import KitchenSink
import Prelude ()

main = do
  sink   <- head . words . fromMaybe (error noUSB) . listToMaybe
          . filter (("usb" `isInfixOf`) . map toLower)
          . lines <$> readProcess "pactl" ["list","short","sinks"] ""
  inputs <- map (head . words)
          . lines <$> readProcess "pactl" ["list","short","sink-inputs"] ""
  rawSystem "pactl" ["set-default-sink",sink]
  forM_ inputs $ \input -> rawSystem "pactl" ["move-sink-input",input,sink]
  where
    noUSB = "no USB sound card detected"
