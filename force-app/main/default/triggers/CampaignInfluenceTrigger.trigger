trigger CampaignInfluenceTrigger on CampaignInfluence (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        Set<Id> opportunityIds = new Set<Id>();
        
        for (CampaignInfluence ci : Trigger.new) {
            opportunityIds.add(ci.OpportunityId);
        }
        
        Map<Id, List<CampaignInfluence>> oppToCampaignInfluences = new Map<Id, List<CampaignInfluence>>();
        
        for (CampaignInfluence ci : [SELECT Id, OpportunityId, ModelId, Influence 
                                     FROM CampaignInfluence 
                                     WHERE OpportunityId IN :opportunityIds]) {
            if (!oppToCampaignInfluences.containsKey(ci.OpportunityId)) {
                oppToCampaignInfluences.put(ci.OpportunityId, new List<CampaignInfluence>());
            }
            oppToCampaignInfluences.get(ci.OpportunityId).add(ci);
        }
        
        List<CampaignInfluence> campaignInfluencesToUpdate = new List<CampaignInfluence>();
        
        for (Id oppId : oppToCampaignInfluences.keySet()) {
            List<CampaignInfluence> ciList = oppToCampaignInfluences.get(oppId);
            Decimal equalSplit = 100.0 / ciList.size();
            
            for (CampaignInfluence ci : ciList) {
                ci.Influence = equalSplit;
                campaignInfluencesToUpdate.add(ci);
            }
        }
        
        if (!campaignInfluencesToUpdate.isEmpty()) {
            update campaignInfluencesToUpdate;
        }
    }
}