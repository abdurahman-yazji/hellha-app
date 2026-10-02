# hellha

A new Flutter project.

## API configuration

Android Emulator development uses `http://10.0.2.2:3000/api` by default. To
use another backend, pass its base URL at build or run time:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com/api
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com/api
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com/api
```

Production builds must use the public HTTPS API URL, including the `/api`
prefix. `API_BASE_URL` is compiled into the client and is not a place for
secrets. Do not put credentials, private keys, or tokens in `--dart-define`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
