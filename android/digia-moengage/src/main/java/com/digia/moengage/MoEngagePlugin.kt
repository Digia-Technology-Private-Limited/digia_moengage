package com.digia.moengage

import android.content.Context
import android.util.Log
import com.digia.engage.DigiaCEPDelegate
import com.digia.engage.DigiaCEPPlugin
import com.digia.engage.DigiaExperienceEvent
import com.digia.engage.DiagnosticReport
import com.digia.engage.InAppPayload
import com.digia.moengage.cache.CampaignCache
import com.digia.moengage.cache.ICampaignCache
import com.digia.moengage.event.MoEngageEventDispatcher
import com.digia.moengage.mapper.CampaignPayloadMapper
import com.digia.moengage.mapper.ICampaignPayloadMapper
import com.moengage.inapp.MoEInAppHelper
import com.moengage.inapp.model.SelfHandledCampaignData

/**
 * Digia CEP plugin for MoEngage Android SDK.
 *
 * Bridges MoEngage's Self-Handled In-App campaign system into
 * Digia's rendering engine.
 *
 * ## Usage
 * ```kotlin
 * // Initialize MoEngage SDK first
 * val moEngage = MoEngage.Builder(this, "YOUR_APP_ID").build()
 * MoEngage.initialise(moEngage)
 *
 * // Register the plugin (pass Application context)
 * Digia.register(MoEngagePlugin(applicationContext))
 * ```
 *
 * ## SOLID design
 * - **SRP**: Each concern lives in its own class —
 *   [ICampaignCache] stores data, [ICampaignPayloadMapper] transforms it,
 *   [MoEngageEventDispatcher] routes events. This class only orchestrates.
 * - **OCP**: Adding a new [DigiaExperienceEvent] requires updating only
 *   [MoEngageEventDispatcher] — this class is closed for modification.
 * - **LSP**: Inject any [ICampaignCache] / [ICampaignPayloadMapper] implementation
 *   without changing behaviour.
 * - **ISP**: Each interface carries exactly the operations its consumers need.
 * - **DIP**: All dependencies are abstractions; concrete classes are provided
 *   by default but can be overridden for testing or alternative strategies.
 *
 * @param context   Application context required by the MoEngage inapp SDK.
 * @param cache     Campaign data cache. Defaults to an in-memory [CampaignCache].
 * @param mapper    Payload mapper. Defaults to [CampaignPayloadMapper].
 */
class MoEngagePlugin(
    private val context: Context,
    private val cache: ICampaignCache = CampaignCache(),
    private val mapper: ICampaignPayloadMapper = CampaignPayloadMapper(),
) : DigiaCEPPlugin {

    private val tag = "DigiaMoEngagePlugin"
    private var delegate: DigiaCEPDelegate? = null
    private val dispatcher = MoEngageEventDispatcher(context = context, cache = cache)

    // --- DigiaCEPPlugin -------------------------------------------------------

    override val identifier: String = "moengage"

    override fun setup(delegate: DigiaCEPDelegate) {
        this.delegate = delegate

        // Ask MoEngage to evaluate and deliver any eligible campaign now.
        // The listener is invoked when a self-handled in-app is available.
        MoEInAppHelper.getInstance().getSelfHandledInApp(context) { data ->
            onSelfHandledInApp(data)
        }

        Log.i(tag, "setup complete — listening for self-handled in-app campaigns")
    }

    override fun forwardScreen(name: String) {
        // MoEngage uses setInAppContext to associate the user with a screen
        // context for in-app campaign targeting.
        MoEInAppHelper.getInstance().setInAppContext(setOf(name))
        Log.i(tag, "forwardScreen: $name")
    }

    override fun notifyEvent(event: DigiaExperienceEvent, payload: InAppPayload) {
        val campaignId = payload.cepContext["campaignId"] as? String
        if (campaignId == null) {
            Log.w(tag, "notifyEvent: missing campaignId in cepContext")
            return
        }
        dispatcher.dispatch(event, campaignId)
    }

    override fun teardown() {
        delegate = null
        cache.clear()
        Log.i(tag, "teardown complete")
    }

    override fun healthCheck(): DiagnosticReport {
        return if (delegate == null) {
            DiagnosticReport(
                isHealthy = false,
                issue = "Plugin has no delegate — setup() has not been called.",
                resolution = "Call Digia.register(MoEngagePlugin(applicationContext)) before using the SDK."
            )
        } else {
            DiagnosticReport(
                isHealthy = true,
                metadata = mapOf(
                    "identifier" to identifier,
                    "delegateSet" to true,
                    "cachedCampaigns" to cache.count,
                    "cachedCampaignIds" to cache.campaignIds
                )
            )
        }
    }

    // --- Private --------------------------------------------------------------

    /**
     * Called by MoEngage when a self-handled in-app campaign is ready.
     */
    private fun onSelfHandledInApp(data: SelfHandledCampaignData?) {
        if (data == null) {
            Log.w(tag, "Received null SelfHandledCampaignData — skipping.")
            return
        }

        val payload = mapper.map(data)
        cache.put(payload.id, data)

        Log.i(tag, "Campaign ready — id=${payload.id}")
        delegate?.onCampaignTriggered(payload)
    }
}