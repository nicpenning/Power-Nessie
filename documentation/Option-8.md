🔗 Back to [📖Overview](./Overview.md)

### 8️⃣ **Remove Processed Scans from Local Nessus File Download Directory (May Be Used Optionally with -Remove_Processed_Scans_By_Days)**

Automates the cleanup of processed Nessus scan files from your local download directory by removing files that have been marked as ingested (with a `.processed` extension). This helps manage disk space and maintain an organized file structure, especially in environments with frequent scan imports.

#### What This Option Does

- **Scans the specified local Nessus file download directory** for files with the `.processed` extension.
- **Removes processed scan files** according to your criteria:
  - If `-Remove_Processed_Scans_By_Days` is set to `0`, removes all `.processed` files.
  - If set to `1`, keeps only the last day’s `.processed` files and removes older ones.
  - If set to a higher number, retains `.processed` files from the last N days and removes older files.
- **Helps automate disk cleanup** for continuous Nessus scan ingestion workflows.

#### Variables Available for Option 8

| Variable Name                         | Default Value           | Description                                                  |
|---------------------------------------|-------------------------|--------------------------------------------------------------|
| **Nessus_File_Download_Location**     | `"Nessus_Exports"`      | Directory containing Nessus files and processed scans.        |
| **Remove_Processed_Scans_By_Days**    | `$null`                 | Controls age-based deletion: `0` = remove all, `1` = keep last day, `N` = last N days. |
| **Configuration_File_Path**           | `$null`                 | Optional path to a JSON configuration file.                  |

#### Default Values Example

**Remove all processed scans:**
```powershell
.\Invoke-PowerNessie.ps1 -Option_Selected 8 -Remove_Processed_Scans_By_Days 0
```

**Keep only the last day’s processed scans:**
```powershell
.\Invoke-PowerNessie.ps1 -Option_Selected 8 -Remove_Processed_Scans_By_Days 1
```

**Keep the last 7 days of processed scans:**
```powershell
.\Invoke-PowerNessie.ps1 -Option_Selected 8 -Remove_Processed_Scans_By_Days 7
```

#### 📝 Use Case

**Clean up all processed scans after a batch ingest:**
```powershell
.\Invoke-PowerNessie.ps1 -Option_Selected 8 -Nessus_File_Download_Location "D:\NessusExports" -Remove_Processed_Scans_By_Days 0
```

**Using a configuration file:**

You can also use a JSON configuration file to set all the variables at once:

**configuration.json**
```json
{
    "Nessus_File_Download_Location": "D:\\NessusExports",
    "Remove_Processed_Scans_By_Days": 1
}
```

Run the script:

```powershell
.\Invoke-PowerNessie.ps1 -Option_Selected 8 -Configuration_File_Path "configuration.json"
```

- Ensures your Nessus file directory doesn’t get cluttered with old processed scans.
- Especially useful for long-running systems or automated scheduled Nessus scan imports.
- Supports both direct CLI argument passing and configuration via JSON file.

**Differences from Other Options:**

- **Does not export, ingest, or summarize scan data.**
- **Operates only on local file system to manage processed scan files.**
- **Focuses on disk management and cleanup.**

Use Option 8 to keep your Nessus scan directory organized and prevent excessive disk usage by removing old processed scans according to your retention requirements.

🔗 Back to [📖Overview](./Overview.md)
