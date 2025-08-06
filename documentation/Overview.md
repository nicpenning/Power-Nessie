🔗 [🏡Home](https://github.com/nicpenning/Power-Nessie/wiki/%F0%9F%8F%A1-Home) | 📖Overview

---

💫 This is an overview of what you can do with this project along with more details and use cases for using Power-Nessie.

## 🛠️ Requirements
1. Get Nessus API Keys [Nessus Documentation](https://docs.tenable.com/nessus/Content/GenerateAnAPIKey.htm).
2. Download the latest release from [here](https://github.com/nicpenning/Power-Nessie/releases/latest) and extract to a directory of your choosing.
- Alternatively, to use the latest branch, clone this project to the directory of your choosing: 
```PowerShell
git clone https://github.com/nicpenning/Power-Nessie.git
```
3. Setup Elasticsearch : Step by step instruction 👉🏻 [Option 0](./option-0.md)
4. Run the Invoke-Power-Nessie.ps1 script supplying required variables for your use case and using the guided options.
5. Watch the Nessus files get downloaded and then ingested into Elasticsearch - Resolve any issues along the way / Ask questions [here](https://github.com/nicpenning/Power-Nessie/discussions).

To fully automate the ingestion on a daily, weekly, or monthly schedule you could create a scheduled task to have the Invoke-Power-Nessie.ps1 script kick off as needed.

## 📃 Options
Invoking this script provides an assortment of menu options you can use for your use case!

See [Options Menu](./options-menu.md) for the available choices.

⚙️This script uses inline variables or a config file. See [Configuration-Priority](https://github.com/nicpenning/Power-Nessie/blob/main/documentation/Configuration-Priority.md) for more details.
