
targetScope = 'resourceGroup'

param workspaceName string = 'law-ad-detection-lab'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource kerberoastingRule 'Microsoft.SecurityInsights/alertRules@2025-09-01' = {
  name: 'ad-kerberoasting'
  scope: workspace
  kind: 'Scheduled'
  properties: {
    displayName: 'AD - Potential Kerberoasting'
    description: 'Detects suspicious RC4-encrypted Kerberos service ticket requests.'
    enabled: true
    severity: 'Medium'
    query: '''
        SecurityEvent
        | where TimeGenerated >= ago(1h)
        | where ingestion_time() > ago(15m)
        | where EventID == 4769
        | extend EncryptionType = extract(
            'Name="TicketEncryptionType">([^<]+)<', 1, EventData
        )
        | extend ServiceAccount = extract(
            'Name="ServiceName">([^<]+)<', 1, EventData
        )
        | extend ResultCode = extract(
            'Name="Status">([^<]+)<', 1, EventData
        )
        | where EncryptionType =~ '0x17'
        | where ResultCode =~ '0x0'
        | where isnotempty(ServiceAccount)
        | where ServiceAccount !endswith '$'
        | where ServiceAccount !~ 'krbtgt'
        | project
            TimeGenerated,
            Computer,
            TargetUserName,
            ServiceAccount,
            IpAddress,
            EncryptionType
    '''



    queryFrequency: 'PT15M'
    queryPeriod: 'PT1H'

    triggerOperator: 'GreaterThan'
    triggerThreshold: 0

    suppressionEnabled: false
    suppressionDuration: 'PT1H'

    tactics: [
      'CredentialAccess'
    ]
    techniques: [
      'T1558'
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
