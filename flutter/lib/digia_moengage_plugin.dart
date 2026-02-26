/// Digia MoEngage Plugin
///
/// Registers MoEngage as a CEP (Customer Engagement Platform) provider
/// for the Digia SDK. Import this library and call [Digia.register] with
/// a [MoEngagePlugin] instance to enable MoEngage self-handled in-app
/// campaigns inside your Digia-powered app.
///
/// ```dart
/// import 'package:digia_moengage_plugin/digia_moengage_plugin.dart';
///
/// final moEngage = MoEngageFlutter('YOUR_APP_ID');
/// moEngage.initialise();
///
/// Digia.initialize(DigiaConfig(apiKey: 'prod_xxxx'));
/// Digia.register(MoEngagePlugin(instance: moEngage));
/// ```
library digia_moengage_plugin;

export 'src/moengage_plugin.dart';
