/**
CREATED BY: Eugene Lanets on 13.07.2021.
AT REQUEST OF: Oyster HR
DESCRIPTION:
*/
public class OpportunityHandler {
    
    /*public static Map<String, String> validation(List<Opportunity> triggerOpps){
String hhoErrorMessage = 'Handover object record must exist. Please create an record to proceed to this stage.';
String cucErrorMessage = 'Handover [Context and Use Case]﻿ field must have a value.';
List<Id> ids = new List<Id>();
for(Opportunity opp :triggerOpps){
ids.add(opp.Id);
}
Map<String, String> validationMap = new Map<String, String>();
List<Opportunity> opps = [SELECT id, Name, StageName, Type, (SELECT id, Context_Use_Case__c, Name FROM Handovers__r) FROM Opportunity WHERE id IN: ids];
for(Opportunity opp: opps){
if(opp.Handovers__r.size() == 0){
validationMap.put(opp.Id, hhoErrorMessage);
}else{
for(Handover__c hh : opp.Handovers__r){
if(hh.Context_Use_Case__c == null){
validationMap.put(opp.Id, cucErrorMessage);
}
}
}
}
return validationMap;
}*/
    
    //looks for related Contact Roles and updates their Lifecycle Stage
    public static void updateOppContactLifecycleStage(List<Id> oppIds, List<String> lifecycleStagesToExclude, String newContactLifecycleStage){
        List<OpportunityContactRole> ocrs = [SELECT OpportunityId, ContactId, Contact.Lifecycle_Stage__c 
                                             FROM OpportunityContactRole
                                             WHERE OpportunityId IN :oppIds AND Contact.Lifecycle_Stage__c NOT IN :lifecycleStagesToExclude];
        if(!ocrs.isEmpty()){
            map<id,Contact> contactsToUpdate = new map<id,Contact>();
            for(OpportunityContactRole ocr : ocrs){
                if(!contactsToUpdate.keyset().contains(ocr.ContactId)){ 
                Contact contactToUpdate = new Contact(
                    Id = ocr.ContactId,
                    Lifecycle_Stage__c = newContactLifecycleStage
                );
                contactsToUpdate.put(ocr.ContactId,contactToUpdate);
            }
            }
             list<Contact> contactsToUpdate1 = new list<Contact>();
            for(id iId: contactsToUpdate.keyset()){
                contactsToUpdate1.add(ContactsToUpdate.get(iId));
                
            }
            update contactsToUpdate1;
            
        }
    }
   public static void handleBeforeUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldmap) {
        List<productSpecialistAlert__e> eventList = new List<productSpecialistAlert__e>();
       
       id initialRecordTypeId=Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('New Logo').getRecordTypeId();
        

        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldmap.get(opp.Id);
            //convert How_Many_TM__c to an integer - if it's "20+", change it to 21
            Integer howManyTmInt = opp.How_many_TM__c == '20+' ? 21 : (opp.How_many_TM__c != null ? Integer.valueOf(opp.How_many_TM__c) : 0);
            if (opp.StageName != null && 
                (oldopp.StageName.equalsIgnoreCase('Prospecting') || oldopp.StageName.equalsIgnoreCase('Discovery'))  &&
                opp.isclosed== false &&
                opp.recordtypeid == initialRecordTypeId&&
                opp.Product_Specialist__c == null && (opp.Owner_Profile__c=='AE User' ||opp.Owner_Profile__c=='PT1')  &&
                opp.How_many_TM__c != null && howManyTmInt > 5 &&
                String.isNotBlank(opp.Region__c) &&
                (opp.StageName != oldOpp.StageName)) {
                
                productSpecialistAlert__e event = new productSpecialistAlert__e();
                eventList.add(event);
                

            }
        }
        
        // Publish platform event
        if (!eventList.isEmpty()) {
            integer x =0;
            x++;
            x++;
            
            List<Database.SaveResult> results = EventBus.publish(eventList);
            for (Database.SaveResult result : results) {
                if (result.isSuccess()) {
                    System.debug('Event published successfully.');
                } else {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error message: ' + error.getMessage());
                    }
                }
            }
        }
    }
    
    public static void addContactRoles(list<opportunity>opplist,map<id,opportunity>oldoppmap){
       trigger_setting__mdt TriggerCheck =[select developername,enabled__c from Trigger_Setting__mdt where developername='OpportunityMEDICUpdates'];
        if(TriggerCheck.enabled__c ==true || Test.isRunningTest()){ 
        list<opportunitycontactrole>ocrlist = new list<opportunitycontactrole>();
        for(opportunity opp: opplist){
            opportunity oldopp = oldoppmap.get(opp.id);
            if(opp.E_Economic_Buyer__c != Null
              &&
               oldopp.E_Economic_Buyer__c ==Null){
                   opportunitycontactrole ocr = new opportunitycontactrole();
                   ocr.contactid=opp.E_economic_buyer__c;
                   ocr.role='Economic Buyer';
                   ocr.OpportunityId=opp.id;
                   ocrlist.add(ocr);
               }
           if(opp.C_Champion__c != Null
              &&
               oldopp.C_Champion__c ==Null){
                   opportunitycontactrole ocr1 = new opportunitycontactrole();
                   ocr1.contactid=opp.c_champion__c;
                   ocr1.role='Champion';
                   ocr1.OpportunityId=opp.id;
                   ocrlist.add(ocr1);
               }
            
        }
        system.debug('this is the ocr list' +ocrlist);
        
        if(ocrlist.size()>0){
            try{database.insert(ocrlist,false) ;
            system.debug('ocr list inserted');
            }
            catch(exception e){
                system.debug('ocrs could not be inserted due to the following reason: '+e);
            }
        }
    }
    }
    
}