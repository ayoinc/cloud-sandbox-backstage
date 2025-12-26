{
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {
            "x": 0,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": {
                  "SubscriptionId": "${subscription_id}",
                  "ResourceGroup": "${resource_group_name}",
                  "Name": "${project}-${environment}-law"
                }
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {
              "content": {
                "Query": "Heartbeat | summarize LastHeartbeat = max(TimeGenerated) by Computer | where LastHeartbeat < ago(5m)",
                "ControlType": "AnalyticsGrid",
                "SpecificChart": "StackedColumn"
              }
            },
            "asset": {
              "idInputName": "ComponentId",
              "type": "Workspace"
            }
          }
        },
        "1": {
          "position": {
            "x": 6,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": {
                  "SubscriptionId": "${subscription_id}",
                  "ResourceGroup": "${resource_group_name}",
                  "Name": "${project}-${environment}-law"
                }
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {
              "content": {
                "Query": "Perf | where CounterName == \"% Processor Time\" | summarize AvgCPU = avg(CounterValue) by Computer, bin(TimeGenerated, 5m) | render timechart",
                "ControlType": "AnalyticsLineChart"
              }
            },
            "asset": {
              "idInputName": "ComponentId",
              "type": "Workspace"
            }
          }
        },
        "2": {
          "position": {
            "x": 0,
            "y": 4,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": {
                  "SubscriptionId": "${subscription_id}",
                  "ResourceGroup": "${resource_group_name}",
                  "Name": "${project}-${environment}-law"
                }
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {
              "content": {
                "Query": "Perf | where CounterName == \"% Used Memory\" or CounterName == \"Available MBytes Memory\" | summarize AvgMemory = avg(CounterValue) by Computer, bin(TimeGenerated, 5m) | render timechart",
                "ControlType": "AnalyticsLineChart"
              }
            },
            "asset": {
              "idInputName": "ComponentId",
              "type": "Workspace"
            }
          }
        },
        "3": {
          "position": {
            "x": 6,
            "y": 4,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": {
                  "SubscriptionId": "${subscription_id}",
                  "ResourceGroup": "${resource_group_name}",
                  "Name": "${project}-${environment}-law"
                }
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {
              "content": {
                "Query": "Perf | where CounterName == \"% Free Space\" | summarize AvgDiskFree = avg(CounterValue) by Computer, InstanceName, bin(TimeGenerated, 5m) | render timechart",
                "ControlType": "AnalyticsLineChart"
              }
            },
            "asset": {
              "idInputName": "ComponentId",
              "type": "Workspace"
            }
          }
        },
        "4": {
          "position": {
            "x": 0,
            "y": 8,
            "colSpan": 4,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [],
            "type": "Extension/HubsExtension/PartType/MarkdownPart",
            "settings": {
              "content": {
                "settings": {
                  "content": "# ${project} - ${environment}\n\n## Observability Dashboard\n\nThis dashboard provides an overview of your infrastructure and application health.\n\n**Resources Monitored:**\n- Log Analytics Workspace\n- Application Insights\n- Metric Alerts\n- Service Health",
                  "title": "Overview",
                  "subtitle": "${project}-${environment}"
                }
              }
            }
          }
        },
        "5": {
          "position": {
            "x": 4,
            "y": 8,
            "colSpan": 4,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": {
                  "SubscriptionId": "${subscription_id}",
                  "ResourceGroup": "${resource_group_name}",
                  "Name": "${project}-${environment}-law"
                }
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {
              "content": {
                "Query": "AzureActivity | where OperationNameValue contains \"Microsoft.Compute\" | summarize count() by OperationNameValue | top 10 by count_",
                "ControlType": "AnalyticsGrid"
              }
            },
            "asset": {
              "idInputName": "ComponentId",
              "type": "Workspace"
            }
          }
        },
        "6": {
          "position": {
            "x": 8,
            "y": 8,
            "colSpan": 4,
            "rowSpan": 3
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": {
                  "SubscriptionId": "${subscription_id}",
                  "ResourceGroup": "${resource_group_name}",
                  "Name": "${project}-${environment}-law"
                }
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {
              "content": {
                "Query": "AzureActivity | where Level == \"Error\" or Level == \"Critical\" | summarize count() by ResourceGroup, bin(TimeGenerated, 1h) | render columnchart",
                "ControlType": "AnalyticsLineChart"
              }
            },
            "asset": {
              "idInputName": "ComponentId",
              "type": "Workspace"
            }
          }
        },
        "7": {
          "position": {
            "x": 0,
            "y": 11,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": "${application_insights_id}"
              }
            ],
            "type": "Extension/AppInsightsExtension/PartType/MetricsExplorerBladePinnedPart",
            "settings": {},
            "asset": {
              "idInputName": "ComponentId",
              "type": "ApplicationInsights"
            },
            "isAdapter": true
          }
        },
        "8": {
          "position": {
            "x": 6,
            "y": 11,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": {
                  "SubscriptionId": "${subscription_id}",
                  "ResourceGroup": "${resource_group_name}",
                  "Name": "${project}-${environment}-law"
                }
              }
            ],
            "type": "Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart",
            "settings": {
              "content": {
                "Query": "ServiceHealth | where Level == \"Error\" or Level == \"Warning\" | project TimeGenerated, Title, ImpactedServices, ImpactedRegions, Status | order by TimeGenerated desc | take 20",
                "ControlType": "AnalyticsGrid"
              }
            },
            "asset": {
              "idInputName": "ComponentId",
              "type": "Workspace"
            }
          }
        }
      }
    }
  },
  "metadata": {
    "model": {
      "timeRange": {
        "value": {
          "relative": {
            "duration": 24,
            "timeUnit": 1
          }
        },
        "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
      },
      "filterLocale": {
        "value": "en-us"
      },
      "filters": {
        "value": {
          "MsPortalFx_TimeRange": {
            "model": {
              "format": "utc",
              "granularity": "auto",
              "relative": "24h"
            },
            "displayCache": {
              "name": "UTC Time",
              "value": "Past 24 hours"
            },
            "filteredPartIds": []
          }
        }
      }
    }
  }
}
