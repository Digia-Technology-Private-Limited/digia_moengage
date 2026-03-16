export interface MoEngageSelfHandledData {
    campaign: {
        /** Marketer-authored JSON string from the MoEngage dashboard. */
        payload: string;
    };
    campaignData: MoEngageCampaignData;
}

export interface MoEngageCampaignData {
    campaignId: string;
    campaignName: string;
}
