🔗 Back to [📖Overview](./Overview.md)

### 7️⃣ **Export PDF or CSV Report from Kibana Dashboard and Optionally Send via Email (Advanced Options - Copy POST URL)**

Automates the export of PDF or CSV reports from your Kibana dashboards, allowing you to generate and distribute visualizations of vulnerability data. Optionally, you can send these reports as email attachments using SMTP via PowerShell.

#### What This Option Does

- **Exports a PDF or CSV report** from a specified Kibana dashboard using a POST URL (obtained from Kibana's "Share" > "PDF/CSV Reports" > "Advanced options").
- **Downloads the report** to a local directory.
- **Optionally sends the exported report via email** using provided SMTP settings and email addresses.
- **Supports custom authentication headers** for Kibana API integration.

#### Variables Available for Option 7

| Variable Name                        | Default Value                        | Description                                                                                  |
|--------------------------------------|--------------------------------------|----------------------------------------------------------------------------------------------|
| **Kibana_URL**                       | `"https://127.0.0.1:5601"`           | URL for your Kibana instance.                                                                |
| **Kibana_Export_PDF_URL**            | `$null`                              | POST URL to export PDF report from Kibana dashboard (Copy from Kibana Advanced options).     |
| **Kibana_Export_CSV_URL**            | `$null`                              | POST URL to export CSV report from Kibana dashboard.                                         |
| **Kibana_Custom_Authentication_Header** | `"ApiKey"`                        | Custom text for Kibana authentication header (e.g., `"Bearer"` for SearchGuard).             |
| **Email_From**                       | `$null`                              | Sender email address.                                                                        |
| **Email_To**                         | `$null`                              | Recipient email addresses (comma-separated or array).                                        |
| **Email_CC**                         | `$null`                              | CC email addresses (optional).                                                               |
| **Email_SMTP_Server**                | `$null`                              | SMTP server address for sending emails.                                                      |
| **Email_Subject**                    | `"Vulnerability Report for <date>"`  | Subject line for the email (default includes current date).                                  |
| **Email_Body**                       | `"Attached is the vulnerability report for <date>."` | Email body text.                                   |
| **Configuration_File_Path**          | `$null`                              | Optional path to a JSON configuration file.                                                  |

#### Default Values Example

```powershell
.\Invoke-PowerNessie.ps1 `
  -Kibana_URL "https://127.0.0.1:5601" `
  -Kibana_Export_PDF_URL "<Kibana POST PDF URL>" `
  -Email_From "soc@company.com" `
  -Email_To "security@company.com" `
  -Email_SMTP_Server "smtp.company.com"
```

#### 📝 Use Cases

**Export a PDF report from a Kibana dashboard and email it to the SOC team:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Kibana_URL "https://my-elastic-instance.local:5601" `
  -Kibana_Export_PDF_URL "https://my-elastic-instance.local:5601/api/reporting/generate/printablePdf?..." `
  -Email_From "soc@company.com" `
  -Email_To "security@company.com" `
  -Email_Subject "Monthly Vulnerability Report" `
  -Email_Body "Please find the attached report for this month's vulnerabilities." `
  -Email_SMTP_Server "smtp.company.com"
```

**Export a CSV report and send to multiple recipients with CC:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Kibana_Export_CSV_URL "https://my-elastic-instance.local:5601/api/reporting/generate/csv?..." `
  -Email_From "soc@company.com" `
  -Email_To "security@company.com,admin@company.com" `
  -Email_CC "teamlead@company.com" `
  -Email_SMTP_Server "smtp.company.com"
```

#### Using a Configuration File

You can also use a JSON configuration file to set all the variables at once:

**configuration.json**
```json
{
    "Kibana_URL": "https://my-elastic-instance.local:5601",
    "Kibana_Export_PDF_URL": "https://my-elastic-instance.local:5601/api/reporting/generate/printablePdf?...",
    "Email_From": "soc@company.com",
    "Email_To": ["security@company.com", "admin@company.com"],
    "Email_CC": ["teamlead@company.com"],
    "Email_Subject": "Monthly Vulnerability Report",
    "Email_Body": "Please find the attached report.",
    "Email_SMTP_Server": "smtp.company.com"
}
```

Run the script:

```powershell
.\Invoke-PowerNessie.ps1 -Configuration_File_Path "configuration.json"
```

- The POST URL for PDF or CSV export is obtained from Kibana ("Share" > "PDF/CSV Reports" > "Advanced options" > Copy POST URL).
- Supports custom authentication headers for enhanced security.
- Email distribution is optional but ideal for automated reporting to security teams or management.
- Multiple recipients and CC supported via comma-separated values or arrays.
- Supports both direct CLI argument passing and configuration via JSON file.

**Differences from Other Options:**

- **Does not export or ingest Nessus scan files.**
- **Operates on data already visualized in Kibana.**
- **Focuses on report generation and automated email distribution.**

Use Option 7 to automate

🔗 Back to [📖Overview](./Overview.md)
