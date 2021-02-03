({
	subscribe: function(component) {
		const $helper = this;

		// Get the empApi component
        const empApi = component.find('empApi');

        // Uncomment below line to enable debug logging (optional)
        // empApi.setDebugFlag(true);

        // Register error listener and pass in the error handler function
        empApi.onError($A.getCallback(error => {
            // Error can be any type of error (subscribe, unsubscribe...)
            console.error('EMP API error: ', error);
        }));

        // Get the channel from the input box
        const channel = component.get('v.channel');
        // Replay option to get new events
        const replayId = -1;

        // Subscribe to an event
        empApi.subscribe(channel, replayId, $A.getCallback(eventReceived => {
            try {
				// Process event (this is called each time we receive an event)
            	//console.log('Received event ', JSON.stringify(eventReceived));

				$helper.addError(component, eventReceived.data.payload, eventReceived.data.event);
			}
			catch(e) {
				//console.error(e.message);
				empApi.unsubscribe(window.integrationLogMonitorErrorsSubscribed, $A.getCallback(unsubscribed => {
					window.integrationLogMonitorErrorsSubscribed = null;
				}));
			}
        }))
        .then(subscription => {
            // Confirm that we have subscribed to the event channel.
            // We haven't received an event yet.
            console.log('Subscribed to channel ', subscription.channel);
            // Save subscription to unsubscribe later
			component.set('v.subscription', subscription);
			window.integrationLogMonitorErrorsSubscribed = subscription;
        });
	},

	unsubscribe: function(component, previousSubscription) {
		// Get the empApi component
        const empApi = component.find('empApi');
        // Get the subscription that we saved when subscribing
        const subscription = previousSubscription || component.get('v.subscription');

        // Unsubscribe from event
        empApi.unsubscribe(subscription, $A.getCallback(unsubscribed => {
        	// Confirm that we have unsubscribed from the event channel
			console.log('Unsubscribed from channel '+ unsubscribed.subscription);
			component.set('v.subscription', null);
			if(!previousSubscription) window.integrationLogMonitorErrorsSubscribed = null;
        }));
	},

	addError : function(component, payload, event) {
        if(!payload.Error_Message__c) return;

        payload.expanded = false;
        payload.Id = event.replayId;

        var errors = component.get("v.errors");
        errors.unshift(payload);
        component.set("v.errors", errors);
	}
})