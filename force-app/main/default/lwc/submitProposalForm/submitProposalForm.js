import { LightningElement, api, track, wire } from 'lwc';
import proposalSubmit from '@salesforce/apex/SendValuationFormController.ProposalSubmit';
debugger;
export default class submitProposalForm extends LightningElement {
    // Section 1: Provider Information
    @track serviceProviderName = 'Ahmed Al-Saud';
    @track mohLicense = '177788';
    @track address = 'Ath Thumamah Road,A Sahafah, 3244, Riyadh 13315';
    @track phone = '+920000560';
    @track email = 'noumaneycon@gmail.com';
    @track pointOfContact = 'Ahmed Al-Saud';
    @track proposalDate;

    // Section 2: proposal Summary 
    @track detailDescription = 'A full panel of laboratory diagnostics, including blood tests, urine analysis, and other essential screenings, to assess key health indicators such as blood sugar levels, cholesterol, kidney and liver function, and more. These tests aid in early detection, diagnosis, and monitoring of various medical conditions.';

    // Section 3: Service Details
    @track services = [
        { code: 'HC001', description: 'استشارة عامة / General Consultation', unitCost: 200, frequency: '50/month', monthlyEstimate: '10,000' },
        { code: 'HC002', description: 'جلسة علاج طبيعي / Physical Therapy Session', unitCost: 260, frequency: '30/month', monthlyEstimate: '7,800' },
        { code: 'HC003', description: 'فحوصات مخبرية كاملة / Complete Lab Tests', unitCost: 375, frequency: '25/month', monthlyEstimate: '9,375' }
    ];

    //Section 4: Duration
    @track contractDuration = '12';
    @track startDate;
    @track billingTerms = 'This agreement is valid for a period of 12 months from the start date specified in the agreement.';
    @track otherConditions = 'Invoices will be issued monthly on the first business day of each month for services rendered during the previous month.';

    // Section 5: proposal Method
    @track selectedDocuments = [];
    @track supportingDocuments = [
        { label: 'MoH License Copy', value: 'licenseCopy' },
        { label: 'Service Brochure', value: 'serviceBrochure' },
        { label: 'Price Justification or Benchmark', value: 'priceJustification' },
        { label: 'CVs of Key Medical Personnel', value: 'cvMedical' },
        { label: 'Facility Photos or Accreditation', value: 'facilityPhotos' }

    ];
    //section 6
    @track authorizedSignatory = '';
    @track position = 'Operations Director';
    @track date;

    // @track supportingDocs = '';

    // Section 5: Prepared By
    @track ButtonDisabled = false; // Initially disabled
    // URL parameters
    leadId;
    userId;
    @track showToast = false;
    @track toastMessage = '';
    @track toastVariant = 'success'; // success, error, info, warning
    connectedCallback() {
        debugger;
        this.parseUrlParameters();
    }

    parseUrlParameters() {
        const url = new URL(window.location.href);
        const searchParams = new URLSearchParams(url.search);

        this.leadId = searchParams.get('recordId') || '';
        this.userId = searchParams.get('userId') || '';
    }

    handleSubmit() {
        if (this.validateForm()) {
            this.submitFormData();
        }
    }

    handleCancel() {
        // Reset form or navigate away
        history.back();
    }

    validateForm() {
        let isValid = true;
        const allInputs = this.template.querySelectorAll('lightning-input, lightning-textarea');

        allInputs.forEach(input => {
            if (input.required && !input.value) {
                input.setCustomValidity('This field is required');
                isValid = false;
            } else {
                input.setCustomValidity('');
            }
            input.reportValidity();
        });
        return isValid;
    }

    async submitFormData() {
        debugger;
        // submitFormData() {
        try {
            // Prepare service details
            // const serviceDetails = this.services.map(service => {
            //     return {
            //         Name: service.code,
            //         Description: service.description,
            //         Cost: service.unitCost,
            //         Frequency: service.frequency,
            //         Estimates: service.monthlyEstimate
            //     };
            // });

            let licenseCopy = false;
            let serviceBrochure = false;
            let priceJustification = false;
            let cvMedical = false;
            let facilityPhotos = false;

            if (this.selectedDocuments.includes('licenseCopy')) {
                licenseCopy = true;
            }
            if (this.selectedDocuments.includes('serviceBrochure')) {
                serviceBrochure = true;
            }
            if (this.selectedDocuments.includes('priceJustification')) {
                priceJustification = true;
            }
            if (this.selectedDocuments.includes('cvMedical')) {
                cvMedical = true;
            }
            if (this.selectedDocuments.includes('facilityPhotos')) {
                facilityPhotos = true;
            }
            const formDetails = {
                // Section 1
                Service_Provider_Name__c: this.serviceProviderName,
                MoH_License_Number__c: this.mohLicense,
                Address__c: this.address,
                Phone__c: this.phone,
                Email__c: this.email,
                Point_of_Contact__c: this.pointOfContact,
                Date_of_Proposal__c: this.proposalDate,
                // Section 2
                Description__c: this.detailDescription,
                // Section 4
                Proposed_Contract_Duration__c: this.contractDuration,
                Start_Date__c: this.startDate,
                Billing_Terms__c: this.billingTerms,
                Other_Conditions__c: this.otherConditions,
                //Section 5
                MoH_License_Copy__c: licenseCopy,
                Service_Brochure__c: serviceBrochure,
                Price_Justification_or_Benchmark__c: priceJustification,
                CVs_of_Key_Medical_Personnel__c: cvMedical,
                Facility_Photos_or_Accreditation__c: facilityPhotos,
                // Section 6
                Authorized_Signatory__c: this.authorizedSignatory,
                Position__c: this.position,
                Date__c: this.date
                // serviceDetails: serviceDetails
            };


            this.showCustomToast('Your proposal form has been sent successfully!', 'success');
            this.ButtonDisabled = true; // Disable the button after submission

            // Call Apex method to submit the form
            const result = await proposalSubmit({
                leadID: this.leadId,
                userID: this.userId,
                // leadID: '00QKj00002BKx9zMAD',
                // userID: '0058V00000FHJ7ZQAX',
                formDetails: JSON.stringify(formDetails)
            });
        } catch (error) {
            // this.showToast('Error', error.body.message, 'error');
        }
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        this[field] = value;
    }

    handleMethodChange(event) {
        this.selectedDocuments = event.detail.value;
    }

    handleDateChange(event) {
        this.date = event.target.value;
    }

    showCustomToast(message, variant = 'success') {
        this.toastMessage = message;
        this.toastVariant = variant;
        this.showToast = true;

        // Auto-hide after 3 seconds
        setTimeout(() => {
            this.showToast = false;
        }, 3000);
    }
}