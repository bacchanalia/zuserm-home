sudo net-mon stop
sudo wauto -p &

~/.xconfig
(sleep 10; xconfig) &

pulse-enable on
sudo bluetooth off &
sudo fan auto &
taffybar-restart --daemon --quiet
parcellite -d &
( sleep 2; pulse-vol mic mute ) &

exec xmonad
