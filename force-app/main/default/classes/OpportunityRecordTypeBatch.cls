/*This batch is intended to run once daily.
 * It ensures that all opportunities have the correct record type.*/
public class OpportunityRecordTypeBatch implements Database.Batchable<sObject>, Schedulable{
    public Iterable<sObject> start(Database.BatchableContext bc){
        //get accounts that have opportunities
        String query = 'SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity)';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Account> accountsWithOpps){
        List<Id> accountIds = new List<Id>();
        for(Account a : accountsWithOpps){
            accountIds.add(a.Id);
        }
        //get opps related to accounts
        List<Opportunity> accountOpps = [SELECT AccountId, IsClosed, IsWon, CloseDate, RecordTypeId, Do_Not_Auto_Update_Record_Type__c FROM Opportunity WHERE AccountId IN :accountIds 
                                         AND (RecordType.Name = 'New Logo' OR RecordType.Name = 'Expansion')
                                         ORDER BY CloseDate ASC, Deal_Date__c ASC NULLS LAST, CreatedDate ASC];
        if(!accountOpps.isEmpty()){
            //map of account id to a list of their opps
            Map<Id,List<Opportunity>> accountOppMap = new Map<Id,List<Opportunity>>();
            for(Opportunity o : accountOpps){
                List<Opportunity> thisOppList = accountOppMap.containsKey(o.AccountId) ? accountOppMap.get(o.AccountId) : new List<Opportunity>();
                thisOppList.add(o);
                accountOppMap.put(o.AccountId,thisOppList);
            }
            
            Id initialRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Initial_Opportunity').getRecordTypeId();
            Id subsequentRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Expansion_Upsell').getRecordTypeId();
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for(Id accountId : accountOppMap.keySet()){
                List<Opportunity> accountOppList = accountOppMap.get(accountId);
                //if an opportunity has an older closed won opp (by close date), set to Subsequent
                //otherwise, set to Initial
                Boolean foundClosedWonOpp = false;
                for(Opportunity accountOpp : accountOppList){
                    Id currentRecTypeId = accountOpp.RecordTypeId;
                    accountOpp.RecordTypeId = foundClosedWonOpp ? subsequentRecTypeId : initialRecTypeId;
                    if(accountOpp.RecordTypeId != currentRecTypeId && !accountOpp.Do_Not_Auto_Update_Record_Type__c){
                        oppsToUpdate.add(accountOpp);
                    }
                    
                    if(accountOpp.isClosed && accountOpp.isWon){
                        foundClosedWonOpp = true;
                    }
                }
            }
            
            update oppsToUpdate;
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    
    public void execute(SchedulableContext sc){
        Database.executeBatch(this);
    }
}