# Email Notifications Setup Guide

## Overview

The Jenkins pipeline is configured to send automated email notifications to team members for all build outcomes (success, failure, unstable). Notifications include:

- ✅ **Success Emails** - Build completed successfully, deployment in production
- ❌ **Failure Emails** - Build failed, detailed error information, remediation steps
- ⚠️ **Unstable Emails** - Build completed but with test failures or warnings

## Jenkins Configuration

### 1. Install Required Plugins

Email notifications require the `Email Extension Plugin`:

**Via Jenkins UI:**
1. Go to **Manage Jenkins** → **Plugin Manager**
2. Search for "**Email Extension Plugin**"
3. Click **Install** and restart Jenkins

**Via Jenkins CLI:**
```bash
java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin email-ext restart
```

### 2. Configure Jenkins Email Settings

**Navigate to:** Manage Jenkins → Configure System → Email Notification

Set the following:

| Setting | Value |
|---------|-------|
| **SMTP Server** | `smtp.gmail.com` (or your mail server) |
| **SMTP Port** | `587` (TLS) or `465` (SSL) |
| **Use SMTP Authentication** | ✅ Checked |
| **SMTP Username** | `your-email@gmail.com` |
| **SMTP Password** | Your email password or app-specific password |
| **Use TLS** | ✅ Checked |
| **From Address** | `jenkins@yourcompany.com` |
| **Reply-To Address** | `devops@yourcompany.com` |

### 3. Configure Extended Email Settings

**Navigate to:** Manage Jenkins → Configure System → Extended E-mail Notification

| Setting | Value |
|---------|-------|
| **SMTP Server** | Same as above |
| **SMTP Port** | `587` |
| **SMTP Authentication Username** | Your email account |
| **SMTP Authentication Password** | Your password |
| **Use TLS** | ✅ Checked |
| **MIME Type** | `text/html` |
| **Default Recipients** | Leave blank (configured in pipeline) |
| **Default Subject** | Leave blank (configured in pipeline) |

## Jenkinsfile Configuration

### Email Recipients

In the Jenkinsfile, update the email addresses in the `environment` section:

```groovy
environment {
    TEAM_EMAIL = 'othmane.afilali@gritlab.ax,jedi.reston@gritlab.ax'              // All team members
}
```

**Add multiple addresses:**
```groovy
TEAM_EMAIL = 'othmane.afilali@gritlab.ax,jedi.reston@gritlab.ax'
```

**Or use distribution lists:**
```groovy
TEAM_EMAIL = 'othmane.afilali@gritlab.ax,jedi.reston@gritlab.ax'
```

### Email Notification Rules

The pipeline uses the `emailext()` step with the following logic:

**Success Email:**
- Sent to: `${TEAM_EMAIL}`
- Recipients include: Build requestor, previous broken build suspects
- Contains: Build details, test results, deployment confirmation

**Failure Email:**
- Sent to: `${TEAM_EMAIL}`
- Recipients include: Developers involved, build requestor
- Contains: Error details, failure cause analysis, remediation steps
- Priority: **HIGH** - Goes to leads and DevOps immediately

**Unstable Email:**
- Sent to: `${TEAM_EMAIL}`
- Recipients include: Build requestor
- Contains: Build details, test failure summary
- Priority: **MEDIUM** - Informational warning

## Email Content

### Success Email Includes:
```
✅ Build Successful
├── Build Information (number, duration, branch, commit)
├── Completed Stages (all stages checked ✅)
├── Test Results (all tests passed)
├── Deployment Status (live in production)
└── Useful Links (console, test report, build details)
```

### Failure Email Includes:
```
❌ Build Failed - URGENT
├── Alert Box (immediate action required)
├── Build Information (with FAILED badge)
├── Possible Failure Causes (test/compile/deploy issues)
├── Required Actions (step-by-step remediation)
├── Important Links (console output, test report)
└── Deployment Status (previous version still running if deployed)
```

### Unstable Email Includes:
```
⚠️ Build Unstable
├── Build Summary
├── Test Report Link
└── Recommendation to review
```

## Using Gmail

If using Gmail as your SMTP server:

### Step 1: Enable 2-Factor Authentication
1. Go to **Google Account** → **Security**
2. Enable **2-Step Verification**

### Step 2: Create App Password
1. Go to **Google Account** → **App passwords**
2. Select "Mail" and "Windows Computer"
3. Google generates a 16-character password
4. Use this password in Jenkins SMTP configuration (NOT your Gmail password)

### Step 3: Configure Jenkins
- **SMTP Server:** `smtp.gmail.com`
- **SMTP Port:** `587` (with TLS)
- **Username:** `your-email@gmail.com`
- **Password:** The 16-character app password from step 2
- **Use TLS:** ✅ Checked

## Testing Email Configuration

### Test from Jenkins UI:
1. Manually trigger a build
2. Check that emails are received after build completion
3. Verify email content and formatting

### Test Email Sending:
In Jenkins, navigate to Manage Jenkins → Configure System → Email Notification

Click the **"Test Configuration"** button to send a test email.

## Troubleshooting

### Emails Not Sending

**Problem:** No emails received after builds
**Solutions:**
1. Check Jenkins logs: `jenkins.log` or Jenkins UI → Logs
2. Verify SMTP credentials are correct
3. Check firewall/network access to SMTP server (port 587 or 465)
4. Test with a simple text email first before HTML
5. Check email spam/junk folder

**Check Logs:**
```bash
# View Jenkins logs
tail -f /var/log/jenkins/jenkins.log | grep -i email
```

### HTML Formatting Issues

**Problem:** Email shows HTML code instead of formatted content
**Solution:**
Ensure `mimeType: 'text/html'` is set in the Jenkinsfile:
```groovy
emailext(
    ...
    mimeType: 'text/html'
)
```

### Incorrect Recipients

**Problem:** Wrong people receiving emails
**Solution:**
1. Double-check email addresses in environment variables
2. Verify `recipientProviders` parameters
3. Check Jenkins user configuration for developer emails

### SMTP Authentication Failed

**Problem:** "Authentication failed" errors in logs
**Solutions:**
1. Verify username and password are correct
2. For Gmail, use app-specific password (not Gmail password)
3. Check if less secure app access is enabled (for non-Gmail SMTP)
4. Verify TLS/SSL settings match your SMTP provider

## Advanced Configuration

### Custom Email Templates

To use custom email templates instead of inline HTML:

1. Create template files in Jenkins home directory:
   ```
   $JENKINS_HOME/email-templates/
   ├── success.html
   ├── failure.html
   └── unstable.html
   ```

2. Reference in Jenkinsfile:
   ```groovy
   emailext(
       subject: "...",
       body: readFile('email-templates/success.html'),
       ...
   )
   ```

### Email Triggers

Configure additional email triggers:

```groovy
emailext(
    ...
    recipientProviders: [
        brokenBuildSuspects(),      // Developers who broke the build
        requestor(),                 // Person who triggered the build
        developers(),                // All developers involved
        culprits()                   // Developers who changed code
    ]
)
```

### Conditional Emails

Send different emails based on stage failures:

```groovy
script {
    def failedStage = 'Unknown'
    if (currentBuild.result == 'FAILURE') {
        // Determine which stage failed
        failedStage = env.STAGE_NAME ?: 'Unknown'
    }
    // Use failedStage in email subject/body
}
```

## Best Practices

1. **Use Distribution Lists** - Don't list individual emails, use team distribution lists
2. **Keep Emails Concise** - Focus on actionable information
3. **Include Links** - Always provide links to logs and test reports
4. **Test Thoroughly** - Send test emails to verify configuration
5. **Monitor Spam** - Regularly check spam folder for legitimate emails
6. **Update Addresses** - Keep team email list updated as team changes
7. **Use HTML Format** - Formatted HTML emails are more readable than plain text
8. **Archive Logs** - Keep build logs accessible for audits

## Email Retention

Jenkins stores email logs in:
```
$JENKINS_HOME/jobs/<job-name>/builds/<build-number>/log
```

To retain email records:
1. Archive console logs
2. Store in centralized logging system (e.g., ELK Stack)
3. Create build notifications history in Slack (optional integration)

## Slack Integration (Optional)

For real-time notifications in Slack:

1. Install **Slack Notification Plugin** in Jenkins
2. Create a Slack webhook
3. Add to Jenkinsfile:
   ```groovy
   slack(
       channel: '#devops',
       webhookUrl: 'YOUR_SLACK_WEBHOOK_URL',
       message: "Build ${BUILD_NUMBER} ${currentBuild.result}"
   )
   ```

## Summary

The email notification system is now configured to:
- ✅ Send success emails to the entire team
- ❌ Send urgent failure emails to DevOps and leads
- ⚠️ Send warning emails for unstable builds
- 📎 Include comprehensive information and links
- 🔗 Provide direct access to logs and test reports

All team members will be immediately informed of build status, enabling faster incident response and deployment verification.
