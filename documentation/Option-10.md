🔗 Back to [📖Overview](./Overview.md)

### 🔟 **Delete Oldest Scan from Scan History (Hidden / Only Works with Nessus Manager License)**

Removes the oldest scan from the scan history for a specified scan name in your Nessus Manager environment. This option is intended for environments where scan retention or storage limits require periodic cleanup of historical scan data from the Nessus scanner directly.

#### What This Option Does

- **Identifies the oldest scan history entry** for the specified `Nessus_Scan_Name_To_Delete_Oldest_Scan`.
- **Deletes the oldest scan** from scan history via the Nessus API (requires Nessus Manager license).
- **Useful for environments with scan storage limits**, compliance retention policies, or routine scan rotation.

#### Variables Available for Option 10

| Variable Name                           | Default Value           | Description                                                                          |
|-----------------------------------------|-------------------------|--------------------------------------------------------------------------------------|
| **Nessus_URL**                          | `"https://127.0.0.1:8834"` | Nessus scanner API endpoint URL.                                                     |
| **Nessus_Access_Key**                   | `$null`                 | Nessus API access key.                                                               |
| **Nessus_Secret_Key**                   | `$null`                 | Nessus API secret key.                                                               |
| **Nessus_Source_Folder_Name**           | `"My Scans"`            | Nessus folder containing the scan.                                                   |
| **Nessus_Archive_Folder_Name**          | `$null`                 | Optional Nessus folder for archiving scans.                                          |
| **Nessus_Scan_Name_To_Delete_Oldest_Scan** | `$null`              | Scan name from which to delete the oldest history entry (required for this option).   |
| **Configuration_File_Path**             | `$null`                 | Optional path to a JSON configuration file.                                          |

#### Default Values Example

```powershell
.\Invoke-PowerNessie.ps1 `
  -Option_Selected 10 `
  -Nessus_URL "https://127.0.0.1:8834" `
  -Nessus_Access_Key "<YourAccessKey>" `
  -Nessus_Secret_Key "<YourSecretKey>" `
  -Nessus_Source_Folder_Name "My Scans" `
  -Nessus_Scan_Name_To_Delete_Oldest_Scan "Weekly Vulnerability Scan"
```

#### 📝 Use Case

**Delete the oldest scan history entry for a recurring scan:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Option_Selected 10 `
  -Nessus_Scan_Name_To_Delete_Oldest_Scan "Weekly Vulnerability Scan" `
  -Nessus_Access_Key "<YourAccessKey>" `
  -Nessus_Secret_Key "<YourSecretKey>"
```

**Using a configuration file:**

You can also use a JSON configuration file to set all the variables at once:

**configuration.json**
```json
{
    "Nessus_URL": "https://scanner1.local:8834",
    "Nessus_Access_Key": "<YourAccessKey>",
    "Nessus_Secret_Key": "<YourSecretKey>",
    "Nessus_Source_Folder_Name": "My Scans",
    "Nessus_Scan_Name_To_Delete_Oldest_Scan": "Weekly Vulnerability Scan"
}
```

Run the script:

```powershell
.\Invoke-PowerNessie.ps1 -Option_Selected 10 -Configuration_File_Path "configuration.json"
```

- Requires a valid Nessus Manager license (not available in Nessus Professional).
- Useful for maintaining scan retention policies or freeing up scan storage.
- Only deletes the oldest scan entry for the specified scan name, leaving newer scans intact.
- Supports both direct CLI argument passing and configuration via JSON file.

**Differences from Other Options:**

- **Works only with Nessus Manager license.**
- **Deletes scan history data, does not export, ingest, or summarize scan results.**
- **Intended for scan management and retention—not vulnerability analysis.**

Use Option 10 for automated scan retention management—keeping your Nessus environment clean and compliant by deleting the oldest scan history entries for recurring scans.

🔗 Back to [📖Overview](./Overview.md)
