import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const REQUEST_BODY = 'Integration_Log__c.Request_Body__c';
const RESPONSE_BODY = 'Integration_Log__c.Response_Body__c';

const fields = [
	REQUEST_BODY,
	RESPONSE_BODY
];

export default class IntegrationLogJsonViewer extends LightningElement {
	@api recordId;
	isLoading;
	data;
	requestBody;
	responseBody;

	label = {
		responseBody: "Response Body",
		requestBody: "Request Body"
	};

	@wire(getRecord, { recordId: '$recordId', fields: fields })
    getCustomerDataWired({ error, data }) {
        this.isLoading = true;
        if (error) {
			console.error(error);
			this.data = null;
			this.isLoading = false;
			this.dispatchEvent(
				new ShowToastEvent({
					title: "Error",
					message: error.message,
					variant: "error"
				})
			);
        }
        if (data) {
			this.data = data;
			let requestBody = getFieldValue(data, REQUEST_BODY);
			let responseBody = getFieldValue(data, RESPONSE_BODY);
			try {
				this.requestBody = JSON.stringify(JSON.parse(requestBody),undefined,4);
			}
			catch(e) {
				console.error(e);
				this.requestBody = requestBody;
			}
			try {
				this.responseBody = JSON.stringify(JSON.parse(responseBody),undefined,4);
			}
			catch(e) {
				console.error(e);
				this.responseBody = responseBody;
			}
			this.isLoading = false;
        }
    }
}