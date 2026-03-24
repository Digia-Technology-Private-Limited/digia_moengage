import DigiaEngage
import Foundation
import MoEngageInApps

/// Default implementation of `ICampaignPayloadMapper`.
///
/// Translates an `InAppSelfHandledCampaign` into a Digia `InAppPayload` by:
/// - parsing the marketer-authored JSON from the campaign's self-handled content,
/// - merging it with campaign metadata (ID + name), and
/// - writing the identifiers needed for lifecycle correlation into `InAppPayload.cepContext`.
///
/// Parsing failures are gracefully degraded — an empty content map is used
/// so the campaign still reaches the rendering engine.
public struct CampaignPayloadMapper: ICampaignPayloadMapper {
    public init() {}

    public func map(_ campaign: MoEngageInAppSelfHandledCampaign) -> InAppPayload {
        let campaignId   = campaign.campaignId
        let campaignName = campaign.campaignName

        let content = buildContent(from: campaign)

        return InAppPayload(
            id: campaignId,
            content: content,
            cepContext: [
                "campaignId":   campaignId,
                "campaignName": campaignName,
            ]
        )
    }

    // MARK: - Private

    private func buildContent(from campaign: MoEngageInAppSelfHandledCampaign) -> InAppPayloadContent {
        let campaignId   = campaign.campaignId
        let campaignName = campaign.campaignName

        // The marketer-authored payload JSON lives in the self-handled content string.
        var payloadMap: [String: JSONValue] = [:]
      let jsonString = campaign.campaignContent
          if let data = jsonString.data(using: .utf8) {
            do {
                if let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    for (key, value) in decoded {
                        payloadMap[key] = jsonValueFrom(any: value)
                    }
                }
            } catch {
                // Graceful degradation — render with metadata only.
            }
        }

        // Extract only the Digia-structural fields; everything else goes into args.
        let type         = stringValue(payloadMap["type"]) ?? "inapp"
        let placementKey = stringValue(payloadMap["placementKey"])
        let viewId       = stringValue(payloadMap["viewId"])
        let command      = stringValue(payloadMap["command"])

        // Strip structural keys; everything else (including all marketer content) goes into args.
        let reservedKeys: Set<String> = ["type", "placementKey", "viewId", "command"]
        var args = payloadMap.filter { !reservedKeys.contains($0.key) }
        args["campaignId"]   = .string(campaignId)
        args["campaignName"] = .string(campaignName)

        return InAppPayloadContent(
            type:         type,
            placementKey: placementKey,
            viewId:       viewId,
            command:      command,
            args:         args
        )
    }

    private func stringValue(_ value: JSONValue?) -> String? {
        guard case .string(let s) = value else { return nil }
        return s
    }

    /// Converts an `Any` value (from `JSONSerialization`) to `JSONValue`.
    private func jsonValueFrom(any value: Any) -> JSONValue {
        switch value {
        case let s as String:
            return .string(s)
        case let b as Bool:
            return .bool(b)
        case let i as Int:
            return .int(i)
        case let d as Double:
            return .double(d)
        case let arr as [Any]:
            return .array(arr.map { jsonValueFrom(any: $0) })
        case let obj as [String: Any]:
            return .object(obj.mapValues { jsonValueFrom(any: $0) })
        default:
            return .null
        }
    }
}
