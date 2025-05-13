import { LightningElement } from 'lwc';
import SheetJS from '@salesforce/resourceUrl/SheetJS';
import { loadScript } from 'lightning/platformResourceLoader';
import uploadEmployees from '@salesforce/apex/EmployeeUploaderController.uploadEmployees';

export default class EmployeeUploader extends LightningElement {
    sheetJsInitialized = false;

    renderedCallback() {
        if (this.sheetJsInitialized) return;
        this.sheetJsInitialized = true;

        loadScript(this, SheetJS)
            .then(() => {
                console.log('SheetJS loaded successfully.');
            })
            .catch(error => {
                console.error('Error loading SheetJS', error);
            });
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            const file = uploadedFiles[0];
            this.readFile(file.documentId);
        }
    }

    readFile(documentId) {
        // Fetch the file from ContentVersion
        fetch(`/sfc/servlet.shepherd/version/download/${documentId}`)
            .then(res => res.arrayBuffer())
            .then(arrayBuffer => {
                const workbook = XLSX.read(arrayBuffer, { type: 'array' });
                const sheetName = workbook.SheetNames[0];
                const sheet = workbook.Sheets[sheetName];
                const data = XLSX.utils.sheet_to_json(sheet);
                console.log('Parsed Data:', data);
                this.uploadToApex(data);
            })
            .catch(error => {
                console.error('Error reading file:', error);
            });
    }

    uploadToApex(data) {
        uploadEmployees({ employees: data })
            .then(() => {
                console.log('Employees uploaded successfully');
            })
            .catch(error => {
                console.error('Error uploading employees:', error);
            });
    }
}