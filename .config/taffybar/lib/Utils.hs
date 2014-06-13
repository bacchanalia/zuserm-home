module Utils(
  defaultDelay, imageDir,
  fg, bg, fgbg,
  rowW, colW, containerW,
  regexMatch, regexAllMatches, regexGroups, regexFirstGroup,
  readInt, readDouble, collectInts, padL, padR, chompAll,
  tryMaybe, nanoTime, isRunning, chompFile, findName,
  systemReadLines, readProc, chompProc, procSuccess,
  procToChan, actToChanDelay, listToChan
) where
import Prelude hiding (readFile)
import System.IO.UTF8 (readFile)
import Control.Concurrent (
  forkIO, threadDelay,
  Chan, writeChan, writeList2Chan, newChan)
import Control.Exception (SomeException, try)
import Control.Monad (forever, void)
import Graphics.UI.Gtk (
  Container, Widget, hBoxNew, vBoxNew, containerAdd,
  toWidget, toContainer, widgetShowAll)
import System.Exit(ExitCode(ExitFailure), ExitCode(ExitSuccess))
import System.Directory (doesFileExist)
import Text.Regex.PCRE ((=~))
import Data.Maybe (catMaybes, fromMaybe, listToMaybe)
import System.Environment (getEnv)
import System.FilePath.Find (
  (||?), (&&?), (==?), (~~?), (/=?),
  find, filePath, fileName, depth)
import System.IO (
  stderr, hGetContents, hGetLine, hPutStrLn,
  hSetBuffering, BufferMode(LineBuffering))
import System.Process (
  StdStream(CreatePipe), std_out, createProcess, proc, shell,
  system)
import ProcUtil ( readProcessWithExitCode' )
import System.Posix.Clock (timeSpecToInt64, monotonicClock, getClockTime)

-- CONSTANTS
defaultDelay :: Double
defaultDelay = 1

imageDir h = do
  home <- getEnv "HOME"
  return $ home ++ "/.config/taffybar/icons/" ++ show h

-- MARKUP
fg color m = "<span foreground=\"" ++ color ++ "\">" ++ m ++ "</span>"
bg color m = "<span background=\"" ++ color ++ "\">" ++ m ++ "</span>"
fgbg fg bg m = "<span"
               ++ " foreground=\"" ++ fg ++ "\""
               ++ " background=\"" ++ bg ++ "\""
               ++ ">" ++ m ++ "</span>"

-- WIDGETS
rowW :: [IO Widget] -> IO Widget
rowW widgets = containerW widgets =<< toContainer `fmap` hBoxNew False 0

colW :: [IO Widget] -> IO Widget
colW widgets = containerW widgets =<< toContainer `fmap` vBoxNew False 0

containerW :: [IO Widget] -> Container -> IO Widget
containerW widgets box = do
  ws <- sequence widgets
  mapM_ (containerAdd box) ws
  widgetShowAll box
  return $ toWidget box

-- PARSING
regexMatch :: String -> String -> Bool
regexMatch = flip (=~)
regexGroups :: String -> String -> Maybe [String]
regexGroups re str = fmap (drop 1) $ listToMaybe $ str =~ re
regexFirstGroup :: String -> String -> Maybe String
regexFirstGroup re str = listToMaybe $ fromMaybe [] $ regexGroups re str
regexAllMatches :: String -> String -> [String]
regexAllMatches re str = concatMap (take 1) $ str =~ re

readInt :: String -> Maybe Integer
readInt s = case reads s of
              ((x,_):_) -> Just x
              _ -> Nothing

readDouble :: String -> Maybe Double
readDouble s = case reads s of
              ((x,_):_) -> Just x
              _ -> Nothing

collectInts :: String -> [Integer]
collectInts = catMaybes . (map readInt) . (regexAllMatches "\\d+")

padL x len xs = replicate (len - length xs) x ++ xs
padR x len xs = xs ++ replicate (len - length xs) x

chompAll = reverse . dropWhile (== '\n') . reverse

-- IO
tryMaybe :: (IO a) -> IO (Maybe a)
tryMaybe act = do
  result <- (try :: IO a -> IO (Either SomeException a)) act
  case result of
    Left ex  -> do
      hPutStrLn stderr $ show ex
      return Nothing
    Right val -> return $ Just val


nanoTime :: IO Integer
nanoTime = fmap (fromIntegral . timeSpecToInt64) $ getClockTime monotonicClock

isRunning :: String -> IO Bool
isRunning p = do
  running <- system $ "pgrep " ++ p ++ " > /dev/null 2>/dev/null"
  return $ case running of
    ExitFailure _ -> False
    otherwise -> True

--rough equivalent to:
--  recurse: find DIR -name PTRN
--  not recurse: find DIR -maxdepth 1 -name PTRN
findName :: FilePath -> Bool -> String -> IO [FilePath]
findName dir recurse ptrn = find rec match dir
  where rec = return recurse ||? depth ==? 0
        match = fileName ~~? ptrn &&? filePath /=? dir

chompFile :: FilePath -> IO String
chompFile file = do
  curExists <- doesFileExist file
  if curExists then fmap chompAll $ readFile file else return ""

systemReadLines :: String -> IO [String]
systemReadLines cmd = fmap lines $ sys >>= \(_,Just h,_,_) -> lineBufContent h
  where sys = createProcess (shell cmd) {std_out = CreatePipe}
        lineBufContent h = hSetBuffering h LineBuffering >> hGetContents h

readProc (cmd:args) = fmap snd3 $ readProcessWithExitCode' cmd args ""
  where snd3 (_,x,_) = x

chompProc = fmap chompAll . readProc

procSuccess (cmd:args) = do
  (exitCode,_,_) <- readProcessWithExitCode' cmd args ""
  return $ exitCode == ExitSuccess

procToHandle (cmd:args) = do
  (_,Just out,_,_) <- createProcess (proc cmd args) {std_out=CreatePipe}
  return out

procToChan cmdarr = do
  out <- procToHandle cmdarr
  hSetBuffering out LineBuffering
  chan <- newChan
  forkIO . forever $ writeChan chan =<< hGetLine out
  return chan

actToChanDelay :: Int -> IO a -> IO (Chan a)
actToChanDelay delayMicro act = do
  chan <- newChan
  forkIO $ forever $ do
    start <- nanoTime
    act >>= writeChan chan
    end <- nanoTime
    let elapsedMicro = (fromIntegral $ end - start) `div` 10^3
    threadDelay $ delayMicro - elapsedMicro
  return chan

listToChan :: [a] -> IO (Chan a)
listToChan xs = newChan >>= (\c -> forkIO (writeList2Chan c xs) >> return c)
