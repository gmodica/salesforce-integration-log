import { LightningElement, track } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class IntegrationLogErrorsChart extends LightningElement {
	label = {
		cardTitle: "Integration Log Errors",
		clear: "Clear",
		toggleDetails: "Show/Hide details"
	};

	rendered;
    channelName = '/event/Integration_Log_Event__e';
    subscription = {};
	chart;
	@track errors = [];

    connectedCallback() {
        this.registerForEvents();
    }

	disconnectedCallback() {
		this.unregisterForEvents();
	}

	registerForEvents() {
        const messageCallback = (eventReceived) => {
			console.log('Received event ', JSON.stringify(eventReceived));

			this.addError(eventReceived.data.payload, eventReceived.data.event);
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
        });
		onError(error => {
            console.error('EMP API error: ', error);
        });
	}

	unregisterForEvents() {
		console.log('unsubscribing');
        unsubscribe(this.subscription, response => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
        });
    }

	clear() {
        this.errors = [];
	}

	addError(payload, event) {
        try {
			if(!payload.Error_Message__c) return;

			payload.Id = event.replayId;

			this.errors.unshift(payload);
		}
		catch(error) {
			console.error(error);
		}
	}

	toggleDetails(event) {
		const id = event.currentTarget.dataset.id;
		const element = this.template.querySelector(`div[data-id="${id}"`);
		element.classList.toggle("slds-is-open");

		event.target.iconName = event.target.iconName == "utility:chevrondown" ? "utility:chevronright" : "utility:chevrondown";
	}
}