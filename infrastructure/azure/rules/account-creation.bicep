
targetScope = 'resourceGroup'

param workspaceName string = 'law-ad-detection-lab'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource accountCreationRule 'Microsoft.SecurityInsights/alertRules@2025-09-01' = {
  name: 'ad-domain-user-account-created'
  scope: workspace
  kind: 'Scheduled'
  properties: {
    displayName: 'AD - Domain User Account Created'
    description: 'Detects the creation of new domain user accounts.'
    enabled: true
    severity: 'Low'

    query: '''
        SecurityEvent
        | where TimeGenerated >= ago(1h)
        | where ingestion_time() > ago(15m)
        | where EventID == 4720
        | project
            TimeGenerated,
            Computer,
            EventID,
            TargetAccount,
            SubjectAccount,
            Activity
    '''

    queryFrequency: 'PT15M'
    queryPeriod: 'PT1H'
    triggerOperator: 'GreaterThan'
    triggerThreshold: 0

    suppressionEnabled: false
    suppressionDuration: 'PT1H'

    tactics: [
      'Persistence'
    ]
    techniques: [
      'T1136'
    ]

    eventGroupingSettings: {
      aggregationKind: 'AlertPerResult'
    }

    incidentConfiguration: {
      createIncident: true
      groupingConfiguration: {
        enabled: false
        reopenClosedIncident: false
        lookbackDuration: 'PT5H'
        matchingMethod: 'AnyAlert'
        groupByEntities: []
        groupByAlertDetails: []
        groupByCustomDetails: []
      }
    }
  }
}
