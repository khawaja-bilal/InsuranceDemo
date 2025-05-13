import { LightningElement, api, track } from 'lwc';
import EngagementSubmit from '@salesforce/apex/SendValuationFormController.EngagementSubmit';

export default class SubmitProposalForm extends LightningElement {
    @track clientName = 'Ahmed Al-Saud';
    @track date;
    acceptedFormats = ['.pdf', '.png', '.jpg', '.jpeg', '.docx', '.csv', '.xls', '.xlsx'];
    @track ButtonDisabled = true;
    @track uploadedFiles = [];
    @track showToast = false;
    @track toastMessage = '';
    @track toastVariant = 'success';
    leadId;
    userId;
    imgSrc;
    connectedCallback() {
        this.parseUrlParameters();
    }

    parseUrlParameters() {
        const url = new URL(window.location.href);
        const searchParams = new URLSearchParams(url.search);
        this.leadId = searchParams.get('recordId') || '';
        this.userId = searchParams.get('userId') || '';
    }

    handleUploadFinished(event) {
        this.uploadedFiles = event.detail.files;
        this.validateForm();
    }

    validateForm() {
        let isValid = true;
        const allInputs = this.template.querySelectorAll('lightning-input');
        
        allInputs.forEach(input => {
            if (input.required && !input.value) {
                input.setCustomValidity('This field is required');
                isValid = false;
            } else {
                input.setCustomValidity('');
            }
            input.reportValidity();
        });

        // Enable button only if form is valid and files are uploaded
        this.ButtonDisabled = !(isValid && this.uploadedFiles.length > 0);
        return isValid;
    }

    async handleSubmit() {
        if (!this.validateForm()) return;

        try {
        // Prepare file data as an object with meaningful structure
        const fileData = {
            documents: this.uploadedFiles.map(file => ({
                documentId: file.documentId,
                title: file.name,
                versionId: file.contentVersionId
            }))
        };
        console.log('File Data:', JSON.stringify(fileData));
            const formDetails = {
                Name: this.clientName,
                Start_Date__c: this.date
                // employeeDetails: JSON.stringify(fileData)
            };

            const result = await EngagementSubmit({
                leadID: this.leadId,
                userID: this.userId,
                // leadID: '00QKj00002BLBPwMAP',
                // userID: '0058V00000FHJ7ZQAX',
                formDetails: JSON.stringify(formDetails),
                document: JSON.stringify(fileData)

            });

            this.showCustomToast('Your acknowledgment has been submitted successfully!', 'success');
            this.resetForm();
        } catch (error) {
            this.showCustomToast('Error submitting form: ' + error.body.message, 'error');
            console.error('Submission error:', error);
        }
    }

    resetForm() {
        this.clientName = '';
        this.date = '';
        this.uploadedFiles = [];
        this.ButtonDisabled = true;
    }

    handleChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
        this.validateForm();
    }

    showCustomToast(message, variant = 'success') {
        this.toastMessage = message;
        this.toastVariant = variant;
        this.showToast = true;
        setTimeout(() => { this.showToast = false; }, 5000);
    }

    hideToast() {
        this.showToast = false;
    }
    // Signature Section 
    renderedCallback() {
        document.fonts.forEach((font) => {
          if (font.family === "Great Vibes" && font.status === "unloaded") {
            // Ensure that the font is loaded so that signature pad could use it.
            // If you are using a different font in your project, don't forget
            // to update the if-condition above to account for it.
            font.load();
          }
        });
      }
    
      saveSignature() {
        const pad = this.template.querySelector("c-signature-pad");
        if (pad) {
          const dataURL = pad.getSignature();
          if (dataURL) {
            // At this point you can consume the signature, for example by saving
            // it to disk or uploading it to a Salesforce org/record.
            // Here we just preview it in an image tag.
            this.imgSrc = dataURL;
          }
        }
      }
    
      clearSignature() {
        const pad = this.template.querySelector("c-signature-pad");
        if (pad) {
          pad.clearSignature();
        }
    
        this.imgSrc = null;
      }
}