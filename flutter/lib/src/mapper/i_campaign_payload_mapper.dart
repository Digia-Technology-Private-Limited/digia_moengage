import 'package:digia_engage/api/models/in_app_payload.dart';
import 'package:moengage_flutter/moengage_flutter.dart';

/// Abstraction for translating MoEngage campaign data into a Digia [InAppPayload].
///
/// Isolates the transformation concern so that mapping logic can evolve
/// (e.g. different JSON schemas) without touching the plugin orchestrator.
///
/// **DIP**: [MoEngagePlugin] depends on this interface, not the concrete
/// [CampaignPayloadMapper], enabling substitution and test doubles.
abstract interface class ICampaignPayloadMapper {
  /// Translates [data] from MoEngage into a Digia [InAppPayload].
  InAppPayload map(SelfHandledCampaignData data);
}
