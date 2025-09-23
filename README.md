<h1 align="center">
  <br>
  <a href="http://macpaper.github.io"><img src="https://github.com/user-attachments/assets/0d2f86cb-a77d-4491-ab0f-f78bb61f0c66" alt="macpaper" width="150"></a>
  <br>
  macpaper
  <br>
</h1>
<p align="center">
  <i>✨ The Wallpaper Manager for macOS</i>
</p>

<p align="center">
  <a title="platform" target="_blank" href="https://github.com/naomisphere/macpaper/releases/latest"><img src="https://img.shields.io/github/v/release/naomisphere/macpaper?style=flat&color=blue&include_prereleases"></a>
  <img src="https://img.shields.io/badge/macOS-12%2B-2396ED?style=flat&logo=apple&logoColor=white" alt="platform" style="margin-right: 10px;" />
  
  <a href="./LICENSE">
    <img src="https://img.shields.io/badge/License-GPLv3-red.svg?logo=gnu" alt="license" />
  </a>
</p>

<p align="center">
macpaper is a feature-packed lightweight Wallpaper Manager for macOS, with support for gifs, videos, and online wallpaper browsing, among other many things!
<br><br>
At the start, macpaper was no more than a simple tool with boring... features... Zzz...
But now, it's evolved to an advanced tool for customization of your wallpaper, all while keeping sure it doesn't eat your RAM.
</p>

<h1 align="center">
✨ Preview
</h1>
<p align="center">
  <img src="https://github.com/user-attachments/assets/15118fad-306d-4804-b108-462e81fef237" alt="Demo GIF" />
</p>

---

## Installation

**System Requirements:**  
- macOS **12** *(Monterey)* or later
- Silicon/Intel Mac

## 🍺 Homebrew (recommended)
```
brew install --cask naomisphere/macpaper/macpaper --no-quarantine
```

## Manual
---
> [!IMPORTANT]
> After downloading and trying to launch the app, you will receive a text saying that it is from an unidentified developer.
> This is because I do not own an Apple Developer account. To fix this:
> 1. Open **System Settings** > **Privacy & Security**
> 2. Scroll down and find the warning about the app
> 3. Click **Open Anyway**
>
> You only need to do this once.

<p align="center">
  <a href="https://github.com/naomisphere/macpaper/releases/latest/download/macpaper.dmg" target="_self"><img width="200" src="https://github.com/user-attachments/assets/e2b187d1-8010-45cf-a9d4-e7ce5e2e677c" /></a>
</p>

---

## License
macpaper is licensed under the GNU General Public License v3.0 (GPLv3). See the [LICENSE](./LICENSE) file for details.

## 🔨 Building from Source
- Clone the repo
- ```cd``` into app
- ```sh build.sh```

## 🉑️ Translating
Contributing to translation is pretty simple and straightforward -partly because there are not many strings to translate-. Fork the repo, grab the template on the [lang](./lang) folder (or an already existing strings file), and replace the value of the keys with the ones respective to your language. Then, upload the translation to lang/{lang}.lproj and submit a pull request.

It is advised that you, alongside the strings file, place a file named `credit` with a link to your GitHub profile, or just your username.

## 🤝 Thanks to
- [Boring Notch](https://github.com/TheBoredTeam/boring.notch), for README inspiration
- [This post](https://stackoverflow.com/questions/34215527/what-does-launchd-status-78-mean-why-my-user-agent-not-running), because it stopped me from going insane

## 🛠️ Troubleshooting
### Quarantine
If you suspect the app is quarantined, run the following on your Terminal after dragging the app to Applications:
```bash
xattr -l /Applications/macpaper.app
```
Which shall output ```com.apple.quarantine: ...;{BROWSER};``` if the app IS quarantined.
In that case, run:
```bash
xattr -dr com.apple.quarantine /Applications/macpaper.app
```

### Apple could not verify "macpaper" is free of malware...
You can fix this by doing the same steps as [here](https://github.com/naomisphere/macpaper/tree/main/README.md#installation).

## ❤️ Support me
☕ If you like my work and want to support me, you can do so via Ko-fi:\
https://ko-fi.com/naomisphere
