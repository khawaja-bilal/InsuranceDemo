public with sharing class EmployeeUploaderController {
    @AuraEnabled
    public static void uploadEmployees(List<Map<String, Object>> employees) {
        List<Employee__c> newEmployees = new List<Employee__c>();

        for (Map<String, Object> emp : employees) {
            Employee__c e = new Employee__c();
            e.Name = (String) emp.get('Name');
            e.Email__c = (String) emp.get('Email');
            e.Phone__c = (String) emp.get('Phone');
            // e.Department__c = (String) emp.get('Department');
            // e.Company__c = (String) emp.get('Company'); // Link to Account or custom object
            newEmployees.add(e);
        }

        insert newEmployees;
    }
}