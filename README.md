# Description

A fork to debug the hotplug events.

## Installation
  ```
  wget https://github.com/pseudocc/udev-monitor-hotplug/releases/download/stable/udev-monitor-hotplug.deb
  sudo dpkg -i udev-monitor-hotplug.deb
  sudo rm -f udev-monitor-hotplug.deb
  ```

## Debuging
  ```
  sudo journalctl -f
  ```

  OR

  ```
  sudo service udev stop
  sudo udevd --debug 2>&1 | tee /tmp/udev.log
  check what's happening when you plug/unplug your monitor
  ```

## License

I'm not responsible of the effect of this script on your computer

Feel free to do whatever you want with it :-)
