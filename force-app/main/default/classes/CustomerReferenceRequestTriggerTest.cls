@isTest
public class CustomerReferenceRequestTriggerTest {
    @isTest
    static void testCompletedReference() {
        Account acc = new Account(
            Name = 'Test Account',
            AccountSource = 'Web',
            Website = 'https://test.com'
        );
        insert acc;
        
        Customer_Reference_Requests__c ref = new Customer_Reference_Requests__c(
            Account__c = acc.Id,
            Request_Status__c = 'Initial Request'
        );
        insert ref;
        
        Test.startTest();
        ref.Request_Status__c = 'Completed';
        update ref;
        Test.stopTest();
        
        Account updatedAcc = [SELECT Last_Reference_Date__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(Date.today(), updatedAcc.Last_Reference_Date__c, 'Last Reference Date should be updated to today');
    }
    
    @isTest
    static void testNonCompletedReference() {
        Account acc = new Account(
            Name = 'Test Account',
            AccountSource = 'Web',
            Website = 'https://test.com'
        );
        insert acc;
        
        Customer_Reference_Requests__c ref = new Customer_Reference_Requests__c(
            Account__c = acc.Id,
            Request_Status__c = 'Initial Request'
        );
        insert ref;
        
        Test.startTest();
        ref.Request_Status__c = 'Awaiting References';
        update ref;
        Test.stopTest();
        
        Account updatedAcc = [SELECT Last_Reference_Date__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(null, updatedAcc.Last_Reference_Date__c, 'Last Reference Date should remain null');
    }

    @isTest
    static void testMultipleCompletedReferences() {
        Account acc = new Account(
            Name = 'Test Account',
            AccountSource = 'Web',
            Website = 'https://test.com'
        );
        insert acc;
        
        Customer_Reference_Requests__c ref1 = new Customer_Reference_Requests__c(
            Account__c = acc.Id,
            Request_Status__c = 'Initial Request'
        );
        insert ref1;
        
        Customer_Reference_Requests__c ref2 = new Customer_Reference_Requests__c(
            Account__c = acc.Id,
            Request_Status__c = 'Initial Request'
        );
        insert ref2;
        
        Test.startTest();
        ref1.Request_Status__c = 'Completed';
        update ref1;
        
        Account firstUpdate = [SELECT Last_Reference_Date__c FROM Account WHERE Id = :acc.Id];
        Date firstReferenceDate = firstUpdate.Last_Reference_Date__c;
        System.assertEquals(Date.today(), firstReferenceDate, 'Last Reference Date should be updated after first completion');
        
        ref2.Request_Status__c = 'Completed';
        update ref2;
        Test.stopTest();
        
        Account secondUpdate = [SELECT Last_Reference_Date__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(Date.today(), secondUpdate.Last_Reference_Date__c, 'Last Reference Date should be updated after second completion');
        System.assertEquals(firstReferenceDate, secondUpdate.Last_Reference_Date__c, 'Both reference dates should be the same since they were completed on the same day');
    }
} 