{-# LANGUAGE TemplateHaskell #-}
import Bindings
import Bindings.Writer
import StaticAssert

import XMonad hiding ( (|||) )
import XMonad.Layout.LayoutCombinators ( (|||), JumpToLayout(..))

import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.ManageDocks (avoidStruts, SetStruts(..), manageDocks)
import XMonad.Layout.Named (named)
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Util.Types (Direction2D(U,D,L,R))

import qualified XMonad.StackSet as Stk

import System.Taffybar.Hooks.PagerHints (pagerHints)

import Control.Concurrent (threadDelay)
import Data.List (isInfixOf)

staticAssert (null mouseOverlaps && null keyOverlaps) . execWriter $ do
    tell "Error: Overlap in bindings\n"
    let pretty = tell . unlines . map ((replicate 8 ' ' ++) . show . map fst)
    pretty mouseOverlaps
    pretty keyOverlaps

main = xmonad . ewmh . pagerHints $ defaultConfig
    { focusFollowsMouse  = False
    , normalBorderColor  = "#93a1a1"
    , focusedBorderColor = "#dc322f"
    , borderWidth        = 2

    , startupHook        = myStartupHook
    , manageHook         = myManageHook <+> manageDocks
    , layoutHook         = myLayoutHook

    , workspaces         = workspaceNames
    , keys               = myKeyBindings
    , mouseBindings      = myMouseBindings

    -- , logHook            =
    -- , terminal           =
    -- , handleEventHook    =
    -- , modMask            =
    }

spawnUnless :: Query Bool -> String -> X ()
spawnUnless prop cmd = withWindowSet $ \ss -> do
    qs <- mapM (runQuery prop) . Stk.allWindows $ ss
    unless (or qs) $ spawn cmd

command = stringProperty "WM_COMMAND"
a =~? b = (b `isInfixOf`) `fmap` a

myStartupHook = do
    spawnUnless (className =? "Pidgin")  "sleep 3 ; pidgin"
    spawnUnless (className =? "Gnucash") "gnucash"
    spawnUnless (className =? "Icedove") "icedove"
    spawnUnless (command   =~? "TODO")   "term vim TODO/TODO"

infixr 0 ~~>
a ~~> b = tell (a --> b)

myManageHook = execWriter $ do
    className =? "Pidgin"       ~~> doShift "1"
    className =? "Gnucash"      ~~> doShift "8"
    className =? "Icedove"      ~~> doShift "9"
    command   =~? "TODO"        ~~> doShift "9"

    title =? "Close Iceweasel"  ~~> restartFF
    title =? "Close Firefox"    ~~> restartFF
    title =? "npviewer.bin"     ~~> doFull
    title =? "plugin-container" ~~> doFull

myLayoutHook = avoidStruts . smartBorders
             $   named "left" (Tall 1 incr ratio)
             ||| named "top"  (Mirror $ Tall 1 incr ratio)
             ||| named "full" Full
  where incr = 5/100 ; ratio = 50/100

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
