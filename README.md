# Train Speed Limits
The **Train Speed Limits** mod lets you assign a maximum speed (in km/h) to **train signals**, ensuring player safety around intersections and train stations.

### 🛠️ Features
- ✅ **Direct Integration:**  
It can be directly integrated into any existing world without problems. This is the same for removing the mod.

- 🚦 **Signal-Based Limits:**  
Speed limits need to be configured in a train signal. When a train drives past it, it will be limited to the configured speed.

- ⏩ **Continuous Limits:**  
Trains will maintain their speed limit until it drives past another applied signal with a speed limit or cleared with 'Unrestricted'.

- 📉 **Train Braking:**  
The train will start to brake after the locomotive drove past the speed limit signal. Braking is gradual like the unmodded game.

- 🔄 **Copy/Paste Compatible:**  
Use `Shift + Right-click` and `Shift + Left-click` to copy-paste speed settings between signals (just like vanilla).

- 🤖 **Automatic Only:**  
Only trains with drive mode `Automatic` are affected by speed limits. Manually controlled trains will ignore these limits.


### ❓ How It Works
1. Place a **rail signal**.
2. Click on the signal and open the GUI.
3. Set a **speed limit (in km/h)** and **apply it** via the checkbox.
4. Any train passing that signal while on **automatic mode** will adjust its speed.
5. The limit persists across blocks until overwritten or unrestricted.

### 😎 Use Cases
You might be wondering, why do I need to slow down trains? Well, how many times have you been hit by a train? Probably a lot of times if you've played Factorio a lot. 😄

Most of these "accidents" happen close to intersections, train stations and mining outposts. They are the perfect places for a speed limit!


### ⚠️ Compatibility & Known Limitations
- Works with vanilla and has been tested with the most popular mods.
- Mods which affect train speed behaviour (including "fast trains") could experience small issues.
- Initial spawn/movement may ignore speed limits until reaching the first signal with a speed limit.
- Try to limit placing signals with speed limits in corners/turns and close to intersections. This should normally work but there are certain cases the train doesn't detect the signal.

### 🚧 Contributions
Developed by **DJj123dj**

Contributions, suggestions and pull requests are always welcome!