# AppsFlyer Setup Guide

## Quick Start

### 1. Set environment variables

```bash
export AF_DEV_KEY="your_appsflyer_dev_key"
export AF_APP_ID="123456789"  # iOS App ID (digits only)
```

### 2. Run the app

**Option A: Using the helper script**
```bash
./run_with_env.sh
```

**Option B: Direct flutter run**
```bash
flutter run \
  --dart-define=AF_DEV_KEY="your_dev_key" \
  --dart-define=AF_APP_ID="your_app_id"
```

**Option C: VS Code launch.json**
Add to `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter with AppsFlyer",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=AF_DEV_KEY=your_dev_key",
        "--dart-define=AF_APP_ID=your_app_id"
      ]
    }
  ]
}
```

## iOS Setup (required)

Add to `ios/Runner/Info.plist`:
```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use the advertising identifier to improve campaign attribution.</string>
```

## Verification

1. Run the app on a **physical device** (simulator events may not appear in dashboard)
2. Check Xcode/Android Studio console for:
   - `[AppsFlyer] SDK started: {status: true}`
   - `[AppsFlyer] Event "af_login" logged: true`
3. Check AppsFlyer dashboard (Development/Sandbox view)

## Troubleshooting

- **Error: AF_DEV_KEY not provided**
  - Ensure you're passing `--dart-define` correctly
  - Check env vars are set: `echo $AF_DEV_KEY`

- **Events not in dashboard**
  - Use physical device, not simulator
  - Check bundle ID matches app in AppsFlyer
  - Wait 2-5 minutes for events to appear

