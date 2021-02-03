({
	chart: null,

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

				//if(!eventReceived.data.payload.Error_Message__c) return;

				var moduleName = eventReceived.data.payload.Module__c;
				$helper.addDataset(component, moduleName);

				var events = component.get("v.events");
				if(!events[moduleName]) events[moduleName] = [];
				events[moduleName].push(eventReceived.data.payload);
				//console.log('Total events: ' + events[moduleName].length);
				component.set("v.events", events);
			}
			catch(e) {
				//console.error(e.message);
				empApi.unsubscribe(window.integrationLogMonitorChartSubscribed, $A.getCallback(unsubscribed => {
					window.integrationLogMonitorChartSubscribed = null;
				}));
			}
        }))
        .then(subscription => {
            // Confirm that we have subscribed to the event channel.
            // We haven't received an event yet.
            console.log('Subscribed to channel ', subscription.channel);
            // Save subscription to unsubscribe later
			component.set('v.subscription', subscription);
			window.integrationLogMonitorChartSubscribed = subscription;
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
			if(!previousSubscription) window.integrationLogMonitorChartSubscribed = null;
        }));
	},

	addDataset : function(component, moduleName) {
        var config = this.chart.config;
        var datasetExists = false;
        config.data.datasets.forEach(function(dataset) {
            if(dataset.label == moduleName) {
				datasetExists = true;
                return;
            }
        })
        if(datasetExists) return;

        var color = Chart.helpers.color;
        var chartColors = {
            red: 'rgb(255, 99, 132)',
            blue: 'rgb(54, 162, 235)',
            orange: 'rgb(255, 159, 64)',
            purple: 'rgb(153, 102, 255)',
            yellow: 'rgb(255, 205, 86)',
            green: 'rgb(75, 192, 192)',
            grey: 'rgb(201, 203, 207)'
        };
        var colorNames = Object.keys(chartColors);

		var colorName = colorNames[config.data.datasets.length % colorNames.length];
        var newColor = chartColors[colorName];
        var newDataset = {
            label: moduleName,
            backgroundColor: color(newColor).alpha(0.5).rgbString(),
            borderColor: newColor,
            borderWidth: 1,
            fill: false,
			cubicInterpolationMode: 'monotone',
            data: []
        };

        config.data.datasets.push(newDataset);
		this.chart.update();
	}
})