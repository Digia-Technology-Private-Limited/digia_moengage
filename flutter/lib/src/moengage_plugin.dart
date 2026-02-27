import 'dart:convert';

import 'package:digia_ui/api/interfaces/digia_cep_delegate.dart';
import 'package:digia_ui/api/interfaces/digia_cep_plugin.dart';
import 'package:digia_ui/api/models/digia_experience_event.dart';
import 'package:digia_ui/api/models/in_app_payload.dart';
import 'package:moengage_flutter/moengage_flutter.dart' hide Logger;

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
/// The plugin registers for MoEngage's self-handled in-app callback via
/// [MoEngageFlutter.setSelfHandledInAppHandler]. When MoEngage fires a
/// campaign, the plugin translates the [SelfHandledCampaignData] into a
/// Digia [InAppPayload] and notifies the [DigiaCEPDelegate].
///
/// Lifecycle events from [DigiaHost] are forwarded back to MoEngage via
/// [MoEngageFlutter.selfHandledShown], [MoEngageFlutter.selfHandledClicked],
/// and [MoEngageFlutter.selfHandledDismissed].
class MoEngagePlugin implements DigiaCEPPlugin {
  final MoEngageFlutter _moEngage;

  DigiaCEPDelegate? _delegate;

  // Keyed by campaign ID. Stored so notifyEvent() can call MoEngage
  // lifecycle APIs with the correct SelfHandledCampaignData reference.
  final Map<String, SelfHandledCampaignData> _campaignCache = {};

  /// Creates a [MoEngagePlugin] wrapping an existing [MoEngageFlutter] instance.
  ///
  /// The [instance] must already have been initialised via
  /// [MoEngageFlutter.initialise] before being passed here.
  MoEngagePlugin({required MoEngageFlutter instance}) : _moEngage = instance;

  // ─── DigiaCEPPlugin ────────────────────────────────────────────────────────

  @override
  String get identifier => 'moengage';

  @override
  void setup(DigiaCEPDelegate delegate) {
    _delegate = delegate;

    // Register for MoEngage self-handled in-app callbacks.
    _moEngage.setSelfHandledInAppHandler(_onSelfHandledInApp);
  }

  @override
  void forwardScreen(String name) {
    // MoEngage uses setCurrentContext to associate the user with a screen
    // context for in-app campaign targeting.
    _moEngage.setCurrentContext([name]);
  }

  @override
  void notifyEvent(DigiaExperienceEvent event, InAppPayload payload) {
    final campaignId = payload.cepContext['campaignId'] as String?;
    if (campaignId == null) {
      return;
    }

    final data = _campaignCache[campaignId];
    if (data == null) {
      return;
    }

    switch (event) {
      case ExperienceImpressed():
        _moEngage.selfHandledShown(data);

      case ExperienceClicked():
        _moEngage.selfHandledClicked(data);

      case ExperienceDismissed():
        _moEngage.selfHandledDismissed(data);
        // Remove from cache once dismissed — campaign lifecycle is complete.
        _campaignCache.remove(campaignId);
    }
  }

  @override
  void teardown() {
    // Deregister callbacks to prevent dangling calls after plugin replacement.
    _moEngage.setSelfHandledInAppHandler(null);
    _delegate = null;
    _campaignCache.clear();
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  /// Called by MoEngage when a self-handled in-app campaign is ready.
  void _onSelfHandledInApp(SelfHandledCampaignData? data) {
    if (data == null) {
      return;
    }

    final payload = _mapToInAppPayload(data);

    // Cache for lifecycle event correlation in notifyEvent().
    _campaignCache[payload.id] = data;

    _delegate?.onExperienceReady(payload);
  }

  /// Translates a MoEngage [SelfHandledCampaignData] to a Digia [InAppPayload].
  ///
  /// - [InAppPayload.id] — MoEngage campaign ID.
  /// - [InAppPayload.content] — merged map of campaign metadata plus the
  ///   marketer-configured key-value pairs from [SelfHandledCampaign.payload].
  /// - [InAppPayload.cepContext] — identifiers needed to look up the cached
  ///   [SelfHandledCampaignData] in [notifyEvent].
  InAppPayload _mapToInAppPayload(SelfHandledCampaignData data) {
    final campaignId = data.campaignData.campaignId;
    final campaignName = data.campaignData.campaignName;

    return InAppPayload(
      id: campaignId,
      content: _extractContent(data),
      cepContext: {'campaignId': campaignId, 'campaignName': campaignName},
    );
  }

  /// Extracts the renderable content map from [SelfHandledCampaignData].
  ///
  /// [SelfHandledCampaign.payload] is a raw JSON string set by the marketer
  /// in the MoEngage dashboard. It is parsed and merged with campaign
  /// metadata so consumers have everything in one flat map.
  Map<String, dynamic> _extractContent(SelfHandledCampaignData data) {
    Map<String, dynamic> payloadMap = {};
    try {
      final decoded = jsonDecode(data.campaign.payload);
      if (decoded is Map<String, dynamic>) {
        payloadMap = decoded;
      }
    } catch (e) {
      // If parsing fails, we can still provide campaign metadata in the content.
    }

    return <String, dynamic>{
      'campaignId': data.campaignData.campaignId,
      'campaignName': data.campaignData.campaignName,
      ...payloadMap,
    };
  }
}
