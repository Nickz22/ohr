@isTest
public class CampaignInfluenceEqualSplitTest {
    @isTest
    static void testEqualSplitOnInsert() {
        Account testAccount = new Account(Name = 'Test Account', AccountSource = 'Test Source', Website = 'www.test.com');
        insert testAccount;
        System.debug('PARSE_DEBUG_START Account created with Id: ' + testAccount.Id + ' PARSE_DEBUG_END');
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            LeadSource = 'Paid Search'
        );
        insert testContact;
        System.debug('PARSE_DEBUG_START Contact created with Id: ' + testContact.Id + ' PARSE_DEBUG_END');
        
        Campaign campaign1 = new Campaign(
            Name = 'Test Campaign 1',
            IsActive = true
        );
        insert campaign1;
        
        Campaign campaign2 = new Campaign(
            Name = 'Test Campaign 2',
            IsActive = true
        );
        insert campaign2;
        
        Campaign campaign3 = new Campaign(
            Name = 'Test Campaign 3',
            IsActive = true
        );
        insert campaign3;
        System.debug('PARSE_DEBUG_START Campaigns created with Ids: ' + campaign1.Id + ', ' + campaign2.Id + ', ' + campaign3.Id + ' PARSE_DEBUG_END');
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            Amount = 10000,
            LeadSource = 'Paid Search'
        );
        insert testOpportunity;
        System.debug('PARSE_DEBUG_START Opportunity created with Id: ' + testOpportunity.Id + ' PARSE_DEBUG_END');
        
        OpportunityContactRole ocr = new OpportunityContactRole(
            ContactId = testContact.Id,
            OpportunityId = testOpportunity.Id,
            Role = 'Decision Maker',
            IsPrimary = true
        );
        insert ocr;
        System.debug('PARSE_DEBUG_START OpportunityContactRole created with Id: ' + ocr.Id + ' PARSE_DEBUG_END');
        
        CampaignInfluenceModel model = [SELECT Id FROM CampaignInfluenceModel LIMIT 1];
        System.debug('PARSE_DEBUG_START Using CampaignInfluenceModel with Id: ' + model.Id + ' PARSE_DEBUG_END');
        
        Test.startTest();
        
        CampaignInfluence ci1 = new CampaignInfluence(
            CampaignId = campaign1.Id,
            OpportunityId = testOpportunity.Id,
            ModelId = model.Id,
            Influence = 100
        );
        insert ci1;
        System.debug('PARSE_DEBUG_START CampaignInfluence 1 created with Id: ' + ci1.Id + ' PARSE_DEBUG_END');
        
        CampaignInfluence ci2 = new CampaignInfluence(
            CampaignId = campaign2.Id,
            OpportunityId = testOpportunity.Id,
            ModelId = model.Id,
            Influence = 100
        );
        insert ci2;
        System.debug('PARSE_DEBUG_START CampaignInfluence 2 created with Id: ' + ci2.Id + ' PARSE_DEBUG_END');
        
        CampaignInfluence ci3 = new CampaignInfluence(
            CampaignId = campaign3.Id,
            OpportunityId = testOpportunity.Id,
            ModelId = model.Id,
            Influence = 100
        );
        insert ci3;
        System.debug('PARSE_DEBUG_START CampaignInfluence 3 created with Id: ' + ci3.Id + ' PARSE_DEBUG_END');
        
        Test.stopTest();
        
        List<CampaignInfluence> updatedCIs = [
            SELECT Id, Influence 
            FROM CampaignInfluence 
            WHERE OpportunityId = :testOpportunity.Id
        ];
        
        System.debug('PARSE_DEBUG_START Found ' + updatedCIs.size() + ' CampaignInfluence records PARSE_DEBUG_END');
        for (CampaignInfluence ci : updatedCIs) {
            System.debug('PARSE_DEBUG_START CampaignInfluence Id: ' + ci.Id + ' has Influence: ' + ci.Influence + ' PARSE_DEBUG_END');
        }
        
        System.assertEquals(3, updatedCIs.size(), 'There should be 3 Campaign Influence records');
        
        for (CampaignInfluence ci : updatedCIs) {
            System.assertEquals(33.33, ci.Influence.setScale(2), 'Each Campaign Influence should have 33.33% attribution');
        }
    }
    
    @isTest
    static void testSingleCampaignInfluence() {
        Account testAccount = new Account(Name = 'Test Account', AccountSource = 'Test Source', Website = 'www.test.com');
        insert testAccount;
        System.debug('PARSE_DEBUG_START Account created with Id: ' + testAccount.Id + ' PARSE_DEBUG_END');
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            LeadSource = 'Paid Search'
        );
        insert testContact;
        System.debug('PARSE_DEBUG_START Contact created with Id: ' + testContact.Id + ' PARSE_DEBUG_END');
        
        Campaign campaign = new Campaign(
            Name = 'Test Campaign',
            IsActive = true
        );
        insert campaign;
        System.debug('PARSE_DEBUG_START Campaign created with Id: ' + campaign.Id + ' PARSE_DEBUG_END');
        
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            Amount = 10000,
            LeadSource = 'Paid Search'
        );
        insert testOpportunity;
        System.debug('PARSE_DEBUG_START Opportunity created with Id: ' + testOpportunity.Id + ' PARSE_DEBUG_END');
        
        OpportunityContactRole ocr = new OpportunityContactRole(
            ContactId = testContact.Id,
            OpportunityId = testOpportunity.Id,
            Role = 'Decision Maker',
            IsPrimary = true
        );
        insert ocr;
        System.debug('PARSE_DEBUG_START OpportunityContactRole created with Id: ' + ocr.Id + ' PARSE_DEBUG_END');
        
        CampaignInfluenceModel model = [SELECT Id FROM CampaignInfluenceModel LIMIT 1];
        System.debug('PARSE_DEBUG_START Using CampaignInfluenceModel with Id: ' + model.Id + ' PARSE_DEBUG_END');
        
        Test.startTest();
        
        CampaignInfluence ci = new CampaignInfluence(
            CampaignId = campaign.Id,
            OpportunityId = testOpportunity.Id,
            ModelId = model.Id,
            Influence = 50
        );
        insert ci;
        System.debug('PARSE_DEBUG_START CampaignInfluence created with Id: ' + ci.Id + ' PARSE_DEBUG_END');
        
        Test.stopTest();
        
        CampaignInfluence updatedCI = [
            SELECT Id, Influence 
            FROM CampaignInfluence 
            WHERE OpportunityId = :testOpportunity.Id
        ];
        
        System.debug('PARSE_DEBUG_START CampaignInfluence Id: ' + updatedCI.Id + ' has Influence: ' + updatedCI.Influence + ' PARSE_DEBUG_END');
        
        System.assertEquals(100, updatedCI.Influence, 'Single Campaign Influence should have 100% attribution');
    }
}