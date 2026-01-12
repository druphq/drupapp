# 🔒 API Security Guide

## Overview
This project uses environment variables and configuration files to keep API keys and sensitive data secure and out of version control.

## Setup Instructions

### 1. Flutter Environment Variables

**Step 1:** Copy the example file:
```bash
cp .env.example .env
```

**Step 2:** Edit `.env` and add your actual API keys:
```env
GOOGLE_MAPS_API_KEY=your_actual_api_key_here
```

### 2. Android Configuration

**Step 1:** The `android/local.properties` file already exists. Add your API key:
```properties
googleMapsApiKey=your_actual_api_key_here
```

**Step 2:** For reference, you can check `android/local.properties.example`

### 3. iOS Configuration

**Step 1:** Copy the example file:
```bash
cp ios/Runner/Config.plist.example ios/Runner/Config.plist
```

**Step 2:** Edit `ios/Runner/Config.plist` and add your actual API key:
```xml
<key>GOOGLE_MAPS_API_KEY</key>
<string>your_actual_api_key_here</string>
```

## Important Files (Never Commit!)

These files are already in `.gitignore` and should **NEVER** be committed:
- `.env`
- `android/local.properties`
- `ios/Runner/Config.plist`
- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`

## Safe to Commit

These template files are safe to commit as they don't contain real keys:
- `.env.example`
- `android/local.properties.example`
- `ios/Runner/Config.plist.example`

## Getting Your Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable **Maps SDK for Android** and **Maps SDK for iOS**
4. Go to **Credentials** → **Create Credentials** → **API Key**
5. **Restrict your API key:**
   - For Android: Add your app's package name and SHA-1 certificate fingerprint
   - For iOS: Add your app's bundle identifier
   - Restrict to only the APIs you need (Maps SDK, Directions API, etc.)

## If API Keys Were Already Pushed to GitHub

If you've already committed API keys:

1. **Immediately regenerate the API keys** in Google Cloud Console
2. Delete the old keys
3. Update all configuration files with new keys
4. Remove keys from Git history:
   ```bash
   # Use BFG Repo-Cleaner or git-filter-repo
   git filter-repo --path-glob '**/.env' --invert-paths
   ```
5. Force push (⚠️ Warning: This rewrites history)
   ```bash
   git push origin --force --all
   ```

## Team Setup

When setting up a new developer:

1. Share the `.env.example` file (committed)
2. Privately share the actual API keys (via secure channel)
3. Have them create their own `.env` and config files
4. Never share keys via email, Slack, or other unsecured channels

## Verification

Before committing, always check:
```bash
# Ensure sensitive files are ignored
git status

# Should NOT see:
# - .env
# - android/local.properties
# - ios/Runner/Config.plist
```

## Best Practices

✅ **DO:**
- Use environment variables for all sensitive data
- Keep `.gitignore` up to date
- Rotate API keys regularly
- Use separate keys for development and production
- Add API restrictions in Google Cloud Console

❌ **DON'T:**
- Commit `.env` files
- Share API keys in code reviews
- Use production keys in development
- Hardcode any sensitive data
- Share keys in public channels

## Troubleshooting

### "API key not found" error
- Ensure `.env` file exists and contains `GOOGLE_MAPS_API_KEY`
- Run `flutter pub get` after adding dependencies
- Restart the app completely

### Android build fails
- Check `android/local.properties` has `googleMapsApiKey`
- Verify the key is on a single line with no quotes

### iOS build fails
- Ensure `ios/Runner/Config.plist` exists and is properly formatted
- Check the file is included in the Xcode project

## Support

For issues or questions about API security, consult:
- [Flutter Security Best Practices](https://flutter.dev/docs/deployment/security)
- [Google Maps Platform Best Practices](https://developers.google.com/maps/api-security-best-practices)
