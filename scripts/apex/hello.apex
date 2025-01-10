List<Account> accounts = new List<Account>();
List<Customer_Reference_Requests__c> requests = new List<Customer_Reference_Requests__c>();

for(Integer i = 0; i < 10; i++) {
    accounts.add(new Account(
        Name = 'Test Account ' + i,
        AccountSource = 'Web',
        Website = 'https://test' + i + '.com'
    ));
}
insert accounts;

for(Account acc : accounts) {
    requests.add(new Customer_Reference_Requests__c(
        Account__c = acc.Id,
        Request_Status__c = 'Initial Request'
    ));
}
insert requests;

System.debug('Created ' + accounts.size() + ' Accounts with Reference Requests');
for(Account acc : [SELECT Id, Name, (SELECT Id, Request_Status__c FROM Customer_Reference_Requests__r) FROM Account WHERE Id IN :accounts]) {
    System.debug('Account: ' + acc.Name + ' has Reference Request: ' + acc.Customer_Reference_Requests__r[0].Id);
}


// Start of Selection
System.debug('Now updating all Reference Requests to Completed...');
List<Account> queriedAccounts = [SELECT Id FROM Account];
List<Customer_Reference_Requests__c> existingRequests = [SELECT Id, Request_Status__c FROM Customer_Reference_Requests__c WHERE Account__c IN :queriedAccounts];
for(Customer_Reference_Requests__c req : existingRequests) {
    req.Request_Status__c = 'Completed';
}
update existingRequests;

List<Account> updatedAccounts = [SELECT Id, Name, Last_Reference_Date__c FROM Account WHERE Id IN :queriedAccounts];
for(Account acc : updatedAccounts) {
    if(acc.Last_Reference_Date__c == Date.today()) {
        System.debug('SUCCESS: Account ' + acc.Name + ' has Last Reference Date updated to today');
    } else {
        System.debug('ERROR: Account ' + acc.Name + ' has incorrect Last Reference Date: ' + acc.Last_Reference_Date__c);
    }
}
