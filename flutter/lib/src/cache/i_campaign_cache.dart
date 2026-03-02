import 'package:moengage_flutter/moengage_flutter.dart';

/// Abstraction for MoEngage self-handled campaign data caching.
///
/// Decouples lifecycle-event correlation from any particular storage
/// strategy — an in-memory map, an LRU cache, or a persistent store may be
/// injected without touching [MoEngagePlugin] or [MoEngageEventDispatcher].
///
/// **DIP**: dependants reference this interface, not the concrete [CampaignCache].
abstract interface class ICampaignCache {
  /// Stores [data] keyed by [campaignId].
  void put(String campaignId, SelfHandledCampaignData data);

  /// Returns the cached [SelfHandledCampaignData] for [campaignId],
  /// or `null` when absent.
  SelfHandledCampaignData? get(String campaignId);

  /// Removes the entry for [campaignId] (call after campaign lifecycle ends).
  void remove(String campaignId);

  /// Evicts all entries (call during plugin teardown).
  void clear();

  /// Number of currently cached campaigns.
  int get count;

  /// Read-only list of currently cached campaign IDs (for diagnostics).
  List<String> get campaignIds;
}
