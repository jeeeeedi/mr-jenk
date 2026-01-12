# 🔴 URGENT: Update Jenkins Credentials

## The Problem
Your MongoDB authentication is failing because the **Jenkins credentials** still contain the OLD values:
- Current (wrong): `root` / `example`
- Needed (correct): `admin` / `gritlab25`

The `.env.production` file in your repository has correct values, but Jenkins **generates a new one from credentials** every build, overwriting it with wrong values.

## How to Fix in Jenkins Dashboard

1. **Go to Jenkins Dashboard** → **Manage Jenkins** → **Credentials** → **System** → **Global credentials**

2. **Update `mongo-root-username`**:
   - Click on `mongo-root-username`
   - Click "Update" 
   - Change **Secret** from `root` to `admin`
   - Click "Save"

3. **Update `mongo-root-password`**:
   - Click on `mongo-root-password`
   - Click "Update"
   - Change **Secret** from `example` to `gritlab25`
   - Click "Save"

4. **Trigger Build #89** manually or push a commit

## Why This Happened
- Your friend likely set up the credentials initially with default MongoDB values
- These credentials are stored in Jenkins and persist across builds
- The Jenkinsfile generates `.env.production` from these credentials on line 193-194
- Even though your repo has correct values, Jenkins overwrites them during deploy

## Verification
After updating, Build #89 logs will show:
```
[DEBUG] Verifying transferred .env on AWS:
MONGO_ROOT_USERNAME=admin
```
(Instead of `root`)

Then user-service will start successfully! ✅
