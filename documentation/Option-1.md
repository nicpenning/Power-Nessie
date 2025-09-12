🔗 Back to [📖Overview](./Overview.md)

### 1️⃣ **Export Nessus Files.**

Automates the extraction of Nessus scan files from your Nessus scanner and moves them to a local directory for further processing or archival. Optionally, the exported scans can be moved to an archive folder within Nessus.

#### What This Option Does

- Connects to your Nessus scanner via API using provided credentials.
- Locates scans in the specified Nessus folder (default: "My Scans").
- Downloads scan files (in `.nessus` format) to your chosen local directory.
- Optionally moves scans to an archive folder within Nessus after export.
- Supports exporting scans from today, a specific date, or all scan history.
- Customizes scan file names for uniqueness (helpful for multi-scanner environments).

Note: The archive feature only works when the Nessus_Archive_Folder_Name (destination folder) variable or config file option is configured, otherwise, scans won't move in the Nessus Web UI. Not configuring the Nessus_Archive_Folder_Name is ideal for those that run re-occurring scans and are not constantly creating new scans.

#### Variables Available for Option 1

| Variable Name                                   | Default Value                        | Description                                                                                                                  |
|-------------------------------------------------|--------------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| **Nessus_URL**                                  | `"https://127.0.0.1:8834"`           | Nessus scanner API endpoint URL.                                                                                             |
| **Nessus_File_Download_Location**               | `"Nessus_Exports"`                   | Local directory for saving exported Nessus files.                                                                            |
| **Nessus_Access_Key**                           | `$null`                              | Nessus API access key.                                                                                                       |
| **Nessus_Secret_Key**                           | `$null`                              | Nessus API secret key.                                                                                                       |
| **Nessus_Source_Folder_Name**                   | `"My Scans"`                         | Nessus folder containing scans to export.                                                                                    |
| **Nessus_Archive_Folder_Name**                  | `$null`                              | Nessus folder to move scans for archival after export. If not set, scans are not moved.                                      |
| **Nessus_Export_Scans_From_Today**              | `$null`                              | Set to `"true"` to export only scans from today.                                                                             |
| **Nessus_Export_Day**                           | `$null`                              | Specify a date (`MM/DD/YYYY`) to export scans from that day.                                                                 |
| **Nessus_Export_Custom_Extended_File_Name_Attribute** | `$null`                        | String appended to exported filenames for uniqueness (e.g., `"_scanner1"`).                                                  |
| **Nessus_Export_All_Scan_History**              | `$null`                              | Set to `"true"` to export all scan history, not just the latest scan.                                                        |
| **Connection_Timeout**                          | `0`                                  | How long to wait for a connection to start (seconds).                                                                        |
| **Operation_Timeout**                           | `0`                                  | How long to wait for connection data (seconds).                                                                              |
| **Configuration_File_Path**                     | `$null`                              | Optional path to a JSON configuration file to load all variables.                                                            |

#### Default Values Example

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_URL "https://127.0.0.1:8834" `
  -Nessus_File_Download_Location "Nessus_Exports" `
  -Nessus_Access_Key "<YourAccessKey>" `
  -Nessus_Secret_Key "<YourSecretKey>" `
  -Nessus_Source_Folder_Name "My Scans"
```

#### 📝 Use Cases

**Export all scans from the "My Scans" folder to a custom directory and append a scanner ID to each filename for a multi-scanner environment:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_URL "https://scanner1.local:8834" `
  -Nessus_File_Download_Location "D:\NessusExports" `
  -Nessus_Access_Key "<YourAccessKey>" `
  -Nessus_Secret_Key "<YourSecretKey>" `
  -Nessus_Source_Folder_Name "My Scans" `
  -Nessus_Export_Custom_Extended_File_Name_Attribute "_scanner1"
```

**Export only today's scans and move them to an archive folder in Nessus after export:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_URL "https://scanner2.company.com:8834" `
  -Nessus_File_Download_Location "C:\NessusToday" `
  -Nessus_Access_Key "<YourAccessKey>" `
  -Nessus_Secret_Key "<YourSecretKey>" `
  -Nessus_Source_Folder_Name "My Scans" `
  -Nessus_Archive_Folder_Name "Archive-Ingested" `
  -Nessus_Export_Scans_From_Today "true"
```

**Export scans for a specific date:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_Export_Day "11/07/2023" `
  -Nessus_Access_Key "<YourAccessKey>" `
  -Nessus_Secret_Key "<YourSecretKey>"
```

#### Using a Configuration File
You can also use a JSON configuration file to set all the variables at once:

**configuration.json**
```json
{
    "Nessus_URL": "https://scanner1.local:8834",
    "Nessus_File_Download_Location": "D:\\NessusExports",
    "Nessus_Access_Key": "<YourAccessKey>",
    "Nessus_Secret_Key": "<YourSecretKey>",
    "Nessus_Source_Folder_Name": "My Scans",
    "Nessus_Archive_Folder_Name": "Archive-Ingested",
    "Nessus_Export_Custom_Extended_File_Name_Attribute": "_scanner1"
}
```

Run the script:

```powershell
.\Invoke-PowerNessie.ps1 -Configuration_File_Path "configuration.json"
```

- You must provide valid Nessus API keys for authentication.
- Exported files use a timestamp and scan name for easy identification.
- If an archive folder is specified, exported scans are moved in the Nessus UI for better organization.
- Supports batch export of all scan history or targeted exports by date.
- Designed for integration with later ingest and automation steps in the Elastic stack workflow.

Use Option 1 to streamline Nessus scan exports for compliance, vulnerability management, or integration with automated ingest pipelines.

🔗 Back to [📖Overview](./Overview.md)
