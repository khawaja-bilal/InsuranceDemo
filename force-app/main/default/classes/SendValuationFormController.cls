public without sharing class SendValuationFormController {
    @AuraEnabled
    public static String sendLeadEmail(String leadId) {
        if (leadId == null) {
            throw new AuraHandledException('Lead ID is required.');
        }
        
        Lead leadRecord = [
            SELECT Id, Name, Email 
            FROM Lead 
            WHERE Id = :leadId 
            LIMIT 1
        ];
        
        leadRecord.Status = 'Valuation Sent';
        Database.update(leadRecord);
        
        // Fetch only the current user ID
        Id currentUserId = UserInfo.getUserId();
        
        // Append both leadId and userId to the URL
        String url = 'https://d8v000002llqcuag-dev-ed.develop.my.site.com/valuation-form?recordId=' 
            + EncodingUtil.urlEncode(leadId, 'UTF-8') 
            + '&userId=' + EncodingUtil.urlEncode(currentUserId, 'UTF-8');
        
        String body = 'Dear ' + leadRecord.Name + ',<br/><br/>' +
            'Thank you for choosing our health insurance services.<br/><br/>' +
            'To proceed, please click the link below to complete the valuation form:<br/><br/>' +
            '👉 <a href="' + url + '">Complete Health Valuation Form</a><br/><br/>' +
            'Best regards,<br/>CAIS Consulting Actuaries & Insurance Specialists';
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'noumaneycon@gmail.com'];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { leadRecord.id });
        mail.setSubject('Valuation Form');
        mail.setHtmlBody(body);
        mail.setSaveAsActivity(false);
        mail.setOrgWideEmailAddressId(owea.get(0).Id);
        system.debug('mail---:'+mail);
        system.debug('from---:'+owea.get(0).ID);
        system.debug('url----' + url);
        system.debug('body----' + body);
        system.debug('setToAddresses=----' + leadRecord.Email);
        try {
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {mail};
                 Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                system.debug('SUCCESS');
            return 'Success';
        } catch (Exception e) {
            System.debug('Email failed to send: ' + e.getMessage());
            return 'Email failed to send: ' + e.getMessage();
        }
    }
    @AuraEnabled(cacheable=true)
    public static Lead getLeadDetails(String leadId) {
        system.debug('leadId----' + leadId);
        
        return [
            SELECT Id, Name, ServiceType__c
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];
    }
    
    @AuraEnabled
    public static String ValuationSubmit(string leadID,string userID,string formDetails,string serviceDetails) {
        system.debug('leadID'+ leadID);
        system.debug('userID'+ userID);
        system.debug('formDetails'+ formDetails);
        system.debug('serviceDetails'+ serviceDetails);
        //Update lead status to next status
        try {
            
            
            User u = [select id,name,email from user where id = :userID];
            
            Lead l = [select id,name,status from lead where id = :leadID];
            l.Status = 'Proposal Pending';
            Database.update(l);
            
            //Create Valuation form and service detaild
            Valuation_Form__c vForm = (Valuation_Form__c)JSON.Deserialize(formDetails,Valuation_Form__c.class);
            //List<Service_Detail__c> serDetails = (List<Service_Detail__c>)JSON.Deserialize(serviceDetails,Service_Detail__c.class);
            List<DetailWrapper> serDetails = (List<DetailWrapper>)JSON.Deserialize(serviceDetails,List<DetailWrapper>.class);
            
            List<Service_Detail__c> lstDetails = new List<Service_Detail__c> ();
            
            vForm.Lead__c = leadID;
            Database.Insert(vForm);
            system.debug('vForm'+ vForm);
            for(DetailWrapper sd:serDetails)
            {	
                Service_Detail__c d = new Service_Detail__c();
                d.Name = sd.Name;
                d.Service_Description__c = sd.Description;
                d.Frequency__c = sd.Frequency;
                d.Unit_Cost__c = sd.cost;
                d.Monthly_Estimates__c = sd.Estimates;
                d.Valuation_Form__c = vForm.Id;
                lstDetails.add(d);
                system.debug('sd'+ sd);
            }
            
            Database.Insert(lstDetails);
            
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'noumaneycon@gmail.com'];
            //email salesRep document is received
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { u.email };
                message.subject = 'Valuation Form Received';
            message.plainTextBody = 'Valuation form is received from '+l.Name+'.<br/> Please review the lead record. Link: ';
            message.plainTextBody += 'https://d8v000002llqcuag-dev-ed.develop.lightning.force.com/lightning/r/Lead/'+l.id+'/view';
            message.setOrgWideEmailAddressId(owea.get(0).Id);
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
            
            Task t3 = [select id from Task where subject = 'Begin Valuation Process' and whoId = :leadID];
            t3.status = 'Completed';
            Database.Update(t3);
            
            //Send slack notification
            string msg = 'Valuation form is received from '+l.Name+'. Please review the lead record. Link: ';
            msg += '<https://d8v000002llqcuag-dev-ed.develop.lightning.force.com/lightning/r/Lead/'+l.id+'/view>';
            SendSlack(msg);
        } catch (Exception ex) {
            system.debug('Error: ' + ex.getMessage());
            return 'Error: ' + ex.getMessage();
        }
        return 'Success';
    }
    
    @AuraEnabled
    public static String sendProposalEmail(String leadId)
    {
        if (leadId == null) {
            throw new AuraHandledException('Lead ID is required.');
        }
        
        Lead leadRecord = [
            SELECT Id, Name, Email 
            FROM Lead 
            WHERE Id = :leadId 
            LIMIT 1
        ];
        
        leadRecord.Status = 'Proposal Sent';
        Database.update(leadRecord);
        
        List<Task> lstTasks = new List<Task>([select id,status from task 
                                              where (subject = 'Verify Valuation Form' or subject = 'Send Proposal') 
                                              and whoid = :leadId and status <> 'Completed']);
        
        for(Task t:lstTasks)
        {
            t.status = 'Completed';
        }
        Database.update(lstTasks);
        
        // Fetch only the current user ID
        Id currentUserId = UserInfo.getUserId();
        
        // Append both leadId and userId to the URL
        String url = 'https://d8v000002llqcuag-dev-ed.develop.my.site.com/proposal-form?recordId=' 
            + EncodingUtil.urlEncode(leadId, 'UTF-8') 
            + '&userId=' + EncodingUtil.urlEncode(currentUserId, 'UTF-8');
        
        String body = 'Dear ' + leadRecord.Name + ',<br/><br/>' +
            'Thank you for choosing our health insurance services.<br/><br/>' +
            'To proceed, please click the link below to review and accept the Proposal form:<br/><br/>' +
            '👉 <a href="' + url + '">Complete Health Proposal Form</a><br/><br/>' +
            'Best regards,<br/>CAIS Consulting Actuaries & Insurance Specialists';
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'noumaneycon@gmail.com'];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { leadRecord.id });
        mail.setSubject('Proposal Form');
        mail.setHtmlBody(body);
        mail.setSaveAsActivity(false);
        mail.setOrgWideEmailAddressId(owea.get(0).Id);
        system.debug('mail---:'+mail);
        system.debug('from---:'+owea.get(0).ID);
        system.debug('url----' + url);
        system.debug('body----' + body);
        system.debug('setToAddresses=----' + leadRecord.Email);
        try {
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {mail};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            system.debug('SUCCESS');
            return 'Success';
        } catch (Exception e) {
            System.debug('Email failed to send: ' + e.getMessage());
            return 'Email failed to send: ' + e.getMessage();
        }
        
        
    }
    @AuraEnabled
    public static string ProposalSubmit(string leadID,string userID,string formDetails) 
    {
        system.debug('leadID'+ leadID);
        system.debug('userID'+ userID);
        system.debug('formDetails'+ formDetails);
        //Update lead status to next status
        try {
            
            
            User u = [select id,name,email from user where id = :userID];
            
            Lead l = [select id,name,status from lead where id = :leadID];
            l.Status = 'Proposal Approved';
            Database.update(l);
            
            //Create Valuation form and service detaild
            Proposal_Form__c pForm = (Proposal_Form__c)JSON.Deserialize(formDetails,Proposal_Form__c.class);
            
            pForm.Lead__c = leadID;
            Database.Insert(pForm);
            system.debug('pForm'+ pForm);
            
            
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'noumaneycon@gmail.com'];
            //email salesRep document is received
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { u.email };
                message.subject = 'Proposal Form Received';
            message.plainTextBody = 'Proposal form is received from '+l.Name+'.<br/> Please review the lead record. Link: ';
            message.plainTextBody += 'https://d8v000002llqcuag-dev-ed.develop.lightning.force.com/lightning/r/Lead/'+l.id+'/view';
            message.setOrgWideEmailAddressId(owea.get(0).Id);
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                
                //Send slack notification
                //Send slack notification
                string msg = 'Proposal form is received from '+l.Name+'. Please review the lead record. Link: ';
            msg += '<https://d8v000002llqcuag-dev-ed.develop.lightning.force.com/lightning/r/Lead/'+l.id+'/view>';
            SendSlack(msg);
            
            
            //Create Followup Tasks
            Task t1 = new Task();
            t1.ActivityDate = system.today().addDays(1);
            t1.Subject = 'Verify Proposal Form';
            t1.WhoId = leadId;
            t1.OwnerId = u.Id;
            
            Task t2 = new Task();
            t2.ActivityDate = system.today().addDays(2);
            t2.Subject = 'Begin Engagement Process';
            t2.WhoId = leadId;
            t2.OwnerId = u.Id;        
            
            List<Task> lstTasks = new List<Task>();
            lstTasks.add(t1);
            lstTasks.add(t2);
            
            Database.insert(lstTasks);
            
        } catch (Exception ex) {
            system.debug('Error: ' + ex.getMessage());
            return 'Error: ' + ex.getMessage();
        }
        return 'Success';
    }
    
    @AuraEnabled
    public static String sendEngagementEmail(String leadId)
    {
        if (leadId == null) {
            throw new AuraHandledException('Lead ID is required.');
        }
        
        Lead leadRecord = [
            SELECT Id, Name, Email 
            FROM Lead 
            WHERE Id = :leadId 
            LIMIT 1
        ];
        
        
        List<Task> lstTasks = new List<Task>([select id,status from task where 
                                              subject = 'Send Engagement Form'and status <> 'Completed'
                                              and whoId = :leadId]);
        
        for(Task t:lstTasks)
        {
            t.status = 'Completed';
        }
        Database.update(lstTasks);
        
        // Fetch only the current user ID
        Id currentUserId = UserInfo.getUserId();
        
        // Append both leadId and userId to the URL
        String url = 'https://d8v000002llqcuag-dev-ed.develop.my.site.com/engagement-form?recordId=' 
            + EncodingUtil.urlEncode(leadId, 'UTF-8') 
            + '&userId=' + EncodingUtil.urlEncode(currentUserId, 'UTF-8');
        
        String body = 'Dear ' + leadRecord.Name + ',<br/><br/>' +
            'Thank you for choosing our health insurance services.<br/><br/>' +
            'Please download the Data tempalte from here, fill out your employee details and attach the file with engament form.<br/><br/>'+
            '👉 <a href="https://d8v000002llqcuag-dev-ed.develop.my.salesforce.com/sfc/p/8V000002LLqc/a/Kj000001tX99/IAKfdP8.sUSHBVbmMkH_xGGIEE5rGl9L_WTA5S41cQk">Employee Details Template</a><br/><br/>' +
            'To proceed, please click the link below to review and accept the Engagement form:<br/><br/>' +
            '👉 <a href="' + url + '">Complete Health Engagement Form</a><br/><br/>' +
            'Best regards,<br/>CAIS Consulting Actuaries & Insurance Specialists<br/><br/>';
        
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'noumaneycon@gmail.com'];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { leadRecord.id });
        mail.setSubject('Engagement Form');
        mail.setHtmlBody(body);
        mail.setSaveAsActivity(false);
        mail.setOrgWideEmailAddressId(owea.get(0).Id);
        system.debug('mail---:'+mail);
        system.debug('from---:'+owea.get(0).ID);
        system.debug('url----' + url);
        system.debug('body----' + body);
        system.debug('setToAddresses=----' + leadRecord.Email);
        try {
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {mail};
                 Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                system.debug('SUCCESS');
            return 'Success';
        } catch (Exception e) {
            System.debug('Email failed to send: ' + e.getMessage());
            return 'Email failed to send: ' + e.getMessage();
        }
        
        
    }
    @AuraEnabled
    public static string EngagementSubmit(string leadID,string userID,string formDetails,string document) 
    {
        system.debug('leadID'+ leadID);
        system.debug('userID'+ userID);
        system.debug('formDetails'+ formDetails);
        //Update lead status to next status
        try {
            
            //convert the lead
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leadID);
            
            LeadStatus convertStatus = [SELECT Id, ApiName FROM LeadStatus WHERE IsConverted=true LIMIT 1];
            lc.setConvertedStatus(convertStatus.ApiName);
            
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            string oppId = lcr.getOpportunityID();
            System.debug('oppId:'+oppId);
            
            // Deserialize form details
            Map<String, Object> formDetailsMap = (Map<String, Object>)JSON.deserializeUntyped(formDetails);
            String clientName = (String)formDetailsMap.get('Name');
            Date startDate = Date.valueOf((String)formDetailsMap.get('Start_Date__c'));
            
            // Deserialize document data
            Map<String, Object> documentMap = (Map<String, Object>)JSON.deserializeUntyped(document);
            List<Object> documents = (List<Object>)documentMap.get('documents');
            
            // Process the form data (create records, etc.)
            // Example: Create an Engagement record
            Engagement__c engagement = new Engagement__c(
                Name = clientName,
                Start_Date__c = startDate,
                Opportunity__c = oppID
                // other fields
            );
            
            insert engagement;
            
            // Process documents
            List<ContentVersion> contentVersionsToInsert = new List<ContentVersion>();
            List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();
            for (Object docObj : documents) {
                Map<String, Object> doc = (Map<String, Object>)docObj;
                String documentId = (String)doc.get('documentId');
                String title = (String)doc.get('title');
                String versionId = (String)doc.get('versionId');
                
                // Query the ContentVersion to get the actual file data
                ContentVersion cv = [
                    SELECT VersionData, Title, PathOnClient, FileExtension 
                    FROM ContentVersion 
                    WHERE Id = :versionId
                ];
                
                // Create a new ContentVersion linked to the engagement
                ContentVersion newCv = new ContentVersion(
                    Title = title,
                    PathOnClient = cv.PathOnClient,
                    VersionData = cv.VersionData,
                    FirstPublishLocationId = engagement.Id
                );
                contentVersionsToInsert.add(newCv);
            }
            
            if (!contentVersionsToInsert.isEmpty()) {
                insert contentVersionsToInsert;
            }
            // Nouman Code Commented for now.
            
            User u = [select id,name,email from user where id = :userID];
            
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'noumaneycon@gmail.com'];
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { u.email };
            message.subject = 'Engagement Form Received';
            message.plainTextBody = 'Engagement form is received .<br/> Please review the Opportunity record. Link: ';
            message.plainTextBody += 'https://d8v000002llqcuag-dev-ed.develop.lightning.force.com/lightning/r/Opportunity/'+oppId+'/view';
            message.setOrgWideEmailAddressId(owea.get(0).Id);
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                  Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            string msg = 'Engagement form is received . Please review the opportunity record. Link: ';
            msg += '<https://d8v000002llqcuag-dev-ed.develop.lightning.force.com/lightning/r/Opportunity/'+oppId+'/view>';
            SendSlack(msg);
                
            Task t1 = new Task();
            t1.ActivityDate = system.today().addDays(1);
            t1.Subject = 'Verify Data';
            t1.whatid = oppId;
            t1.OwnerId = u.Id;
            
            Database.insert(t1); 
            
        } catch (Exception ex) {
            system.debug('Error: ' + ex.getMessage());
            return 'Error: ' + ex.getMessage();
        }
        return 'Success';
    }
    
    
    public class DetailWrapper
    {
        public string Name;
        public string Description;
        public double Cost;
        public string Frequency;
        public double estimates;
    }
    
    @future(callout=true)
    public static void SendSlack(string body)
    {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://hooks.slack.com/services/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');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        SlackMessage m = new SlackMessage();
        m.text = body;
        string text = JSON.Serialize(m);
        req.setBody(text);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
    }
    
    public class SlackMessage
    {
        public string text;
    }
    // Comment for nouman *Un comment this if you want to use wrapper* 
    // public class DocumentWrapper
    // {
    //     public string documentId;
    //     public string title;
    //     public string versionId;
    // }
}