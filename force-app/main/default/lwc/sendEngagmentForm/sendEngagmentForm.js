import { LightningElement, api, wire } from 'lwc';
import getLeadDetails from '@salesforce/apex/SendValuationFormController.getLeadDetails';
import sendEngagementEmail from '@salesforce/apex/SendValuationFormController.sendEngagementEmail';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
debugger;

export default class SendProposal extends LightningElement {
    @api recordId;
    showModal = true;
    leadName = '';
    serviceType = '';

    @wire(getLeadDetails, { leadId: '$recordId' })
    wiredLead({ data, error }) {
        debugger;

        if (data) {
            this.leadName = data.Name || '';
            this.serviceType = data.ServiceType__c || '';
        } else if (error) {
            console.error('Error loading lead details:', error);
            this.showToast('Error', error.body?.message || 'Error loading lead details', 'error');
            this.closeModal();
        }
    }

    handleCancel() {
        this.closeModal();
    }

    handleSubmit() {
        debugger;
        if (!this.serviceType) {
            this.showToast('Error', 'Please select a service type before sending', 'error');
            return;
        }

        sendEngagementEmail({ leadId: this.recordId })
            .then(() => {
                this.showToast('Success', 'Engagement Letter sent successfully', 'success');
                this.closeModal();
            })
            .catch(error => {
                console.error('Error sending Engagement Letter:', error);
                this.showToast('Error', error.body?.message || 'Error sending Engagement Letter', 'error');
            });
    }

    closeModal() {
        this.showModal = false;
        this.dispatchEvent(new CloseActionScreenEvent());
        window.location.reload();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title || 'Notification',
            message: message || '',
            variant: variant || 'info'
        }));
    }
}