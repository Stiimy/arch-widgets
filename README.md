<div align="center">

![Arch](https://img.shields.io/badge/Arch-%231793D1?style=flat&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-%2358E1FF?style=flat&logo=hyprland&logoColor=black)
![Quickshell](https://img.shields.io/badge/Quickshell-0.3.0-%23cba6f7?style=flat)
![Made with QML](https://img.shields.io/badge/Made%20with-QML-%2341CD52?style=flat&logo=qt)
![License](https://img.shields.io/badge/license-WTFPL-brightgreen?style=flat)

</div>

---

# ⚡ Arch Widgets

> *Three sleek Quickshell widgets ripped from [ilyamiro's dots](https://github.com/ilyamiro/imperative-dots), tuned for Arch + HyDE.*

<br/>

| 🎮 Keybind | 🧩 Widget | 🔧 What it does |
|:----------:|-----------|-----------------|
| `Super + N` | **Control Center** | Battery · Brightness · Volume · Live notifications |
| `Super + R` | **Network** | WiFi scan & connect · Bluetooth scan/pair · Ethernet · Refresh |
| `Super + O` | **Calendar** | Monthly view · Weather forecast · Day navigation |

> 💡 **Escape** hides — same keybind brings it back. That simple.

<br/>

---

## 📦 Dependencies

<details open>
<summary><b>Click to expand</b></summary>

```bash
# AUR (required)
yay -S quickshell-git iw

# Pacman (usually already there)
sudo pacman -S networkmanager bluez-utils brightnessctl wireplumber jq
```

| Package | Why |
|---------|-----|
| `quickshell-git` | QtQuick shell framework |
| `nmcli` | WiFi / Ethernet backend |
| `bluetoothctl` | Bluetooth backend |
| `brightnessctl` | Backlight slider |
| `wpctl` | Volume slider |
| `jq` | JSON parsing in scripts |

</details>

<br/>

---

## 🚀 Install

```bash
# Clone it
git clone https://github.com/Stiimy/arch-widgets ~/.config/quickshell

# Add keybinds
cat >> ~/.config/hypr/keybindings.conf << 'EOF'
bind = $mainMod, N, exec, ~/.config/quickshell/battery-widget/launch.sh
bind = $mainMod, R, exec, ~/.config/quickshell/network-widget/launch.sh
bind = $mainMod, O, exec, ~/.config/quickshell/calendar-widget/launch.sh
EOF

# Reload
hyprctl reload
```

<br/>

---

## ☀️ Weather

Stick your OpenWeather key in `calendar-widget/.env`:

```env
OPENWEATHER_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
OPENWEATHER_CITY_ID=2988507
OPENWEATHER_UNIT=metric
```

> Free key at [openweathermap.org](https://openweathermap.org) — takes 2 minutes.

<br/>

---

## 🙏 Credits

- [**ilyamiro**](https://github.com/ilyamiro) — original widget genius
- [**Quickshell**](https://quickshell.org) by outfoxxed — the shell that makes it possible
- [**Catppuccin**](https://github.com/catppuccin) — the colors you're looking at

<br/>

<div align="center">
  <sub>built with ❤️‍🔥 on Arch · breaks sometimes · nangalafou</sub>
</div>
