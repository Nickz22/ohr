@isTest
public class TestOpportunityRenewalFlow {
    @isTest static void testRenewalOpportunityCreation() {
        System.debug('PARSE_DEBUG_START');
        System.debug('Setting up test data...');
        System.debug('PARSE_DEBUG_END');

        Account testAccount = new Account(
            Name = 'Test Account ZZZ',
            AccountSource = 'Web',
            Website = 'https://test.com'
        );
        insert testAccount;

        System.debug('PARSE_DEBUG_START');
        System.debug('Created test account: ' + testAccount);
        System.debug('PARSE_DEBUG_END');

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            LastName = 'Test Contact',
            Email = 'test@test.com',
            LeadSource = 'Web'
        );
        insert testContact;

        System.debug('PARSE_DEBUG_START');
        System.debug('Created test contact: ' + testContact);
        System.debug('PARSE_DEBUG_END');

        Id pricebookId = Test.getStandardPricebookId();
        Product2 scaleProduct = new Product2(
            Name = 'Oyster Scale',
            IsActive = true
        );
        insert scaleProduct;
        
        System.debug('PARSE_DEBUG_START');
        System.debug('Created product: ' + scaleProduct);
        System.debug('PARSE_DEBUG_END');

        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = scaleProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPrice;

        System.debug('PARSE_DEBUG_START');
        System.debug('Created pricebook entry: ' + standardPrice);
        System.debug('PARSE_DEBUG_END');

        Id initialOpportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Initial_Opportunity').getRecordTypeId();
        
        System.debug('PARSE_DEBUG_START');
        System.debug('Got record type ID: ' + initialOpportunityRecordTypeId);
        System.debug('PARSE_DEBUG_END');

        Opportunity originalOpp = new Opportunity(
            Name = 'Original Opp',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Product_Name__c = 'Oyster Scale',
            Pricebook2Id = pricebookId,
            RecordTypeId = initialOpportunityRecordTypeId,
            Number_of_Seats__c = 5
        );
        insert originalOpp;

        System.debug('PARSE_DEBUG_START');
        System.debug('Created original opportunity: ' + originalOpp);
        System.debug('PARSE_DEBUG_END');

        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = originalOpp.Id,
            ContactId = testContact.Id,
            Role = 'Decision Maker'
        );
        insert ocr;

        System.debug('PARSE_DEBUG_START');
        System.debug('Created opportunity contact role: ' + ocr);
        System.debug('PARSE_DEBUG_END');

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = originalOpp.Id,
            PricebookEntryId = standardPrice.Id,
            Quantity = 5,
            UnitPrice = 100,
            Subscription_Start_Date__c = Date.today(),
            Contract_Term_months__c = 12,
            Billing_Currency__c = 'USD'
        );
        insert oli;

        System.debug('PARSE_DEBUG_START');
        System.debug('Created opportunity line item: ' + oli);
        System.debug('PARSE_DEBUG_END');

        Test.startTest();
        System.debug('PARSE_DEBUG_START');
        System.debug('Updating opportunity to Closed Won...');
        System.debug('Original opportunity before update: ' + [SELECT Id, Name, StageName, Product_Name__c, Number_of_Oyster_Scale_Products__c FROM Opportunity WHERE Id = :originalOpp.Id]);
        System.debug('PARSE_DEBUG_END');

        originalOpp.StageName = 'Closed Won';
        originalOpp.Contact_Roles__c = 1;
        originalOpp.Meeting_Outcome__c = 'Qualified';
        originalOpp.Purchasing_Criteria_1__c = 'Hire';
        originalOpp.Purchasing_Criteria_Details_1__c = 'Speed of hire';
        originalOpp.Won_Reason__c = 'Compliance';
        originalOpp.Use_Case__c = 'Contractor Only';
        originalOpp.Won_Against_Competitor__c = 'No';
        update originalOpp;

        System.debug('PARSE_DEBUG_START');
        System.debug('Updated opportunity: ' + [SELECT Id, Name, StageName, Product_Name__c, Number_of_Oyster_Scale_Products__c FROM Opportunity WHERE Id = :originalOpp.Id]);
        System.debug('PARSE_DEBUG_END');

        Test.stopTest();

        List<Opportunity> renewalOpps = [SELECT Id, Name, StageName, Product_Name__c, Number_of_Oyster_Scale_Products__c FROM Opportunity WHERE AccountId = :testAccount.Id AND Id != :originalOpp.Id];
        System.debug('PARSE_DEBUG_START');
        System.debug('Found renewal opportunities: ' + renewalOpps);
        System.debug('PARSE_DEBUG_END');

        System.assertEquals(1, renewalOpps.size(), 'Expected one renewal opportunity to be created');
        Integer expectedYear = Date.today().addMonths(12).year();
        String expectedName = 'Test Account ZZZ - Oyster Scale Renewal ' + expectedYear + ' - 5 Seats';
        System.assertEquals(expectedName, renewalOpps[0].Name, 'Renewal opportunity name does not match expected format');
    }
}