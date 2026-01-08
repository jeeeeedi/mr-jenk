# ✅ GitHub Webhook Setup - COMPLETE THIS NOW!

## 🚀 Your ngrok tunnel is ACTIVE!

**Webhook URL (copy this):**
```
https://hairy-tropological-eddy.ngrok-free.dev/github-webhook/
```

---

## 📝 GitHub Configuration Steps

### 1. Open your GitHub repository in browser
   - Go to: https://github.com/YOUR_USERNAME/YOUR_REPO

### 2. Navigate to Webhooks
   - Click: **Settings** (top menu)
   - Click: **Webhooks** (left sidebar)
   - Click: **Add webhook** (green button)

### 3. Configure the webhook
   Fill in these fields:

   | Field | Value |
   |-------|-------|
   | **Payload URL** | `https://hairy-tropological-eddy.ngrok-free.dev/github-webhook/` |
   | **Content type** | `application/json` |
   | **Secret** | Leave empty |
   | **SSL verification** | Enable SSL verification |
   | **Which events?** | ☑️ Just the push event |
   | **Active** | ☑️ Checked |

### 4. Save the webhook
   - Click **Add webhook** (green button at bottom)
   - GitHub will send a test ping
   - You should see a ✅ green checkmark appear

---

## 🧪 Test It!

```bash
# Make a test change
echo "# Webhook test - $(date)" >> README.md

# Commit and push
git add README.md
git commit -m "test: webhook trigger"
git push

# Check Jenkins - build should start automatically!
# Open: http://localhost:8080
```

---

## ⚙️ Important Notes

- ✅ **ngrok is running in background** (PID saved in /tmp/ngrok.pid)
- ✅ **Jenkins is running** on http://localhost:8080
- ⚠️ **Keep ngrok running** - if you stop it, webhook will break
- 💡 **If Mac restarts** - run `docker start jenkins` and then restart ngrok

### To stop ngrok:
```bash
kill $(cat /tmp/ngrok.pid)
```

### To restart ngrok:
```bash
ngrok http 8080 --log=stdout > /tmp/ngrok-output.log 2>&1 &
echo $! > /tmp/ngrok.pid
```

Then update GitHub webhook URL with the new ngrok URL.

---

## 🎯 Next Step

**Go to GitHub NOW and configure the webhook!**
