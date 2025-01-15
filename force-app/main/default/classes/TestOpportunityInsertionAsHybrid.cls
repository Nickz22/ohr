@isTest
public with sharing class TestOpportunityInsertionAsHybrid {
    @isTest static void testLogAllTypesOfOpps() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Hybrid AE_AM' LIMIT 1];
        User u = new User(
            ProfileId=p.Id,
            Username='hybridtester'+DateTime.now().millisecond()+'@example.com',
            Email='hybridtester'+DateTime.now().millisecond()+'@example.com',
            LastName='Tester',
            TimeZoneSidKey='America/Los_Angeles',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            Alias='hybr'
        );
        insert u;
        
        System.runAs(u) {
            List<RecordType> rts = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType='Opportunity' AND IsActive=true];
            System.debug('PARSE_DEBUG_START');
            System.debug('Found record types: ' + rts);
            for(RecordType rt : rts) {
                System.debug('Record type: ' + rt.DeveloperName);
            }
            System.debug('PARSE_DEBUG_END');
            
            List<Opportunity> opps = new List<Opportunity>();
            for(RecordType rt : rts) {
                Decimal amount = rt.DeveloperName == 'Churn_Contraction_Risk' ? -1000 : 1000;
                String useCase;
                if(rt.DeveloperName == 'Expansion_Upsell') {
                    useCase = 'Entity Closure';
                } else if(rt.DeveloperName == 'Churn_Contraction_Risk') {
                    useCase = 'Contractor Conversion';
                } else {
                    useCase = 'Edge cases';
                }
                
                opps.add(new Opportunity(
                    Name='Test '+rt.DeveloperName, 
                    CloseDate=Date.today().addDays(10), 
                    StageName='Prospecting', 
                    RecordTypeId=rt.Id,
                    Use_Case__c=useCase,
                    Amount=amount//,
                    // Pricebook2Id=rt.DeveloperName == 'Churn_Contraction_Risk' ? negativePricebook.Id : standardPricebookId
                ));
            }
            
            Test.startTest();
            Database.SaveResult[] results = Database.insert(opps, false);
            System.debug('PARSE_DEBUG_START');
            for(Integer i = 0; i < results.size(); i++) {
                Database.SaveResult sr = results[i];
                if(!sr.isSuccess()) {
                    System.debug('Failed to insert opportunity for record type: ' + rts[i].DeveloperName);
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error: ' + err.getMessage());
                        System.debug('Fields: ' + err.getFields());
                    }
                }
            }
            System.debug('PARSE_DEBUG_END');

            Test.stopTest();
            
            List<Opportunity> insertedOpps = [SELECT Id, RecordType.DeveloperName FROM Opportunity WHERE Id IN :opps];
            System.assertEquals(rts.size(), insertedOpps.size(), 'All opportunities should be created. Expected: ' + rts.size() + ', Actual: ' + insertedOpps.size());
        
        }
    }
}