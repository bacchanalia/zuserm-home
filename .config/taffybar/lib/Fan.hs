module Fan(fanW) where
import Label (labelW, mainLabel)
import Utils (fg, bg, padL, regexGroups,
  readInt, readDouble, chompFile, readProc)
import Data.Maybe (fromMaybe)

main = mainLabel fanReader
fanW = labelW fanReader

width = 2

fanDev = "/proc/acpi/ibm/fan"

fanReader = do
  info <- chompFile fanDev
  acpiInfo <- readProc ["acpi", "-V"]
  let temp = parseCpuTemp acpiInfo
  let (status, speed, level) = parseFanInfo info
  return $ formatScaling temp status speed level

parseCpuTemp acpiInfo = fromMaybe 0 $ readDouble $ grps!!0
  where re = ", (\\d+\\.\\d+) degrees C"
        grps = fromMaybe [] $ regexGroups re acpiInfo

parseFanInfo info = (grps!!0, fromMaybe 0 $ readInt $ grps!!1, grps!!2)
  where re = ""
             ++ "status:\\s*(.*)\\n?"
             ++ "speed:\\s*(\\d+)\\n?"
             ++ "level:\\s*(.*)\\n?"
        grps = fromMaybe [] $ regexGroups re info

formatScaling temp status speed level = col $ (pad tmp) ++ "\n" ++ (pad spd)
  where col = color level
        pad = padL '0' width . take width
        spd = take 2 $ if speed == 65535 then "FF" else show $ speed`div`100
        tmp = take 2 $ show temp

color level = case level of
                "auto"       -> fg "#268bd2"
                "disengaged" -> fg "white"
                "0"          -> bg "red" . fg "#002b36"
                "7"          -> bg "black" . fg "white"
                _            -> bg "orange" . fg "#002b36"
