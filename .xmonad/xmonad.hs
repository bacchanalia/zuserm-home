{-# LANGUAGE TemplateHaskell #-}
import Bindings
import Bindings.Writer
import StaticAssert

import XMonad hiding ( (|||) )
import XMonad.Layout.LayoutCombinators ( (|||), JumpToLayout(..))

import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.ManageDocks (avoidStruts, SetStruts(..), manageDocks)
import XMonad.Hooks.ManageHelpers (doFullFloat, isFullscreen)
import XMonad.Layout.Named (named)
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Util.Types (Direction2D(U,D,L,R))

import qualified XMonad.StackSet as Stk

import System.Taffybar.Hooks.PagerHints (pagerHints)

import Control.Applicative ((<$>))
import Control.Concurrent (threadDelay)
import Control.Monad (when)
import Data.List (isInfixOf)
import Data.Monoid (All (All))
import System.FilePath ((</>))
import System.Directory (getHomeDirectory)

staticAssert (null mouseOverlaps && null keyOverlaps) . execWriter $ do
    tell "Error: Overlap in bindings\n"
    let pretty = tell . unlines . map ((replicate 8 ' ' ++) . show . map fst)
    pretty mouseOverlaps
    pretty keyOverlaps

main = xmonad . ewmh . pagerHints . addStartUps $ defaultConfig
    { focusFollowsMouse  = False
    , normalBorderColor  = "#93a1a1"
    , focusedBorderColor = "#dc322f"
    , borderWidth        = 2

    , handleEventHook    = myEventHook
    , startupHook        = myStartupHook
    , layoutHook         = myLayoutHook
    , manageHook         = myManageHook <+> manageDocks

    , workspaces         = workspaceNames
    , keys               = myKeyBindings
    , mouseBindings      = myMouseBindings

    -- , logHook            =
    -- , terminal           =
    -- , handleEventHook    =
    -- , modMask            =
    }

relToHomeDir file = (</> file) <$> getHomeDirectory

spawnUnless :: Query Bool -> String -> X ()
spawnUnless prop cmd = withWindowSet $ \ss -> do
    qs <- mapM (runQuery prop) . Stk.allWindows $ ss
    unless (or qs) $ spawn cmd


command = stringProperty "WM_COMMAND"
a =~? b = (b `isInfixOf`) `fmap` a

infixr 0 ~~>
a ~~> b = tell (a --> b)

addStartUps conf = conf { startupHook = startupHook', manageHook = manageHook' }
  where
    osw ws cmd cond = tell [(ws, cmd, cond)]
    startups = execWriter $ do
        osw "1" "term vim TODO"                $ command   =~? "TODO"
        osw "1" "execPing --timeout=15 pidgin" $ className =?  "Pidgin"
        osw "9" "icedove"                      $ className =?  "Icedove"
    startupHook' = do
        forM startups $ \( _, cmd, cond) -> spawnUnless cond cmd
        startupHook conf
    manageHook' = execWriter $ do
        forM startups $ \(ws,   _, cond) -> cond ~~> doShift ws
        tell $ manageHook conf

myStartupHook = do
    io $ tryWriteKeyBindingsCache =<< relToHomeDir ".cache/xmonad-bindings"

myLayoutHook = avoidStruts . smartBorders
             $   named "left" (Tall 1 incr ratio)
             ||| named "top"  (Mirror $ Tall 1 incr ratio)
             ||| named "full" Full
  where incr = 5/100 ; ratio = 50/100

myManageHook = execWriter $ do
    isFullscreen                      ~~> doFullFloat
    title =? "Close Iceweasel"        ~~> restartFF
    title =? "Close Firefox"          ~~> restartFF
    title =? "npviewer.bin"           ~~> doFloat
    title =? "plugin-container"       ~~> doFloat
    title =? "Assault Android Cactus" ~~> doFloat

restartFF = do
    w <- ask
    let delay = 1
    liftX $ do
        killWindow w
        io . threadDelay $ delay*10^6
        let msg = "'restarting firefox in " ++ show delay ++ "s'"
        spawn $ "notify-send -t 3000 " ++ msg
        spawn "firefox"
        refresh
    doF id

doFull = do
    liftX . sendMessage $ removeStruts
    liftX . sendMessage $ JumpToLayout "full"
    doF id
    -- TODO: add layout to extensible state,
    --       add event hook to restore layout when window closes
    --       first step, just restore defaut layout then window closes


addStruts = SetStruts [U,D,L,R] []
removeStruts = SetStruts [] [U,D,L,R]

doView workspace = doF $ Stk.view workspace
doShiftView workspace = doShift workspace <+> doView workspace


-- Helper functions to fullscreen the window
fullFloat, tileWin :: Window -> X ()
fullFloat w = windows $ Stk.float w r
    where r = Stk.RationalRect 0 0 1 1
tileWin w = windows $ Stk.sink w

myEventHook :: Event -> X All
myEventHook (ClientMessageEvent _ _ _ dpy win typ dat) = do
  state <- getAtom "_NET_WM_STATE"
  fullsc <- getAtom "_NET_WM_STATE_FULLSCREEN"
  isFull <- runQuery isFullscreen win

  -- Constants for the _NET_WM_STATE protocol
  let remove = 0
      add = 1
      toggle = 2

      -- The ATOM property type for changeProperty
      ptype = 4

      action = head dat

  when (typ == state && (fromIntegral fullsc) `elem` tail dat) $ do
    when (action == add || (action == toggle && not isFull)) $ do
         io $ changeProperty32 dpy win state ptype propModeReplace [fromIntegral fullsc]
         fullFloat win
    when (head dat == remove || (action == toggle && isFull)) $ do
         io $ changeProperty32 dpy win state ptype propModeReplace []
         tileWin win

  -- It shouldn't be necessary for xmonad to do anything more with this event
  return $ All False
myEventHook _ = return $ All True
