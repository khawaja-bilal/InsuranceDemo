public class DocumentServiceHandler {

    @AuraEnabled(cacheable=true)
    public static void ValuationSubmit(string leadID,string userID,string formDetails,string serviceDetails) {
        User u = [select id,name,email from user where id = :userID];
        
        //Update lead status to next status
        Lead l = [select id,name,status from lead where id = :leadID];
        l.Status = 'Proposal Pending';
        Database.update(l);
        
        //Create Valuation form and service detaild
        Valuation_Form__c vForm = (Valuation_Form__c)JSON.Deserialize(formDetails,Valuation_Form__c.class);
        List<Service_Detail__c> serDetails = (List<Service_Detail__c>)JSON.Deserialize(formDetails,Service_Detail__c.class);
               
        vForm.Lead__c = leadID;
        Database.Insert(vForm);
        
        for(Service_Detail__c sd:serDetails)
        {
            sd.Valuation_Form__c = vForm.Id;
        }
        
        Database.Insert(serDetails);
        
        //email salesRep document is received
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[] { u.email };
        message.subject = 'Valuation Form Received';
        message.plainTextBody = 'Valuation form is received from '+l.Name+'. Please review the lead record. Link';
        message.plainTextBody += 'https://d8v000002llqcuag-dev-ed.develop.lightning.force.com/lightning/r/Lead/'+l.id+'/view';
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
        //Create Followup Tasks
        Task t1 = new Task();
        t1.ActivityDate = system.today().addDays(1);
        t1.Subject = 'Verify Valuation Form';
        t1.WhoId = leadId;
        t1.OwnerId = u.Id;
        
		Task t2 = new Task();
        t2.ActivityDate = system.today().addDays(2);
        t2.Subject = 'Send Proposal';
        t2.WhoId = leadId;
        t2.OwnerId = u.Id;        

		List<Task> lstTasks = new List<Task>();
        lstTasks.add(t1);
        lstTasks.add(t2);
        
        Database.insert(lstTasks);
        
    }
}