🔗 Back to [📖Overview](./Overview.md)

### 0️⃣ **Setup Elasticsearch and Kibana.**

Configures your Elastic stack (Elasticsearch & Kibana) to properly ingest and visualize Nessus scan data prior to importing scans. This is a critical first step to ensure your vulnerability data is ready for analysis and reporting.

---

#### What This Option Does

- **Checks for Elasticsearch and Kibana endpoints and credentials**
- **Imports ingest pipelines** required for parsing Nessus scan data into Elasticsearch
- **Imports index templates** to structure vulnerability data for efficient storage and retrieval
- **Imports saved objects:** dashboards, data views, and other visualizations into Kibana
- **Creates an Elasticsearch API key** for secure Nessus data ingestion

#### Variables Available for Option 0

| Variable Name        | Default Value                    | Description                                                         |
|----------------------|----------------------------------|---------------------------------------------------------------------|
| **Elasticsearch_URL**| `"https://127.0.0.1:9200"`       | URL for your Elasticsearch instance                                 |
| **Kibana_URL**       | `"https://127.0.0.1:5601"`       | URL for your Kibana instance                                        |

#### Default Values Example

```powershell
.\Invoke-PowerNessie.ps1 -Elasticsearch_URL "https://127.0.0.1:9200" -Kibana_URL "https://127.0.0.1:5601"
```

#### 📝 Use Case

**Configure Elastic stack for a cluster hosted at `my-elastic-instance.local`:**

```powershell
.\Invoke-PowerNessie.ps1 -Elasticsearch_URL "https://my-elastic-instance.local:9200" -Kibana_URL "https://my-elastic-instance.local:5601"
```

#### Using a Configuration File
You can also use a JSON configuration file to set all the variables at once:

**configuration.json**

```json
{
    "Elasticsearch_URL" : "https://my-elastic-instance.local:9200",
    "Kibana_URL" : "https://my-elastic-instance.local:5601"
}
```

Then run:

```powershell
.\Invoke-PowerNessie.ps1 -Configuration_File_Path "configuration.json"
```

- You must have a running Elastic stack (Elasticsearch & Kibana). If you don’t have one, [download Elastic here](https://www.elastic.co/downloads/).
- This step imports all necessary ingest pipelines, index templates, and saved Kibana objects so that Nessus scan files can be visualized and analyzed.
- The Elasticsearch API key generated here is used for secure data ingestion in subsequent steps.
- Supports both direct argument passing and configuration via JSON file.

Use Option 0 to prepare your Elastic environment for Nessus vulnerability data ingestion and visualization. This step is required before importing any scans!

🔗 Back to [📖Overview](./Overview.md)
