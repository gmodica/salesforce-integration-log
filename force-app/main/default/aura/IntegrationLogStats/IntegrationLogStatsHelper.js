({
	chartLogs: null,

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

				$helper.addEvent(component, eventReceived.data.payload);
			}
			catch(e) {
				//console.error(e.message);
				empApi.unsubscribe(window.integrationLogMonitorStatsSubscribed, $A.getCallback(unsubscribed => {
					window.integrationLogMonitorStatsSubscribed = null;
				}));
			}
        }))
        .then(subscription => {
            // Confirm that we have subscribed to the event channel.
            // We haven't received an event yet.
            console.log('Subscribed to channel ', subscription.channel);
            // Save subscription to unsubscribe later
			component.set('v.subscription', subscription);
			window.integrationLogMonitorStatsSubscribed = subscription;
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

			if(!previousSubscription) window.integrationLogMonitorStatsSubscribed = null;
		}));
	},

	addEvent : function(component, payload) {
        var config = this.chartLogs.config;
        var moduleName = payload.Module__c;
        var datasetExists = false;
        config.data.labels.forEach(function(label) {
            if(label == moduleName) {
				datasetExists = true;
                return;
            }
        });
        if(!datasetExists) {
            config.data.labels.push(moduleName);
            config.data.datasets[0].data.push(0);
            config.data.datasets[1].data.push(0);
        }

        var index = -1;
        config.data.labels.forEach(function(label, i) {
            if(label == moduleName) {
				index = i;
            }
        });
        if(index < 0) return;

        var total = config.data.datasets[0].data[index];
        config.data.datasets[0].data[index] = total + 1;

        if(payload.Error_Message__c) {
            var errors = config.data.datasets[1].data[index];
			config.data.datasets[1].data[index] = errors + 1;
        }

        this.chartLogs.update();
    }
})