# NVIDIA Power Limit
**A PowerShell script to automatically generate a script and Windows scheduled task for setting NVIDIA eGPU power limit (and any custom actions) on connect**

## About
eGPUs are a fantastic way to add graphics horsepower to an existing laptop, but as with any new technology, standards haven't quite reached maturity yet. Different enclosures feature different power supplies, with different allocations to a variety of components besides just the GPU. This often limits GPU compatibility based on power draw alone, but what if there was a way to limit the GPU's power consumption to match the enclosure?

**For NVIDIA users, there is a way!** Included in NVIDIA's driver package is a little-known command-line utility called `nvidia-smi`. This tool has the ability to report and modify many low-level properties of GPU behavior, including power limits. However, changes are not permanent and last only for the current session. Disconnecting the eGPU or rebooting the PC will return the power limit to normal.

**This script fixes that.** `NVIDIA Power Limit` will generate a custom PowerShell script (yes, within a PowerShell script) and Windows Task Scheduler profile from a few simple inputs. From there, Windows will handle the rest! Any time the specified GPU is connected, `nvidia-smi` will be invoked to set your desired power limit (and any other custom actions you may add to the script!). This behavior will persist across users and reboots, running silently in the background without the need for any further user interaction.

It's the safest way to use virtually any NVIDIA GPU in virtually any eGPU enclosure!

## How-to
1. Download and run `Enable PowerShell Scripts (Run as Admin).bat` while (you guessed it) running as an Administrator

OR

1. Open PowerShell and run the command:
```
Set-ExecutionPolicy -Scope "CurrentUser" -ExecutionPolicy "RemoteSigned"
```
2. Download and run `NVIDIA Power Limit.ps1` (you may need to unblock it from the file properties first if you didn't use the Batch script to enable PowerShell scripts)
3. Follow the prompts
4. That's it!

## Removal
* If you make a mistake, or want to experiment with different settings, simply run the script again. It will safely overwrite previous settings. (**WARNING:** Any custom actions you may have added will be deleted!)
* If you decide `NVIDIA Power Limit` isn't for you, open Windows Task Scheduler and delete the `NVIDIA Power Limit` profile.

OR

* Run PowerShell as an Administrator and enter the following command:
```
schtasks /delete /tn "\NVIDIA Power Limit" /f
```
* That's it!

---

<p align="center"><em>This script is provided as-is and comes without warranty or support. Use at your own risk! (But I hope you found it helpful!)</em></p>
