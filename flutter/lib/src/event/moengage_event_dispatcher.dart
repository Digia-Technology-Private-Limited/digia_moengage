import 'package:digia_engage/api/models/digia_experience_event.dart';
import 'package:moengage_flutter/moengage_flutter.dart';

import '../cache/i_campaign_cache.dart';

/// Dispatches [DigiaExperienceEvent]s to the corresponding MoEngage
/// self-handled in-app lifecycle APIs.
///
/// ## Strategy pattern
/// Event dispatch is a dedicated responsibility, isolated here so that
/// [MoEngagePlugin] is **closed for modification** when new event types
/// are added. Only this class is updated — the plugin orchestrator is unchanged.
///
/// Dart's sealed-class exhaustive `switch` provides compile-time safety:
/// adding a new [DigiaExperienceEvent] subtype causes a compile error here
/// rather than a silent runtime miss.
///
/// ## Dependencies
/// - [MoEngageFlutter]: MoEngage lifecycle APIs (shown / clicked / dismissed).
/// - [ICampaignCache]: resolves the cached [SelfHandledCampaignData] required
///   by the MoEngage APIs, and evicts entries post-dismiss.
final class MoEngageEventDispatcher {
  final MoEngageFlutter _moEngage;
  final ICampaignCache _cache;

  const MoEngageEventDispatcher({
    required MoEngageFlutter moEngage,
    required ICampaignCache cache,
  })  : _moEngage = moEngage,
        _cache = cache;

  /// Resolves cached [SelfHandledCampaignData] for [campaignId] and forwards
  /// [event] to the appropriate MoEngage lifecycle API.
  ///
  /// Returns `true` on successful dispatch, `false` when [campaignId] is
  /// absent from the cache (guard against stale events).
  bool dispatch(DigiaExperienceEvent event, String campaignId) {
    final data = _cache.get(campaignId);
    if (data == null) {
      Logger.w(
        'MoEngageEventDispatcher: no cached data for campaignId=$campaignId',
      );
      return false;
    }

    switch (event) {
      case ExperienceImpressed():
        _moEngage.selfHandledShown(data);
        Logger.v('dispatched: selfHandledShown — campaignId=$campaignId');

      case ExperienceClicked():
        _moEngage.selfHandledClicked(data);
        Logger.v('dispatched: selfHandledClicked — campaignId=$campaignId');

      case ExperienceDismissed():
        _moEngage.selfHandledDismissed(data);
        // Campaign lifecycle is complete — evict the entry.
        _cache.remove(campaignId);
        Logger.v('dispatched: selfHandledDismissed — campaignId=$campaignId');
    }

    return true;
  }
}
