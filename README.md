# check-router

Small utility to check connectivity to a local router and attempt a Wi‑Fi
reconnect using NetworkManager (`nmcli`) when connectivity is lost.

Features
- Lightweight single-file shell script.
- Configurable router IP, connection name/SSID, and reconnect method.
- Intended to be run from a cron job (every minute) or as a systemd timer.

Configuration
- `ROUTER` — IP address of the router to ping (default `192.168.0.1`).
- `TARGET` — optional NetworkManager connection name or SSID to bring up.
- `RECONNECT_METHOD` — `device` (default) to use `nmcli device disconnect/connect`, or `radio` to toggle `nmcli radio wifi off/on`.
- Other environment vars: `PING_COUNT`, `PING_TIMEOUT`, `LOG_TAG`.

Installation
1. Copy the script to a system path:

```bash
sudo cp check_router.sh /usr/local/bin/check_router.sh
sudo chmod +x /usr/local/bin/check_router.sh
```

Or for a single user:

```bash
cp check_router.sh ~/.local/bin/check_router.sh
chmod +x ~/.local/bin/check_router.sh
```

2. Install a per-user cron entry (runs every minute):

```bash
(crontab -l 2>/dev/null; echo "* * * * * /path/to/check_router.sh >/dev/null 2>&1") | crontab -
```

Replace `/path/to/check_router.sh` with the installed location.

Usage
- Run once for testing:

```bash
RECONNECT_METHOD=radio /path/to/check_router.sh
```

- To override the router IP only:

```bash
ROUTER=10.0.0.1 /path/to/check_router.sh
```

Testing
- To simulate failure, set `ROUTER` to a non-routable IP and run the script with tracing:

```bash
ROUTER=203.0.113.1 bash -x /path/to/check_router.sh
```

Troubleshooting
- Ensure `nmcli` is installed and the user running the script has permission to control NetworkManager.
- Check system logs for `check-router` tag (the script uses `logger`).

License
This project is released under the MIT License. See `LICENSE`.
