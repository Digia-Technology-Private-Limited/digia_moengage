import 'package:moengage_flutter/moengage_flutter.dart';

import 'i_campaign_cache.dart';

/// In-memory implementation of [ICampaignCache].
///
/// Backed by a plain [Map]; entries are evicted per-campaign on [remove]
/// (post-dismiss) and globally on [clear] (teardown).
///
/// Swap this with an LRU or persistent cache by implementing [ICampaignCache]
/// and injecting it into [MoEngagePlugin] — no other code changes required.
final class CampaignCache implements ICampaignCache {
  final Map<String, SelfHandledCampaignData> _store = {};

  @override
  void put(String campaignId, SelfHandledCampaignData data) =>
      _store[campaignId] = data;

  @override
  SelfHandledCampaignData? get(String campaignId) => _store[campaignId];

  @override
  void remove(String campaignId) => _store.remove(campaignId);

  @override
  void clear() => _store.clear();

  @override
  int get count => _store.length;

  @override
  List<String> get campaignIds => List.unmodifiable(_store.keys);
}
