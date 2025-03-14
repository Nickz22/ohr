/**
    CREATED BY: Eugene Lanets on 13.07.2021.
    AT REQUEST OF: Oyster HR
    DESCRIPTION:
*/
trigger OpportunityTrigger on Opportunity (before update,after update) {

    /*Map<String, String> validationMap = OpportunityHandler.validation(Trigger.new);
    
    

    if(Trigger.isUpdate && Trigger.isBefore){
        for(Opportunity opp : Trigger.new){
            if(opp.Type == 'New Business'){
                if(opp.StageName == 'Verbal Commit' && Trigger.oldMap.get(opp.Id).StageName != 'Verbal Commit'){
                    if(validationMap.containsKey(opp.Id)){
                        opp.addError(validationMap.get(opp.Id));
                    }
                }
            }
        }
    }*/
    
    /*else */
    if(trigger.isAfter){
        
        OpportunityHandler.addContactRoles(trigger.new,trigger.oldmap);
        
    List<Id> discoveryOppIds = new List<Id>();
    if(Trigger.isUpdate && Trigger.isAfter){
        for(Opportunity opp : Trigger.new){
            Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
            if(opp.StageName != oldOpp.StageName && (opp.IsWon || !opp.IsClosed)){
                discoveryOppIds.Add(opp.Id);
            }
        }
    }
    
    if(!discoveryOppIds.isEmpty()){
        List<String> discoveryLifecycleStagesToExclude = new List<String>();
        discoveryLifecycleStagesToExclude.add('customer');
        OpportunityHandler.updateOppContactLifecycleStage(discoveryOppIds, discoveryLifecycleStagesToExclude, 'opportunity');
    }
}
    if(Trigger.isBefore){
        OpportunityHandler.handleBeforeUpdate(trigger.new,trigger.oldmap);
        
    }
}