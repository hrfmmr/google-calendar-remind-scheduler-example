{
  Architectures: [
    'arm64',
  ],
  Description: '',
  EphemeralStorage: {
    Size: 512,
  },
  Environment: {
    Variables: {
      LOG_LEVEL: 'INFO',
      GOOGLE_CALENDAR_ID: '{{ env `GOOGLE_CALENDAR_ID` }}',
      SLACK_CHANNEL_ID: '{{ env `SLACK_CHANNEL_ID` }}',
      PARAM_KEY_SERVICE_ACCOUNT_JSON: '{{ env `PARAM_KEY_SERVICE_ACCOUNT_JSON` }}',
      PARAM_KEY_SLACK_API_TOKEN: '{{ env `PARAM_KEY_SLACK_API_TOKEN` }}',
    },
  },
  FunctionName: 'schedule-reminder',
  Handler: 'main.lambda_handler',
  MemorySize: 128,
  Role: '{{ tfstate `aws_iam_role.lambda_exec_iam_role.arn` }}',
  Runtime: 'python3.10',
  SnapStart: {
    ApplyOn: 'None',
  },
  Tags: {},
  Timeout: 15,
  TracingConfig: {
    Mode: 'PassThrough',
  },
}
