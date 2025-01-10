trigger CustomerReferenceRequestTrigger on Customer_Reference_Requests__c (after update) {
    CustomerReferenceRequestTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
} 