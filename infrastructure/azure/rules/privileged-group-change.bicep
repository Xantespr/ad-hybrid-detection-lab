
targetScope = 'resourceGroup'

param workspaceName string = 'law-ad-detection-lab'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource privilegedGroupRule 'Microsoft.SecurityInsights/alertRules@2025-09-01' = {
  name: 'ad-privileged-group-change'
  scope: workspace
  kind: 'Scheduled'
  properties: {
    displayName: 'AD - Monitored Group Member Added'
    description: 'Detects members added to selected Active Directory security groups.'
    enabled: true
    severity: 'Medium'

    query: '''
        SecurityEvent
        | where TimeGenerated >= ago(1h)
        | where ingestion_time() > ago(15m)
        | where EventID == 4728
        | where TargetUserName in~ ('Domain Admins', 'LAB-Audit-Test')
        | project
            TimeGenerated,
            Computer,
            EventID,
            GroupName = TargetUserName,
            AddedMember = MemberName,
            Initiator = SubjectAccount
    '''

    queryFrequency: 'PT15M'
    queryPeriod: 'PT1H'

    triggerOperator: 'GreaterThan'
    triggerThreshold: 0

    suppressionEnabled: false
    suppressionDuration: 'PT1H'

    tactics: [
      'Persistence'
      'PrivilegeEscalation'
    ]
    techniques: [
      'T1098'
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
