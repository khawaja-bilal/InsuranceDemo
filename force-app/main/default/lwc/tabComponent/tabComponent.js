import { LightningElement,wire,track } from 'lwc';

import getAccounts from '@salesforce/apex/LWCHelper.getAccounts';

const COLUMNS = [
    { label: 'Name', fieldName: 'Name',sortable: true },
    { label: 'Industry', fieldName: 'Industry' },
    { label: 'Phone', fieldName: 'Phone', type: 'phone' },
];

export default class TabComponent extends LightningElement {
    accounts;
    errors;
    columns = COLUMNS;
    @track tabValue = 'C';

    @wire(getAccounts)
    wiredAccounts({ error, data }) {
       // alert(data);
       // debugger;
        if (data) {
            console.log('Data received:', JSON.stringify(data));
            this.accounts = data.map(acc => ({
                Id: acc.Id,  // ✅ key-field must match this
                Name: acc.Name,
                Industry: acc.Industry,
                Phone: acc.Phone
            }));
            console.log('account this:', this.accounts);
           // this.accounts = data;
        } else if (error) {
            this.error = error;
        }
    }

    buttonClick()
    {
        
        console.log('::up'+this.tabValue);
        this.tabValue = 'A';
        console.log('::down'+this.tabValue);
    }

}