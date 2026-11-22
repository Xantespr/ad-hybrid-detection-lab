
targetScope = 'resourceGroup'

param workspaceName string = 'law-ad-detection-lab'

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource passwordSprayingRule 'Microsoft.SecurityInsights/alertRules@2025-09-01' = {
  name: 'ad-password-spraying'
  scope: workspace
  kind: 'Scheduled'
  properties: {
    displayName: 'AD - Potential Password Spraying'
    description: 'Detects failed Kerberos or NTLM authentication attempts against multiple AD accounts from one source.'
    enabled: true
    severity: 'Medium'


    query: '''
        SecurityEvent
        | where TimeGenerated >= ago(1h)
        | where EventID in (4771, 4776)
        | extend FailureCode = toupper(coalesce(
            extract('Name="Status">([^<]+)<', 1, EventData),
            extract('Name="ErrorCode">([^<]+)<', 1, EventData),
            Status
        ))
        | where (EventID == 4771 and FailureCode == '0X18')
            or (EventID == 4776 and FailureCode == '0XC000006A')
        | extend AccountName = coalesce(TargetUserName, TargetAccount)
        | extend Source = iff(
            EventID == 4771,
            coalesce(IpAddress, extract('Name="IpAddress">([^<]+)<', 1, EventData)),
            coalesce(Workstation, extract('Name="Workstation">([^<]+)<', 1, EventData))
        )
        | where isnotempty(Source) and isnotempty(AccountName)
        | where AccountName !endswith '$'
        | summarize
            Attempts = count(),
            Accounts = dcount(AccountName),
            Users = make_set(AccountName, 20),
            LastSeen = max(TimeGenerated),
            LastIngestion = max(ingestion_time())
            by Source, EventID, bin(TimeGenerated, 30m)
        | where Accounts >= 3
        | where LastIngestion > ago(15m)
        | project
            TimeGenerated = LastSeen,
            Source,
            EventID,
            Attempts,
            Accounts,
            Users
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
      'T1110'
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
