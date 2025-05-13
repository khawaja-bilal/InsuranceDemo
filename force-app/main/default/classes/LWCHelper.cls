public with sharing class LWCHelper {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
         List<Account> accList  = [SELECT Id, Name, Industry,Phone FROM Account LIMIT 10];
          
        return accList;
      
    }
}