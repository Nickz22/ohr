public class CustomerReferenceRequestTriggerHandler {
    public static void handleAfterUpdate(List<Customer_Reference_Requests__c> newRecords, Map<Id, Customer_Reference_Requests__c> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        for(Customer_Reference_Requests__c ref : newRecords) {
            Customer_Reference_Requests__c oldRef = oldMap.get(ref.Id);
            if(ref.Request_Status__c == 'Completed' && oldRef.Request_Status__c != 'Completed') {
                accountIds.add(ref.Account__c);
            }
        }
        
        if(!accountIds.isEmpty()) {
            List<Account> accountsToUpdate = new List<Account>();
            for(Id accId : accountIds) {
                accountsToUpdate.add(new Account(
                    Id = accId,
                    Last_Reference_Date__c = Date.today()
                ));
            }
            update accountsToUpdate;
        }
    }
} 