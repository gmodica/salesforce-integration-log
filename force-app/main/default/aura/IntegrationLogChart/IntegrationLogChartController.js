({
	// Sets an empApi error handler on component initialization
    onInit : function(component, event, helper) {
		if(window.integrationLogMonitorChartSubscribed) {
			console.log('already subscribed... unsubscribing');
			helper.unsubscribe(component, window.integrationLogMonitorChartSubscribed);
		}
		helper.subscribe(component);
	},

	onTabClosed: function(component, event, helper) {
		helper.unsubscribe(component);
	},

    onScriptsLoaded : function(component, event, helper) {
        Chart.plugins.unregister(ChartStreaming);

        var onRefresh = $A.getCallback(function(chart) {
            var events = component.get("v.events");
            if(!events) return;

            chart.config.data.datasets.forEach(function(dataset) {
                var moduleEvents = events[dataset.label];
                if(!moduleEvents) {
                    /*dataset.data.push({
                        x: Date.now(),
                        y: 0
                    });*/
                    return;
                }

                var data = new Map();
                moduleEvents.forEach(function(payload) {
                    if(!data.get(payload.CreatedDate)) data.set(payload.CreatedDate,0);
                    data.set(payload.CreatedDate,data.get(payload.CreatedDate)+1);
                });

                /*data.forEach(function(value,key) {
                	dataset.data.push({
                        x: key,
                        y: value,
                        r: value * 10,
                        error: 'Error'
                    });
                });*/

				moduleEvents.forEach(function(payload) {
                    var y = data.get(payload.CreatedDate);
                    if(!y) y = 1;
                    dataset.data.push({
                        x: payload.CreatedDate,
                        y: y,
                        r: y * 10,
                        error: payload.Error_Message__c || 'OK'
                    });
                });
            });
            component.set("v.events",{});
        })

        var color = Chart.helpers.color;
        var config = {
            plugins: [ChartStreaming],
            type: 'bubble',
            data: {
                labels: [],
                datasets: []
            },
            options: {
                title: {
                    display: true,
                    text: 'Integration Log Errors',
                    position: 'bottom'
                },
                legend: {
                    display: true,
                    position: 'bottom'
                },
                scales: {
                    xAxes: [{
                        type: 'realtime',
                        realtime: {
                            duration: 60000,
                            refresh: 1000,
                            delay: 1000,
                            onRefresh: onRefresh
                        }
                    }],
                    yAxes: [{
                        type: 'linear',
                        displaye: true,
                        scaleLabel: {
                            display: true,
                            labelString: 'value'
                        },
                        ticks: {
                            suggestedMin: 0,
                            suggestedMax: 10
                        }
                    }]
                },
                tooltips: {
                    mode: 'nearest',
                    intersect: false,
                    callbacks: {
                        label: function(tooltipItem, data) {
                            var label = data.datasets[tooltipItem.datasetIndex].label || '';

                            if (label) {
                                label += ': ';
                            }
                            label += data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index].error;
                            return label;
                        }
                    }
                },
                hover: {
                    mode: 'nearest',
                    intersect: false
                },
                plugins: {
                    datalabels: {
                        backgroundColor: function(context) {
                            return context.dataset.backgroundColor;
                        },
                        borderRadius: 4,
                        clip: true,
                        color: 'white',
                        font: {
                            weight: 'bold'
                        },
                        formatter: function(value) {
                            return value.error;
                        }
                    }
                }
            }
        };

        var ctx = document.getElementById('chart').getContext('2d');
		helper.chart = new Chart(ctx, config);
    }
})