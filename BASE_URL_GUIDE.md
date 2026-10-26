# Base URL Configuration — Student App

The base URL is set in one place:

```dart
// lib/services/api_service.dart  
static const String baseUrl = 'http://10.0.2.2:3001';
```

## When to change it

| Target                         | `baseUrl` value                          |
|-------------------------------|------------------------------------------|
| Android Emulator (localhost)  | `http://10.0.2.2:3001`                  |
| iOS Simulator (localhost)     | `http://localhost:3001`                 |
| Physical Android/iOS device   | `http://<YOUR_COMPUTER_LAN_IP>:3001`    |
| Production (Render deployed)  | `https://bustransit-g4ks.onrender.com`  |

## Finding your LAN IP (for physical device testing)

```powershell
ipconfig | findstr IPv4
```

Replace `baseUrl` with your machine's IP, e.g. `http://192.168.1.42:3001`.

## Android cleartext traffic

If using HTTP (not HTTPS) on a physical Android device, you need to allow cleartext
traffic. Add this to `android/app/src/main/AndroidManifest.xml` inside `<application>`:

```xml
android:usesCleartextTraffic="true"
```
