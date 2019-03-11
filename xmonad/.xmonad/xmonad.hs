import System.IO
import System.Exit

import XMonad
import XMonad.Actions.DynamicWorkspaces
import XMonad.Actions.CycleWS
import XMonad.Actions.FloatKeys
import XMonad.Config.Desktop
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.FloatNext
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.EwmhDesktops
import XMonad.Util.NamedScratchpad
import XMonad.Layout
import XMonad.Layout.Accordion
import XMonad.Layout.NoBorders
import XMonad.Layout.ResizableTile
import XMonad.Layout.Spacing
import XMonad.Layout.Spiral
import XMonad.Util.Loggers
import XMonad.Util.NamedWindows (getName)
import XMonad.Util.Font
import XMonad.Util.Run
import Graphics.X11.ExtraTypes.XF86

import Control.Monad (forM_, join)

import Data.Char
import Data.List (sortBy)
import Data.Function (on)
import Data.Bits ((.|.))
import qualified XMonad.StackSet as W
import qualified Data.Map as M

-- DefaultTerminal: Set to succless terminal
myTerminal = "st"

-- Launcher (ie. dmenu, rofi...)
myLauncher = "dmenu_run"

-- ModKey: Set to Windows Key
modm = mod4Mask

-- Border Styling
myBorderWidth = 3
myNormalBorderColor = "#BFBFBF"
myFocusedBorderColor = "#89DDFF"

-- status bar
xmproc = "polybar main"

-- gaps (border / window spacing)
gaps = spacingRaw True (Border 0 10 10 10) True (Border 10 10 10 10) True 

workspaceIcons =
  [ "\xe17e"
  , "\xe17f"
  , "\xe180"
  , "\xe181"
  , "\xe182"
  , "\xe183"
  , "\xe184"
  , "\xe185"
  , "\xe186"
  ]

-- My Workspaces
workspaceNames =
  [ "Main"
  , "Qutebrowser"
  , "Code"
  , "Firefox"
  , "Chrome"
  , "Media"
  ]

myWorkspaces = wrapWorkspaces workspaceIcons $ workspaceNames
 where
  wrapWorkspaces icons workspaces =
    [ i ++ " " ++ ws | (i, ws) <- zip icons workspaces ]

-- Layout Hook
myLayout = sizeTall ||| spir ||| Accordion
 where
  sizeTall = ResizableTall 1 (3 / 100) (1 / 2) []
  spir     = spiral (6 / 7)

-- myManageHook
myManageHook = composeAll . concat $
  [ [className =? "qutebrowser" --> doShift " Qutebrowser"]
  , [className =? "Spotify" --> doShift " Media"]
  , [className =? "Firefox" --> doShift " Firefox"]
  , [className =? "Chromium" --> doShift " Chrome"]
  , [className =? c --> doRectFloat (W.RationalRect 0.3 0.3 0.4 0.4) | c <- floatsClass]
  , [wmName =? "sxiv" -->  doRectFloat (W.RationalRect 0.3 0.3 0.4 0.4)] 
  ]
  where
    wmName = stringProperty "WM_NAME"
    floatsClass = [ "feh"
                  , "mpv"
                  ,"VirtualBox"
                  ]

scratchpads =
  [ NS "htop" "st -t process -e htop" (title =? "process")  defaultFloating
  , NS "cmus" "st -c cmus -e cmus"    (className =? "cmus") defaultFloating
  ]

myNewManageHook = composeAll
  [ myManageHook
  , floatNextHook
  , manageHook desktopConfig
  , namedScratchpadManageHook scratchpads
  ]


myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig { XMonad.modMask = modMask }) =
  M.fromList
    $  [ ((modm .|. shiftMask, xK_Return), spawn myTerminal)
       , ((modm, xK_p)                   , spawn myLauncher)
       , ((modm, xK_Tab)                 , nextWS)
       , ((modm .|. shiftMask, xK_Tab)   , prevWS)
       , ( (modm .|. controlMask .|. shiftMask, xK_t)
         , namedScratchpadAction scratchpads "htop"
         )
       , ( (modm .|. controlMask .|. shiftMask, xK_c)
         , namedScratchpadAction scratchpads "cmus"
         )
       , ( (modm .|. controlMask .|. shiftMask, xK_w)
         , namedScratchpadAction scratchpads "chat"
         )
       -- audio keybindings
       , ( (0, xF86XK_AudioRaiseVolume)
         , spawn
           "amixer set Master 3+"
         )
       , ( (0, xF86XK_AudioLowerVolume)
         , spawn
           "amixer set Master 3-"
         )
       , ((0, xF86XK_AudioNext), spawn "playerctl next")
       , ((0, xF86XK_AudioPrev), spawn "playerctl previous")
       , ((0, xF86XK_AudioPlay), spawn "playerctl play-pause")
       , ((0, xF86XK_AudioStop), spawn "playerctl stop")
       , ( (0, xF86XK_AudioMute)
         , spawn "amixer set Master toggle"
         )
       , ( (modm, xK_j)
         , windows W.focusDown
         ) -- %! Move focus to the next window
       , ((modm, xK_k), windows W.focusUp)
       , ( (modm, xK_comma)
         , sendMessage (IncMasterN 1)
         ) -- %! Increment the number of windows in the master area
       , ( (modm, xK_period)
         , sendMessage (IncMasterN (-1))
         ) -- %! Deincrement the number of windows in the master area
       , ( (modm, xK_space)
         , sendMessage NextLayout
         ) -- %! Rotate through the available layout algorithms
       , ( (modm .|. shiftMask, xK_space)
         , setLayout $ XMonad.layoutHook conf
         ) -- %!  Reset the layouts on the current workspace to default
       , ( (modMask, xK_space)
         , sendMessage NextLayout
         ) -- %! Rotate through the available layout algorithms
       , ( (modMask .|. shiftMask, xK_space)
         , setLayout $ XMonad.layoutHook conf
         ) -- %!  Reset the layouts on the current workspace to default
       , ( (mod4Mask, xK_comma)
         , sendMessage (IncMasterN 1)
         ) -- %! Increment the number of windows in the master area
       , ( (mod4Mask, xK_period)
         , sendMessage (IncMasterN (-1))
         ) -- %! Deincrement the number of windows in the master area
       , ( (mod4Mask, xK_t)
         , withFocused $ windows . W.sink
         ) -- %! Push window back into tiling
       , ( (mod4Mask, xK_h)
         , sendMessage Shrink
         ) -- %! Shrink the master area
       , ( (mod4Mask, xK_l)
         , sendMessage Expand
         ) -- %! Expand the master area
       , ( (mod4Mask, xK_Return)
         , windows W.swapMaster
         ) -- %! Swap the focused window and the master window
       , ( (mod4Mask .|. shiftMask, xK_j)
         , windows W.swapDown
         ) -- %! Swap the focused window with the next window
       , ( (mod4Mask .|. shiftMask, xK_k)
         , windows W.swapUp
         ) -- %! Swap the focused window with the previous window
        -- , ((mod4Mask              , xK_m     ), windows W.focusMaster  ) -- %! Move focus to the master window
       , ( (mod4Mask .|. shiftMask, xK_c)
         , kill
         ) -- %! Close the focused window
       , ((modMask .|. shiftMask, xK_q), io (exitWith ExitSuccess))
          -- Quit xmonad.
       , ( (mod4Mask, xK_q)
         , broadcastMessage ReleaseResources >> restart "xmonad" True
         ) -- %! Restart xmonad
       , ( (modm .|. shiftMask, xK_x)
         , spawn "kill $(pidof polybar); polybar main"
         ) -- %! Kill & restart statusbar (polybar)
       , ((modm, xK_z)              , sendMessage MirrorShrink)
       , ((modm, xK_a)              , sendMessage MirrorExpand)
       , ((modm, xK_e)              , toggleFloatNext)
       , ((modm .|. shiftMask, xK_e), toggleFloatAllNew)
       , ( (modm .|. shiftMask, xK_p)
         , spawn "notify-send ' Taking screenshot in 5..4..3..2..1..';scrot ~/Pictures/screenshots/'%Y-%m-%d_$wx$h.png' -c -d 5;notify-send ' Screenshot taken!'"
         )
                        -- toggle fullscreen (really just lower status bar
                        --    below everything)
       , ((modm, xK_b), sendMessage ToggleStruts)
       , ((modm .|. shiftMask, xK_g), toggleWindowSpacingEnabled)
                      -- floating window keys
       , ((controlMask .|. shiftMask, xK_k), withFocused (keysMoveWindow (0, -15)))
       , ((controlMask .|. shiftMask, xK_j), withFocused (keysMoveWindow (0, 15)))
       , ((controlMask .|. shiftMask, xK_l), withFocused (keysMoveWindow (15, 0)))
       , ((controlMask .|. shiftMask, xK_h), withFocused (keysMoveWindow (-15, 0)))
       , ((controlMask .|. shiftMask, xK_m), withFocused $ keysResizeWindow (0, -15) (0, 0))
       , ((controlMask .|. shiftMask, xK_comma), withFocused $ keysResizeWindow (0, 15) (0, 0))
       ]
    ++ [ ((m .|. modMask, k), windows $ f i) -- mod-[1..9], Switch to workspace N
       | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9] -- mod-shift-[1..9], Move client to workspace N
       , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]
       ]


main :: IO ()
main = do
  spawn xmproc
  xmonad $ ewmh $ defaults { handleEventHook = handleEventHook desktopConfig }

defaults = docks $ desktopConfig { borderWidth = myBorderWidth
, normalBorderColor  = myNormalBorderColor
, focusedBorderColor = myFocusedBorderColor
, modMask            = modm
, terminal           = myTerminal
, workspaces         = myWorkspaces
, keys               = myKeys
, manageHook         = myNewManageHook <+> manageDocks
, layoutHook         = avoidStruts $ smartBorders $ gaps $ myLayout
, startupHook        = spawn "feh --bg-scale /home/qwerty/Pictures/wallpaper/the-look.jpg"
}

