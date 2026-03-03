package com.digia.moengage

import android.content.Context
import android.util.Log
import com.digia.engage.DigiaCEPDelegate
import com.digia.moengage.cache.CampaignCache
import com.digia.moengage.cache.ICampaignCache
import com.digia.moengage.mapper.CampaignPayloadMapper
import com.digia.moengage.mapper.ICampaignPayloadMapper
import com.moengage.inapp.listeners.SelfHandledAvailableListener
import com.moengage.inapp.model.SelfHandledCampaignData

class MoEngageSelfHandledDataListener(
    private val cache: ICampaignCache,
    private val mapper: ICampaignPayloadMapper,
    private var delegate: DigiaCEPDelegate?,
    private val tag : String,
) : SelfHandledAvailableListener {


    override fun onSelfHandledAvailable(data: SelfHandledCampaignData?) {
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