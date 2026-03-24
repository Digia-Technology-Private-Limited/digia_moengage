import DigiaEngage
import MoEngageInApp
import os.log

/// Digia CEP plugin for MoEngage (iOS).
///
/// Bridges MoEngage's Self-Handled In-App campaign system into Digia's
/// rendering engine.
///
/// ## Usage
/// ```swift
/// // AppDelegate / SwiftUI App init
/// MoEngage.sharedInstance.initializeDefault(with: config, in: application, withLaunchOptions: launchOptions)
///
/// Digia.initialize(config: DigiaConfig(apiKey: "prod_xxxx"))
/// Digia.register(MoEngagePlugin())
/// ```
///
/// ## SOLID design
/// - **SRP** — mapping, caching, and event dispatch each live in their own type.
/// - **OCP** — inject custom `ICampaignCache` / `ICampaignPayloadMapper` without
///   modifying this class.
/// - **DIP** — depends on the `ICampaignCache` and `ICampaignPayloadMapper`
///   abstractions, not their concrete implementations.
@MainActor
public final class MoEngagePlugin: DigiaCEPPlugin {

    // MARK: - Public

    public let identifier = "moengage"

    // MARK: - Private

    private let cache: ICampaignCache
    private let mapper: ICampaignPayloadMapper
    private let dispatcher: MoEngageEventDispatcher
    private weak var delegate: DigiaCEPDelegate?

    private let logger = Logger(subsystem: "com.digia.moengage", category: "MoEngagePlugin")

    // MARK: - Init

    /// Creates a `MoEngagePlugin`.
    ///
    /// `cache` and `mapper` are optional — default implementations are used when
    /// omitted. Provide custom implementations for testing or alternative strategies.
    public init(
        cache: ICampaignCache = CampaignCache(),
        mapper: ICampaignPayloadMapper = CampaignPayloadMapper()
    ) {
        self.cache = cache
        self.mapper = mapper
        self.dispatcher = MoEngageEventDispatcher(cache: cache)
    }

    // MARK: - DigiaCEPPlugin

    public func setup(delegate: DigiaCEPDelegate) {
        self.delegate = delegate
        MoEngageInApp.sharedInstance.setInAppDelegate(self)
        MoEngageInApp.sharedInstance.getSelfHandledInApp(withCompletionBlock: { [weak self] campaign, _ in
            guard let self, let campaign else { return }
            self.handleSelfHandledCampaign(campaign)
        })
        logger.info("\(self.identifier): setup complete — listening for self-handled in-app campaigns")
    }

    public func forwardScreen(_ name: String) {
        MoEngageInApp.sharedInstance.setCurrentInAppContexts([name])
        MoEngageInApp.sharedInstance.getSelfHandledInApp(withCompletionBlock: { [weak self] campaign, _ in
            guard let self, let campaign else { return }
            self.handleSelfHandledCampaign(campaign)
        })
        logger.info("\(self.identifier): forwardScreen → \(name)")
    }

    public func notifyEvent(_ event: DigiaExperienceEvent, payload: InAppPayload) {
        guard let campaignId = payload.cepContext["campaignId"] else {
            logger.warning("\(self.identifier): notifyEvent — missing campaignId in cepContext")
            return
        }
        dispatcher.dispatch(event, campaignId: campaignId)
    }

    public func teardown() {
        delegate = nil
        cache.clear()
        logger.info("\(self.identifier): teardown complete")
    }

    public func healthCheck() -> DiagnosticReport {
        guard delegate != nil else {
            return DiagnosticReport(
                isHealthy: false,
                issue: "Plugin has no delegate — setup() has not been called.",
                resolution: "Call Digia.register(MoEngagePlugin()) before using the SDK."
            )
        }
        return DiagnosticReport(
            isHealthy: true,
            metadata: [
                "identifier":       identifier,
                "delegateSet":      "true",
                "cachedCampaigns":  "\(cache.count)",
                "cachedCampaignIds": cache.campaignIds.joined(separator: ","),
            ]
        )
    }

    // MARK: - Private helpers

    private func handleSelfHandledCampaign(_ campaign: InAppSelfHandledCampaign) {
        let payload = mapper.map(campaign)
        cache.put(campaignId: payload.id, data: campaign)
        logger.info("\(self.identifier): campaign ready — id=\(payload.id)")
        delegate?.onCampaignTriggered(payload)
    }
}

// MARK: - MoEngageInAppDelegate

extension MoEngagePlugin: MoEngageInAppDelegate {
    public func inAppShownWithCampaignInfo(_ inAppInfo: MoEngageInAppCampaignInfo) {}
    public func inAppDismissedWithCampaignInfo(_ inAppInfo: MoEngageInAppCampaignInfo) {}
    public func inAppClickedWithCampaignInfo(
        _ inAppInfo: MoEngageInAppCampaignInfo,
        andWidgetInfo widgetInfo: MoEngageWidgetInfo,
        andNavigationActionInfo actionInfo: MoEngageInAppNavigationInfo
    ) {}

    public func selfHandledWithCampaignInfo(
        _ inAppInfo: MoEngageInAppCampaignInfo,
        andSelfHandledCampaignInfo campaignInfo: InAppSelfHandledCampaign
    ) {
        handleSelfHandledCampaign(campaignInfo)
    }

    public func inAppCustomActionClickedWithCampaignInfo(
        _ inAppInfo: MoEngageInAppCampaignInfo,
        andWidgetInfo widgetInfo: MoEngageWidgetInfo,
        andCustomActionInfo actionInfo: MoEngageInAppCustomActionInfo
    ) {}
}
