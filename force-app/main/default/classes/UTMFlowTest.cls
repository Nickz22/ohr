@isTest
private class UTMFlowTest {
    
    @isTest
    static void testContactUTMToOpportunity() {
        // Create test Accounts in bulk
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                AccountSource = 'Web',
                Website = 'https://test' + i + '.com'
            ));
        }
        insert testAccounts;
        
        // Create test Contacts without UTM values
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            testContacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                AccountId = testAccounts[i].Id,
                Email = 'test' + i + '@example.com',
                LeadSource = 'Web'
            ));
        }
        insert testContacts;
        
        // Create test Opportunities
        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (Integer i = 0; i < 10; i++) {
            testOpportunities.add(new Opportunity(
                Name = 'Test Opportunity ' + i,
                AccountId = testAccounts[i].Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
        insert testOpportunities;
        
        // Create OpportunityContactRoles
        List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
        for (Integer i = 0; i < 10; i++) {
            ocrs.add(new OpportunityContactRole(
                ContactId = testContacts[i].Id,
                OpportunityId = testOpportunities[i].Id,
                IsPrimary = true,
                Role = 'Decision Maker'
            ));
        }
        insert ocrs;
        
        // Verify Opportunities have no UTM values initially
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([
            SELECT Id, utm_campaign__c, utm_content__c, utm_medium__c, utm_source__c, utm_term__c 
            FROM Opportunity 
            WHERE Id IN :testOpportunities
        ]);
        
        for (Opportunity opp : opportunityMap.values()) {
            System.assertEquals(null, opp.utm_campaign__c, 'Opportunity should not have utm_campaign__c value initially');
            System.assertEquals(null, opp.utm_content__c, 'Opportunity should not have utm_content__c value initially');
            System.assertEquals(null, opp.utm_medium__c, 'Opportunity should not have utm_medium__c value initially');
            System.assertEquals(null, opp.utm_source__c, 'Opportunity should not have utm_source__c value initially');
            System.assertEquals(null, opp.utm_term__c, 'Opportunity should not have utm_term__c value initially');
        }
        
        // Add UTM values to Contacts
        for (Integer i = 0; i < 10; i++) {
            testContacts[i].last_utm_campaign__c = 'test-campaign-' + i;
            testContacts[i].last_utm_content__c = 'test-content-' + i;
            testContacts[i].last_utm_medium__c = 'test-medium-' + i;
            testContacts[i].last_utm_source__c = 'test-source-' + i;
            testContacts[i].last_utm_term__c = 'test-term-' + i;
        }
        
        Test.startTest();
        update testContacts;
        Test.stopTest();
        
        // Verify UTM values are copied to Opportunities
        Map<Id, Opportunity> updatedOpportunityMap = new Map<Id, Opportunity>([
            SELECT Id, utm_campaign__c, utm_content__c, utm_medium__c, utm_source__c, utm_term__c 
            FROM Opportunity 
            WHERE Id IN :testOpportunities
        ]);
        
        for (Integer i = 0; i < 10; i++) {
            Opportunity opp = updatedOpportunityMap.get(testOpportunities[i].Id);
            String expectedUtmCampaign = 'test-campaign-' + i;
            String expectedUtmContent = 'test-content-' + i;
            String expectedUtmMedium = 'test-medium-' + i;
            String expectedUtmSource = 'test-source-' + i;
            String expectedUtmTerm = 'test-term-' + i;
            
            System.assertEquals(expectedUtmCampaign, opp.utm_campaign__c, 'Opportunity utm_campaign__c should match Contact value');
            System.assertEquals(expectedUtmContent, opp.utm_content__c, 'Opportunity utm_content__c should match Contact value');
            System.assertEquals(expectedUtmMedium, opp.utm_medium__c, 'Opportunity utm_medium__c should match Contact value');
            System.assertEquals(expectedUtmSource, opp.utm_source__c, 'Opportunity utm_source__c should match Contact value');
            System.assertEquals(expectedUtmTerm, opp.utm_term__c, 'Opportunity utm_term__c should match Contact value');
        }
    }
    
    @isTest
    static void testLeadConversionUTMToOpportunity() {
        // Create test Lead with UTM values
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'lead@example.com',
            Website = 'https://testlead.com',
            utm_campaign__c = 'lead-campaign',
            utm_content__c = 'lead-content',
            utm_medium__c = 'lead-medium',
            utm_source__c = 'lead-source',
            utm_term__c = 'lead-term',
            LeadSource = 'Web'
        );
        insert testLead;
        
        // Convert Lead
        Test.startTest();
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setConvertedStatus('Qualified');
        lc.setDoNotCreateOpportunity(false);
        lc.setOpportunityName('Test Converted Opportunity');
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Test.stopTest();
        
        System.assert(lcr.isSuccess(), 'Lead conversion failed: ' + lcr.getErrors());
        
        // Get the converted Opportunity and add required fields for validation
        Opportunity convertedOpportunity = [SELECT Id, AccountId, utm_campaign__c, utm_content__c, utm_medium__c, utm_source__c, utm_term__c FROM Opportunity WHERE Id = :lcr.getOpportunityId()];
        
        // Verify UTM values were copied from Lead to Opportunity
        System.assertEquals('lead-campaign', convertedOpportunity.utm_campaign__c, 'Opportunity utm_campaign__c should match Lead value');
        System.assertEquals('lead-content', convertedOpportunity.utm_content__c, 'Opportunity utm_content__c should match Lead value');
        System.assertEquals('lead-medium', convertedOpportunity.utm_medium__c, 'Opportunity utm_medium__c should match Lead value');
        System.assertEquals('lead-source', convertedOpportunity.utm_source__c, 'Opportunity utm_source__c should match Lead value');
        System.assertEquals('lead-term', convertedOpportunity.utm_term__c, 'Opportunity utm_term__c should match Lead value');
        
        // Verify Contact received UTM values as well
        Contact convertedContact = [SELECT Id, utm_campaign__c, utm_content__c, utm_medium__c, utm_source__c, utm_term__c FROM Contact WHERE Id = :lcr.getContactId()];
        System.assertEquals('lead-campaign', convertedContact.utm_campaign__c, 'Contact utm_campaign__c should match Lead value');
        System.assertEquals('lead-content', convertedContact.utm_content__c, 'Contact utm_content__c should match Lead value');
        System.assertEquals('lead-medium', convertedContact.utm_medium__c, 'Contact utm_medium__c should match Lead value');
        System.assertEquals('lead-source', convertedContact.utm_source__c, 'Contact utm_source__c should match Lead value');
        System.assertEquals('lead-term', convertedContact.utm_term__c, 'Contact utm_term__c should match Lead value');
    }
} 