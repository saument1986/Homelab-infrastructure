# Slack Webhook Setup Guide

## Step 1: Create a Slack App

1. Go to https://api.slack.com/apps
2. Click "Create New App"
3. Select "From scratch"
4. Name: "Wazuh Security Alerts"
5. Choose your workspace
6. Click "Create App"

## Step 2: Enable Incoming Webhooks

1. In your app settings, click "Incoming Webhooks"
2. Toggle "Activate Incoming Webhooks" to ON
3. Click "Add New Webhook to Workspace"
4. Select the channel for security alerts (e.g., #security-alerts)
5. Click "Allow"

## Step 3: Copy Webhook URL

Copy the webhook URL that looks like:
```
https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX
```

## Step 4: Configure App Settings (Optional)

### App Icon and Display Name
1. Go to "Basic Information"
2. Upload a security-related icon
3. Set display name: "Wazuh Security Bot"
4. Set default username: "wazuh-alerts"

### App Description
- Short Description: "Security alerts from Wazuh SIEM"
- Long Description: "Automated security monitoring and threat detection alerts from your homelab Wazuh SIEM system"

## Step 5: Create Channel

Create a dedicated channel for security alerts:
1. In Slack, create channel: `#security-alerts`
2. Add relevant team members
3. Set channel topic: "🔒 Security alerts from Wazuh SIEM - homelab monitoring"
4. Pin this message: "This channel receives automated security alerts. High severity alerts require immediate attention."

## Step 6: Test Webhook

Test your webhook with curl:
```bash
curl -X POST -H 'Content-type: application/json' \
--data '{"text":"🔒 Wazuh Slack integration test - webhook working correctly!"}' \
YOUR_WEBHOOK_URL_HERE
```

## Next Steps

1. Save your webhook URL securely
2. Run the Wazuh integration setup script
3. Configure alert filtering levels
4. Test different alert types