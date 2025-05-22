resource "azurerm_resource_group" "sentinel" {
    name = "sentinel"
    location = local.config.azure.location
}

resource "azurerm_log_analytics_workspace" "sentinel" {
    name = format("sentinel%s", split("-", uuid())[0]) # i want a fresh workspace with each deployment
    location = local.config.azure.location
    resource_group_name = azurerm_resource_group.sentinel.name
    retention_in_days = 30 # this is the minimum

    lifecycle {
      ignore_changes = [ name ]
    }
}

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "sentinel" {
    workspace_id = azurerm_log_analytics_workspace.sentinel.id
}

resource "azurerm_sentinel_alert_rule_scheduled" "tetragon-demo" {
  depends_on = [azurerm_sentinel_log_analytics_workspace_onboarding.sentinel]
  name                       = "Unusual shadow file activity"
  display_name               = "Unusual shadow file activity"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.sentinel.id
  enabled                    = true
  description                = "Flags when /etc/shadow has been read (tetragon demo)"

  severity   = "Medium"
  tactics    = ["Impact"]
  techniques = ["T1496"]

  suppression_enabled  = true
  suppression_duration = "PT5H"

  incident {
    create_incident_enabled = true
    grouping {
      enabled                = true
      lookback_duration      = "P1D"
      entity_matching_method = "AllEntities"
    }
  }

  query_frequency = "PT5M"
  query_period    = "P1D"

  query = <<QUERY
ContainerLogV2
| where ContainerName == "export-stdout"
| extend Process=parse_json(LogMessage).process_exit.process
| extend Workload=Process.pod.workload
| where Process.arguments contains "/etc/shadow"
| extend Binary=Process.binary, Arguments=Process.arguments
| project-away Process
QUERY
}