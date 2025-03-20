/*This class is intended to be scheduled to run nightly.
 * It calculates the Last Week Win Rate (New Business) and This Month Win Rate (New Business) for all users
 * based on opportunity ownership*/

public class NewBusinessWinRateBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful{
    public List<String> lostReasonsDoNotInclude = new List<String>();
    public Iterable<sObject> start(Database.BatchableContext bc){
        clearAllWinRates();
        lostReasonsDoNotInclude.add('Misqualified');
        lostReasonsDoNotInclude.add('Duplicate Opp');
        lostReasonsDoNotInclude.add('Client Unresponsive');
        lostReasonsDoNotInclude.add('Meeting Never Set');
        lostReasonsDoNotInclude.add('Not a Priority');
        
        String query = 'SELECT OwnerId, IsWon FROM Opportunity WHERE RecordType.Name = \'New Logo\' AND IsClosed = TRUE AND';
        query += ' (CloseDate = LAST_WEEK OR CloseDate = THIS_MONTH)';
        //query += ' Lost_Reason__c NOT IN :lostReasonsDoNotInclude';
        //update 2024-10-29: change "do not include" logic
        query += ' AND Lost_Reason__c EXCLUDES(';
        for(String lostReason : lostReasonsDoNotInclude){
            query += '\'' + lostReason + '\',';
        }
        //remove final comma from string
        query = query.removeEnd(',');
        query +=')';

        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Opportunity> scope){
        //collect owner ids and query all opps that match the criteria for these owners again
        //this will ensure no opps get lost between batches
        Set<Id> ownerIds = new Set<Id>();
        for(Opportunity opp : scope){
            ownerIds.add(opp.OwnerId);
        }
        System.debug('loss reasons: ' + lostReasonsDoNotInclude);
        
        List<Opportunity> lastWeekClosedOpps = [SELECT OwnerId, IsWon FROM Opportunity WHERE RecordType.Name = 'New Logo' AND IsClosed = TRUE AND
                                         		Lost_Reason__c NOT IN :lostReasonsDoNotInclude AND CloseDate = LAST_WEEK AND OwnerId IN :ownerIds];
        List<Opportunity> thisMonthClosedOpps = [SELECT OwnerId, IsWon FROM Opportunity WHERE RecordType.Name = 'New Logo' AND IsClosed = TRUE AND
                                         		Lost_Reason__c NOT IN :lostReasonsDoNotInclude AND CloseDate = THIS_MONTH AND OwnerId IN :ownerIds];
        
        //create 4 maps: ownerid to closed won/lost and this week/month opp list
        Map<Id,List<Opportunity>> lastWeekClosedWonMap = new Map<Id,List<Opportunity>>();
        Map<Id,List<Opportunity>> lastWeekClosedLostMap = new Map<Id,List<Opportunity>>();
        Map<Id,List<Opportunity>> thisMonthClosedWonMap = new Map<Id,List<Opportunity>>();
        Map<Id,List<Opportunity>> thisMonthClosedLostMap = new Map<Id,List<Opportunity>>();
        
        for(Opportunity opp : lastWeekClosedOpps){
            if(opp.IsWon){
                List<Opportunity> lastWeekClosedWonMapOppList = lastWeekClosedWonMap.containsKey(opp.OwnerId) ? lastWeekClosedWonMap.get(opp.OwnerId) : new List<Opportunity>();
                lastWeekClosedWonMapOppList.add(opp);
                lastWeekClosedWonMap.put(opp.OwnerId,lastWeekClosedWonMapOppList);
            }else{
                List<Opportunity> lastWeekClosedLostMapOppList = lastWeekClosedLostMap.containsKey(opp.OwnerId) ? lastWeekClosedLostMap.get(opp.OwnerId) : new List<Opportunity>();
                lastWeekClosedLostMapOppList.add(opp);
                lastWeekClosedLostMap.put(opp.OwnerId,lastWeekClosedLostMapOppList);
            }
            
        }
        
        for(Opportunity opp : thisMonthClosedOpps){
            if(opp.IsWon){
                List<Opportunity> thisMonthClosedWonMapOppList = thisMonthClosedWonMap.containsKey(opp.OwnerId) ? thisMonthClosedWonMap.get(opp.OwnerId) : new List<Opportunity>();
                thisMonthClosedWonMapOppList.add(opp);
                thisMonthClosedWonMap.put(opp.OwnerId,thisMonthClosedWonMapOppList);
            }else{
                List<Opportunity> thisMonthClosedLostMapOppList = thisMonthClosedLostMap.containsKey(opp.OwnerId) ? thisMonthClosedLostMap.get(opp.OwnerId) : new List<Opportunity>();
                thisMonthClosedLostMapOppList.add(opp);
                thisMonthClosedLostMap.put(opp.OwnerId,thisMonthClosedLostMapOppList);
            }
            
        }
        
        List<User> usersToUpdate = new List<User>();
        for(Id ownerId : ownerIds){
            //last week win rate
            Decimal lastWeekWonOpps = lastWeekClosedWonMap.containsKey(ownerId) ? lastWeekClosedWonMap.get(ownerId).size() : 0;
            Decimal lastWeekLostOpps = lastWeekClosedLostMap.containsKey(ownerId) ? lastWeekClosedLostMap.get(ownerId).size() : 0;
            Decimal lastWeekWinRate = lastWeekWonOpps != 0 ? lastWeekWonOpps / (lastWeekLostOpps + lastWeekWonOpps) : 0;
            lastWeekWinRate = lastWeekWinRate * 100;
            
            //this month win rate
            Decimal thisMonthWonOpps = thisMonthClosedWonMap.containsKey(ownerId) ? thisMonthClosedWonMap.get(ownerId).size() : 0;
            Decimal thisMonthLostOpps = thisMonthClosedLostMap.containsKey(ownerId) ? thisMonthClosedLostMap.get(ownerId).size() : 0;
            Decimal thisMonthWinRate = thisMonthWonOpps != 0 ? thisMonthWonOpps / (thisMonthLostOpps + thisMonthWonOpps) : 0;
            thisMonthWinRate = thisMonthWinRate * 100;

            User userToUpdate = new User(Id = ownerId, Last_Week_Win_Rate_New_Business__c = lastWeekWinRate, This_Month_Win_Rate_New_Business__c = thisMonthWinRate);
            usersToUpdate.add(userToUpdate);
        }
        
        update usersToUpdate;
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    
    public void execute(SchedulableContext sc){
        Database.executeBatch(this);
    }
    
    public void clearAllWinRates(){
        List<User> usersToClear = [SELECT Id FROM User WHERE
                                   Last_Week_Win_Rate_New_Business__c != NULL OR This_Month_Win_Rate_New_Business__c != NULL];
        for(User u : usersToClear){
            u.Last_Week_Win_Rate_New_Business__c = null;
            u.This_Month_Win_Rate_New_Business__c = null;
        }
        
        update usersToClear;
    }
}