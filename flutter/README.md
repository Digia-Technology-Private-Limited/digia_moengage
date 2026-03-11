# digia_moengage_plugin

A Flutter plugin that bridges MoEngage self-handled in-app campaigns with Digia's rendering engine.

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  digia_moengage_plugin: ^1.0.0-beta.1
  digia_engage: ^1.0.0-beta.1
  moengage_flutter: ^10.5.0
```

## Quick Start

```dart
import 'package:digia_moengage_plugin/digia_moengage_plugin.dart';
import 'package:digia_engage/digia_engage.dart';
import 'package:moengage_flutter/moengage_flutter.dart';

void main() async {
  // Initialize MoEngage
  final moEngage = MoEngageFlutter('YOUR_APP_ID');
  await moEngage.initialise();

  // Initialize Digia
  await Digia.initialize(DigiaConfig(apiKey: 'your-api-key'));

  // Register plugin
  Digia.register(MoEngagePlugin(instance: moEngage));

  runApp(const MyApp());
}
```

## Setup

1. Configure MoEngage following their [Flutter SDK docs](https://moengage.gitbook.io/moengage-flutter-sdk/)
2. Initialize Digia SDK with your credentials
3. Register the plugin with Digia after both are initialized
4. Use `Digia.forwardScreen()` when navigating to trigger campaign delivery

## How It Works

MoEngage Campaign → Plugin bridges to Digia → Digia renders → Events sent back to MoEngage

## Architecture


## Troubleshooting

**Campaigns not appearing?**
- Verify plugin registered: `Digia.register(MoEngagePlugin(instance: moEngage))`
- Ensure MoEngage initialized before Digia
- Check iOS deployment target ≥ 12.0
- Check campaign eligibility in MoEngage dashboard

**Build/Setup Issues?**
- Run `flutter clean && flutter pub get`
- Verify all dependencies in pubspec.yaml

## Platforms

- **iOS**: ✅ 12.0+
- **Android**: ✅ API 21+

## License

MIT License - see [LICENSE](LICENSE)

## More Info

- See [CHANGELOG.md](CHANGELOG.md) for version history
- [Digia Engage](https://pub.dev/packages/digia_engage) - Core plugin interface
- [MoEngage Flutter](https://pub.dev/packages/moengage_flutter) - MoEngage SDK
- Issues: [GitHub Issues](https://github.com/Digia-Technology-Private-Limited/digia_moengage/issues)
