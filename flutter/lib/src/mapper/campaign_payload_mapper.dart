import 'dart:convert';

import 'package:digia_engage/api/models/in_app_payload.dart';
import 'package:moengage_flutter/moengage_flutter.dart';

import 'i_campaign_payload_mapper.dart';

/// Default implementation of [ICampaignPayloadMapper].
///
/// Translates a [SelfHandledCampaignData] into a Digia [InAppPayload] by:
/// - parsing the marketer-authored JSON from [SelfHandledCampaign.payload],
/// - merging it with campaign metadata (ID + name), and
/// - writing the identifiers needed for lifecycle correlation into [InAppPayload.cepContext].
///
/// Parsing failures are gracefully degraded — an empty payload map is used
/// so the campaign still reaches the rendering engine.
final class CampaignPayloadMapper implements ICampaignPayloadMapper {
  const CampaignPayloadMapper();

  @override
  InAppPayload map(SelfHandledCampaignData data) {
    final campaignId = data.campaignData.campaignId;
    final campaignName = data.campaignData.campaignName;

    return InAppPayload(
      id: campaignId,
      content: _buildContent(data),
      cepContext: {
        'campaignId': campaignId,
        'campaignName': campaignName,
      },
    );
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  /// Merges campaign metadata with the raw marketer JSON from the dashboard.
  Map<String, dynamic> _buildContent(SelfHandledCampaignData data) {
    Map<String, dynamic> payloadMap = {};

    try {
      final decoded = jsonDecode(data.campaign.payload);
      if (decoded is Map<String, dynamic>) {
        payloadMap = decoded;
      }
    } catch (e) {
      Logger.w('CampaignPayloadMapper: could not parse campaign payload JSON: $e');
    }

    return <String, dynamic>{
      'campaignId': data.campaignData.campaignId,
      'campaignName': data.campaignData.campaignName,
      ...payloadMap,
    };
  }
}
