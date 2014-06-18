import qualified Widgets as W
import Color (Color(..), hexColor)
import WMLog (WMLogConfig(..))
import Utils (colW)

import Graphics.UI.Gtk.General.RcStyle (rcParseString)
import System.Taffybar (defaultTaffybar, defaultTaffybarConfig,
  barHeight, widgetSpacing, startWidgets, endWidgets)

main = do
  let cfg = defaultTaffybarConfig {barHeight=36, widgetSpacing=5}
      font = "Inconsolata medium 12"
      fgColor = hexColor $ RGB (0x93/0xff, 0xa1/0xff, 0xa1/0xff)
      bgColor = hexColor $ RGB (0x00/0xff, 0x2b/0xff, 0x36/0xff)
      textColor = hexColor $ Black
      sep = W.sepW Black 2

      start = [ W.wmLogNew WMLogConfig
                { titleLength = 30
                , wsImageHeight = 20
                , titleRows = True
                , stackWsTitle = False
                , wsBorderColor = RGB (0x58/0xff, 0x6e/0xff, 0x75/0xff)
                }
              ]
      end = reverse
          [ W.monitorCpuW
          , W.monitorMemW
          , W.progressBarW
          , W.fcrondynW
          , sep
          , W.netStatsW
          , sep
          , W.netW
          , W.widthScreenWrapW 0.165972 =<< W.klompW
          , W.volumeW
          , W.micW
          , W.pidginPipeW $ barHeight cfg
          , W.thunderbirdW (barHeight cfg) Green Black
          -- , W.ekigaW
          -- , W.cpuIntelPstateW
          , W.cpuFreqsW
          -- , W.fanW
          , W.brightnessW
          , colW [ W.pingMonitorW "G" "www.google.com" ]
          , W.tpBattStatW $ barHeight cfg
          , sep
          , W.clockW
          ]

  rcParseString $ ""
        ++ "style \"default\" {"
        ++ "  font_name = \"" ++ font ++ "\""
        ++ "  bg[NORMAL] = \"" ++ bgColor ++ "\""
        ++ "  fg[NORMAL] = \"" ++ fgColor ++ "\""
        ++ "  text[NORMAL] = \"" ++ textColor ++ "\""
        ++ "}"
  defaultTaffybar cfg {startWidgets=start, endWidgets=end}
