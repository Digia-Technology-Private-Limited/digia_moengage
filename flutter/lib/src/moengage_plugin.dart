import 'package:digia_engage/api/interfaces/digia_cep_delegate.dart';
import 'package:digia_engage/api/interfaces/digia_cep_plugin.dart';
import 'package:digia_engage/api/models/diagnostic_report.dart';
import 'package:digia_engage/api/models/digia_experience_event.dart';
import 'package:digia_engage/api/models/in_app_payload.dart';
import 'package:moengage_flutter/moengage_flutter.dart';

import 'cache/campaign_cache.dart';
import 'cache/i_campaign_cache.dart';
import 'event/moengage_event_dispatcher.dart';
import 'mapper/campaign_payload_mapper.dart';
import 'mapper/i_campaign_payload_mapper.dart';

/// Digia CEP plugin for MoEngage.
///
/// Bridges MoEngage's Self-Handled In-App campaign system into
/// Digia's rendering engine.
///
/// ## Usage
/// ```dart
/// final moEngage = MoEngageFlutter('YOUR_APP_ID');
/// moEngage.initialise();
///
/// Digia.initialize(DigiaConfig(apiKey: 'prod_xxxx'));
/// Digia.register(MoEngagePlugin(instance: moEngage));
/// ```
///
/// ## SOLID design
///

final class MoEngagePlugin implements DigiaCEPPlugin {
  final MoEngageFlutter _moEngage;
  final ICampaignPayloadMapper _mapper;
  final ICampaignCache _cache;
  late final MoEngageEventDispatcher _dispatcher;

  DigiaCEPDelegate? _delegate;

  /// Creates a [MoEngagePlugin] wrapping an existing [MoEngageFlutter] instance.
  ///
  /// The [instance] must already have been initialised via
  /// [MoEngageFlutter.initialise] before being passed here.
  ///
  /// [cache] and [mapper] are optional — default implementations are used when
  /// omitted. Provide custom implementations for testing or alternative strategies.
  MoEngagePlugin({
    required MoEngageFlutter instance,
  })  : _moEngage = instance,
        _cache = CampaignCache(),
        _mapper = const CampaignPayloadMapper() {
    _dispatcher = MoEngageEventDispatcher(
      moEngage: _moEngage,
      cache: _cache,
    );
  }

  // --- DigiaCEPPlugin --------------------------------------------------------

  @override
  String get identifier => 'moengage';

  @override
  void setup(DigiaCEPDelegate delegate) {
    _delegate = delegate;
    _moEngage.setSelfHandledInAppHandler(_onSelfHandledInApp);
    Logger.i(
        '$identifier: setup complete — listening for self-handled in-app campaigns');
  }

  @override
  void forwardScreen(String name) {
    _moEngage.setCurrentContext([name]);
    Logger.i('$identifier: forwardScreen → $name');
  }

  @override
  void notifyEvent(DigiaExperienceEvent event, InAppPayload payload) {
    final campaignId = payload.cepContext['campaignId'] as String?;
    if (campaignId == null) {
      Logger.w('$identifier: notifyEvent — missing campaignId in cepContext');
      return;
    }

    _dispatcher.dispatch(event, campaignId);
  }

  @override
  void teardown() {
    _moEngage.setSelfHandledInAppHandler(null);
    _delegate = null;
    _cache.clear();
    Logger.i('$identifier: teardown complete');
  }

  @override
  DiagnosticReport healthCheck() {
    if (_delegate == null) {
      return const DiagnosticReport(
        isHealthy: false,
        issue: 'Plugin has no delegate — setup() has not been called.',
        resolution:
            'Call Digia.register(MoEngagePlugin(...)) before using the SDK.',
      );
    }

    return DiagnosticReport(
      isHealthy: true,
      metadata: {
        'identifier': identifier,
        'delegateSet': true,
        'cachedCampaigns': _cache.count,
        'cachedCampaignIds': _cache.campaignIds,
      },
    );
  }

  // --- Private ---------------------------------------------------------------

  /// Called by MoEngage when a self-handled in-app campaign is ready.
  void _onSelfHandledInApp(SelfHandledCampaignData? data) {
    if (data == null) {
      Logger.w('$identifier: received null SelfHandledCampaignData — skipping');
      return;
    }

    final payload = _mapper.map(data);
    _cache.put(payload.id, data);

    Logger.i('$identifier: campaign ready — id=${payload.id}');
    _delegate?.onCampaignTriggered(payload);
  }
}
