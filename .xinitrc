sudo net-mon stop
sudo wauto www.google.com &

~/.xconfig
(sleep 10; xconfig) &

pulseaudio --start &
sudo bluetooth off &
sudo fan auto &
taffybar-restart --daemon --quiet
parcellite -d &
( sleep 2; pulse-vol mic mute ) &

exec xmonad
