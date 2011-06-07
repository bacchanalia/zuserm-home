import Bindings
import Dzen

import XMonad hiding ( (|||) )
import XMonad.Layout.LayoutCombinators ( (|||) )

import XMonad.Hooks.ManageDocks (avoidStruts)
import XMonad.Layout.Named (named)
import XMonad.Layout.NoBorders (smartBorders)

import qualified XMonad.StackSet as Stk

import Data.Monoid
import Graphics.X11.Xlib
import Graphics.X11.Xlib.Extras

myHandleEventHook _ = return (All True)
myHandleEventHook _ = return (All True)

workspaceNames = ["A", "B", "D", "G", "5", "6", "7", "8", "9"]

closeRboxWin = "xdotool search --class Rhythmbox key --window %@ ctrl+w"

main = do
  dzenKill <- spawn "killall dzen2"
  hookedDzens <- spawnHookedDzens
  unhookedDzens <- spawnUnhookedDzens
  
  xmonad $ defaultConfig {
    focusFollowsMouse  = False,
    modMask            = mod1Mask,
    workspaces         = workspaceNames,
    
    borderWidth        = 3,
    normalBorderColor  = "#dddddd",
    focusedBorderColor = "#ff0000",

    keys               = myKeyBindings,
    mouseBindings      = myMouseBindings,
  
    layoutHook         = avoidStruts $ smartBorders $
                             (named "left" $          Tall 1 (3/100) (55/100))
                         ||| (named "top"  $ Mirror $ Tall 1 (3/100) (55/100))
                         ||| (named "full" $          Full)
                         ,

    manageHook         = composeAll
                         [ className =? "Gnome-panel"    --> doIgnore
                         , className =? "Do"             --> doIgnore
                         , className =? "Eclipse"        --> doShift "A"
                         , className =? "Pidgin"         --> doShift "B"
                         , className =? "MPlayer"        --> doShift "7"
                         , className =? "Thunderbird"    --> doShiftView "8"
                         , className =? "Rhythmbox"      --> doShift "9"
                         , title     =? "xmonad-hidden"  --> doHide
                         ],

    handleEventHook    = myHandleEventHook,
    logHook            = myDzenLogHook workspaceNames hookedDzens
  }

doHide = ask >>= doF . Stk.delete
doView workspace = doF $ Stk.view workspace
doShiftView workspace = doShift workspace <+> doView workspace

