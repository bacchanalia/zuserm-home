{-# LANGUAGE OverloadedStrings #-}
import qualified Widgets as W
import Color (Color(..), hexColor)
import DBusUtils
import WMLog (WMLogConfig(..))
import Utils

import Graphics.UI.Gtk.General.RcStyle (rcParseString)
import System.Taffybar (defaultTaffybar, defaultTaffybarConfig,
  barHeight, barPosition, widgetSpacing, startWidgets, endWidgets,
  Position(Top, Bottom))

import Control.Applicative
import System.Environment (getArgs)

profile = profileFHD

profileFHD = P { height = 36
               , spacing = 5
               , titleLen = 30
               , typeface = "Inconsolata medium"
               , fontSizePt = 12.0
               , graphWidth = 50
               , workspaceImageHeight = 20
               }

main = do
  isBot <- elem "--bottom" <$> getArgs
  dbc <- dbusConnect
  let cfg = defaultTaffybarConfig { barHeight=height profile
                                  , widgetSpacing= spacing profile
                                  , barPosition=if isBot then Bottom else Top
                                  }
      font = (typeface profile) ++ " " ++ show (fontSizePt profile)
      fgColor = hexColor $ RGB (0x93/0xff, 0xa1/0xff, 0xa1/0xff)
      bgColor = hexColor $ RGB (0x00/0xff, 0x2b/0xff, 0x36/0xff)
      textColor = hexColor $ Black
      addSeperators = concatMap (++ [W.sepW Black 2])

      start = addSeperators . return $
              [W.wmLogNew WMLogConfig
                { titleLength = titleLen profile
                , wsImageHeight = workspaceImageHeight profile
                , titleRows = True
                , stackWsTitle = False
                , wsBorderColor = RGB (0x58/0xff, 0x6e/0xff, 0x75/0xff)
                }
              ]
      end = addSeperators . map reverse . reverse $
          [ [W.progressBarW, W.fcrondynW]
          , [ W.widthScreenWrapW (1/6) =<< W.klompW
            , W.volumeW
            , W.micW
            , colW [ W.paSinkW   dbc sinks (Just "U")
                   , W.paSourceW dbc sources Nothing]]
          , [ W.netW
            , W.pingMonitorW "G" "8.8.8.8"
            , W.netStatsW
            , W.pidginPipeW $ barHeight cfg
            , W.thunderbirdW (barHeight cfg) Green Black]
            -- , [W.ekigaW]
          , [W.monitorCpuW $ graphWidth profile, W.monitorMemW $ graphWidth profile],
          , [ W.cpuFreqsW
            -- , W.fanW
            -- , [W.cpuIntelPstateW]
            , W.brightnessW
            , W.tpBattStatW $ barHeight cfg]
          , [W.clockW]
          ]

  rcParseString $ ""
        ++ "style \"default\" {"
        ++ "  font_name = \"" ++ font ++ "\""
        ++ "  bg[NORMAL] = \"" ++ bgColor ++ "\""
        ++ "  fg[NORMAL] = \"" ++ fgColor ++ "\""
        ++ "  text[NORMAL] = \"" ++ textColor ++ "\""
        ++ "}"

  defaultTaffybar cfg {startWidgets=start, endWidgets=end}

sinks =
  [ ("B", "alsa_output.pci-0000_00_1b.0.analog-stereo")
  , ("U", "alsa_output.usb-Generic_Turtle_Beach_USB_Audio_0000000001-00.analog-stereo")
  , ("H", "alsa_output.pci-0000_00_03.0.hdmi-stereo")
  ]
sources =
  [ ("B", "alsa_input.pci-0000_00_1b.0.analog-stereo")
  , ("U", "alsa_input.usb-Generic_Turtle_Beach_USB_Audio_0000000001-00.analog-stereo")
  ]

data Profile = P { height :: Int
                 , spacing :: Int
                 , titleLen :: Int
                 , typeface :: String
                 , fontSizePt :: Double
                 , graphWidth :: Int
                 , workspaceImageHeight :: Int
                 }
