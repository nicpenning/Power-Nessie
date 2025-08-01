# Configuration File vs. Command-Line Options

## Overview

**Power-Nessie** allows you to customize its behavior by providing options either via a configuration file (e.g., `configuration.json`) or directly as command-line parameters. Understanding which takes priority is important for a predictable and flexible experience.

---

## Priority and Override Logic

- **If a configuration file is provided using** `-Configuration_File_Path`, **all supported options in that file will override any values passed on the command line.**
- **If no configuration file is provided, the script uses the values from the command line arguments.**
- **If neither a configuration file nor a command-line argument is provided for a parameter, the script uses its built-in default value.**

### Priority Order
1. **Configuration file** (highest priority; overrides everything if specified)
2. **Command-line options** (used only if configuration file is not provided or doesn’t set a value)
3. **Script defaults** (used if neither of the above are set)

---

## Use Cases

### When to Use a Configuration File

- **Consistency:** Run the script with the same settings every time, especially in automated or scheduled environments.
- **Simplicity:** Avoid typing long or repetitive command-line arguments.
- **Version control:** Store configuration files in version control to track changes to scan/import settings.

**Example:**
```powershell
.\Invoke-Power-Nessie.ps1 -Configuration_File_Path "C:\path\to\configuration.json"
```

### When to Use Command-Line Options

- **Ad hoc runs:** Quickly change a few settings for a one-off execution.
- **Testing:** Override just one or two settings without editing a shared config file.
- **Scripting:** Integrate with other scripts or CI/CD pipelines where dynamic values are passed in.

**Example:**
```powershell
.\Invoke-Power-Nessie.ps1 -Nessus_URL "https://scanner.example.com:8834" -Nessus_Access_Key "XXXX" -Nessus_Secret_Key "YYYY"
```

---

## Summary Table

| Provided?                      | Value Used      |
|--------------------------------|----------------|
| Config file & command-line      | **Config file** |
| Only command-line               | Command-line    |
| Neither                         | Script Default  |

---

## Tips

- If you supply both a configuration file and command-line options, the configuration file’s values will be used for any option it contains.
- Command-line arguments are only relevant for settings not specified in the configuration file.
- Use configuration files for automation and repeatability; use command-line for quick, situational overrides.

---

**For more details on available options, see the [Parameters section](https://github.com/nicpenning/Power-Nessie/blob/main/Invoke-Power-Nessie.ps1) in the script.**
