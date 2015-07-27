module PidginPipe(pidginPipeW) where
import Clickable (clickableAsync)
import Label (mainLabel)
import Image (imageW)
import System.Environment (getEnv)
import Control.Monad (forever)
import Data.Char (toLower)
import Utils (ifM, imageDir, chompAll, isRunning, chompFile)

main = mainLabel $ getImage 0
pidginPipeW h = clickableAsync clickL clickM clickR =<< imageW (getImage h)

exec = "pidgin"
process = exec
workspace = 2

runCmd = exec
wsCmd = "wmctrl -s " ++ show (workspace-1)

clickL = ifM (isRunning process) (return $ Just wsCmd) (return $ Just runCmd)
clickM = return Nothing
clickR = return $ Just $ "pkill " ++ process

getImage h = do
  home <- getEnv "HOME"
  let pipeFile = home ++ "/.purple/plugins/pipe"

  pipe <- chompFile pipeFile
  let status = if null pipe then "off" else map toLower pipe

  pidginRunning <- if status == "off" then return False else isRunning exec

  dir <- imageDir h
  let img = if pidginRunning then imgName status else imgName "off"
  return $ dir ++ "/pidgin/" ++ img ++ ".png"

imgName status = case status of
  "off"            -> "not-running"
  "new message"    -> "pidgin-tray-pending"
  "available"      -> "pidgin-tray-available"
  "away"           -> "pidgin-tray-away"
  "do not disturb" -> "pidgin-tray-busy"
  "invisible"      -> "pidgin-tray-invisible"
  "offline"        -> "pidgin-tray-offline"
  _                -> "pidgin-tray-xa"

