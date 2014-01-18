sudo net-mon stop
sudo wauto &

~/.xconfig
(sleep 10; xconfig) &

pulseaudio --start &
sudo bluetooth off &
sudo fan auto &
taffybar &
parcellite -d &

exec xmonad
