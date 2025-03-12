@isTest 
public with sharing class CampaignInfluenceStandardTest {
    @isTest
    public static void testCampaignInfluence() {
        // Create test data
        Account acc = new Account(Name='Test Account', AccountSource='Test Source', Website='www.test.com');
        insert acc;
        System.debug('PARSE_DEBUG_START Account created with Id: ' + acc.Id + ' PARSE_DEBUG_END');
        
        Contact con = new Contact(FirstName='Test', LastName='Contact', AccountId=acc.Id, LeadSource='Paid Search');
        insert con;
        System.debug('PARSE_DEBUG_START Contact created with Id: ' + con.Id + ' PARSE_DEBUG_END');
        
        // Create multiple campaigns
        Campaign camp1 = new Campaign(Name='Test Campaign 1', IsActive=true);
        Campaign camp2 = new Campaign(Name='Test Campaign 2', IsActive=true);
        Campaign camp3 = new Campaign(Name='Test Campaign 3', IsActive=true);
        insert new List<Campaign>{camp1, camp2, camp3};
        System.debug('PARSE_DEBUG_START Campaigns created with Ids: ' + camp1.Id + ', ' + camp2.Id + ', ' + camp3.Id + ' PARSE_DEBUG_END');
        
        // Create campaign members for the contact with different timestamps
        CampaignMember cm1 = new CampaignMember(CampaignId = camp1.Id, ContactId = con.Id, Status='Responded');
        CampaignMember cm2 = new CampaignMember(CampaignId = camp2.Id, ContactId = con.Id, Status='Responded');
        CampaignMember cm3 = new CampaignMember(CampaignId = camp3.Id, ContactId = con.Id, Status='Responded');
        insert new List<CampaignMember>{cm1, cm2, cm3};
        System.debug('PARSE_DEBUG_START CampaignMembers created with Ids: ' + cm1.Id + ', ' + cm2.Id + ', ' + cm3.Id + ' PARSE_DEBUG_END');
        
        // Set created dates to different times to test influence models
        Test.setCreatedDate(cm1.Id, System.now().addDays(-30)); // First touch
        Test.setCreatedDate(cm2.Id, System.now().addDays(-15)); // Middle touch
        Test.setCreatedDate(cm3.Id, System.now().addDays(-5));  // Last touch
        System.debug('PARSE_DEBUG_START Campaign member dates set: First(-30d), Middle(-15d), Last(-5d) PARSE_DEBUG_END');
        
        // Create opportunity
        Opportunity opp = new Opportunity(
            Name='Test Opportunity', 
            StageName='Prospecting', 
            CloseDate=Date.today().addDays(30), 
            AccountId=acc.Id, 
            LeadSource='Paid Search'
        );
        insert opp;
        System.debug('PARSE_DEBUG_START Opportunity created with Id: ' + opp.Id + ' PARSE_DEBUG_END');
        
        Test.startTest();
        
        // Create contact role to trigger campaign influence
        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = con.Id,
            Role = 'Decision Maker',
            IsPrimary = true
        );
        insert ocr;
        System.debug('PARSE_DEBUG_START OpportunityContactRole created with Id: ' + ocr.Id + ' PARSE_DEBUG_END');
        
        // Give the system time to process the campaign influence
        Test.stopTest();
        
        // Query for campaign influence records that should have been automatically created
        List<CampaignInfluence> ciList = [
            SELECT Id, OpportunityId, CampaignId, Influence, ModelId, Model.DeveloperName
            FROM CampaignInfluence 
            WHERE OpportunityId = :opp.Id
        ];
        
        System.debug('PARSE_DEBUG_START CampaignInfluence record count: ' + ciList.size() + ' PARSE_DEBUG_END');
        
        // Basic assertion to check if Campaign Influence records were created
        System.assert(ciList.size() > 0, 'Expected at least one Campaign Influence record to be created automatically');
        
        // Log details of each campaign influence record for debugging
        for(CampaignInfluence ci : ciList) {
            System.debug('PARSE_DEBUG_START CampaignInfluence: CampaignId=' + ci.CampaignId + 
                         ', Influence=' + ci.Influence + 
                         ', ModelId=' + ci.ModelId + 
                         ', ModelName=' + ci.Model.DeveloperName + ' PARSE_DEBUG_END');
        }
    }
} 

