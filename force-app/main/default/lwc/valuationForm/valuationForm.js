import { LightningElement, api, track, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { getRecord } from 'lightning/uiRecordApi';
import submitValuationForm from '@salesforce/apex/SendValuationFormController.ValuationSubmit';
debugger;
export default class HealthcareValuationForm extends LightningElement {
    // Section 1: Provider Information
    @track facilityName = 'Health Care';
    @track mohLicense = '177788';
    @track address = 'Ath Thumamah Road,A Sahafah, 3244, Riyadh 13315';
    @track phone = '+920000560';
    @track email = 'noumaneycon@gmail.com';
    @track owner = 'Ahmed Al-Saud';

    // Section 2: Service Details
    @track services = [
        { code: 'HC001', description: 'استشارة عامة / General Consultation', unitCost: 200, frequency: 40, monthlyEstimate: 8000 },
        { code: 'HC002', description: 'جلسة علاج طبيعي / Physical Therapy Session', unitCost: 260, frequency: 20, monthlyEstimate: 5200 },
        { code: 'HC003', description: 'فحوصات مخبرية كاملة / Complete Lab Tests', unitCost: 375, frequency: 30, monthlyEstimate: 11250 },
        { code: 'HC004', description: 'تصوير طبي (أشعة/MRI) / Medical Imaging (X-ray/MRI)', unitCost: 850, frequency: 10, monthlyEstimate: 8500 },
        { code: 'HC005', description: 'إقامة يومية في المستشفى / Daily Hospital Stay', unitCost: 1200, frequency: 20, monthlyEstimate: 24000 }
    ];

    // Section 3: Valuation Summary
    @track monthlyTotal = 56950;
    @track annualTotal = 683400;

    // Section 4: Valuation Method
    @track valuationMethods = [
        { label: 'التكاليف الفعلية / Cost-Based', value: 'costBased' },
        { label: 'أسعار السوق / Market Comparison', value: 'marketComparison' },
        { label: 'متوسط تاريخي / Historical Data', value: 'historicalData' },
        { label: 'تقييم طرف ثالث / Third-Party Appraisal', value: 'thirdParty' }
    ];
    @track selectedMethods = [];
    @track supportingDocs = '';

    // Section 5: Prepared By
    @track preparedByName = 'Fatimah Al-Harbi';
    @track preparedByTitle = 'Operations Manager';
    @track preparedDate = '';
    @track signature = '';
    @track ButtonDisabled = false; // Initially disabled
    // URL parameters
    leadId;
    userId;
    @track showToast = false;
    @track toastMessage = '';
    @track toastVariant = 'success'; // success, error, info, warning
    connectedCallback() {
        debugger;
        // this.calculateTotals();
        this.parseUrlParameters();
    }

    parseUrlParameters() {
        const url = new URL(window.location.href);
        const searchParams = new URLSearchParams(url.search);

        this.leadId = searchParams.get('recordId') || '';
        this.userId = searchParams.get('userId') || '';
    }

    handleServiceChange(event) {
        const code = event.target.dataset.code;
        const field = event.target.dataset.field;
        const value = parseFloat(event.target.value) || 0;

        this.services = this.services.map(service => {
            if (service.code === code) {
                service[field] = value;
                service.monthlyEstimate = service.unitCost * service.frequency;
            }
            return service;
        });
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
        // submitFormData() {
        try {
            let costBased = false;
            let marketComparison = false;
            let historicalData = false;
            let thirdParty = false;
            if (this.selectedMethods.includes('costBased')) {
                costBased = true;
            }
            if (this.selectedMethods.includes('marketComparison')) {
                marketComparison = true;
            }
            if (this.selectedMethods.includes('historicalData')) {
                historicalData = true;
            }
            if (this.selectedMethods.includes('thirdParty')) {
                thirdParty = true;
            }
            // Prepare form details (excluding service details)
            const formDetails = {
                Facility_Name__c: this.facilityName,
                MoH_License_No__c: this.mohLicense,
                Address__c: this.address,
                Phone__c: this.phone,
                Email__c: this.email,
                Owner__c: this.owner,
                Total_Monthly_Estimate__c: this.monthlyTotal,
                Total_Annual_Estimate__c: this.annualTotal,
                Name__c: this.preparedByName,
                Position__c: this.preparedByTitle,
                Date__c: this.preparedDate,
                Cost_Based__c: costBased,
                Market_Comparison__c: marketComparison,
                Historical_Data__c: historicalData,
                Third_Party__c: thirdParty
                // signature: this.signature
            };

            // Prepare service details
            const serviceDetails = this.services.map(service => {
                return {
                    Name: service.code,
                    Description: service.description,
                    Cost: service.unitCost,
                    Frequency: service.frequency,
                    Estimates: service.monthlyEstimate
                };
            });
            this.showCustomToast('Your valuation form has been sent successfully!', 'success');
            // this.showToast('Success', 'Your valuation form has been sent successfully.', 'success');
            this.ButtonDisabled = true; // Disable the button after submission

            // Call Apex method to submit the form
            const result = await submitValuationForm({
                leadID: this.leadId,
                userID: this.userId,
                formDetails: JSON.stringify(formDetails),
                serviceDetails: JSON.stringify(serviceDetails)
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
        this.selectedMethods = event.detail.value;
    }

    handleDateChange(event) {
        this.preparedDate = event.target.value;
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