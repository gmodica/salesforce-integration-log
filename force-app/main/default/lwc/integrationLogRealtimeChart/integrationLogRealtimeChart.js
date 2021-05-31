import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import CHARTJS from '@salesforce/resourceUrl/ChartJSWithStreaming';

export default class IntegrationLogChart extends LightningElement {
	label = {
		cardTitle: "Integration Log Realtime Chart"
	};

	rendered;
	events = {};
    channelName = '/event/Integration_Log_Event__e';
    subscription = {};
	chart;

    connectedCallback() {
        this.registerForEvents();
    }

	disconnectedCallback() {
		this.unregisterForEvents();
	}

	async renderedCallback() {
        if (this.rendered) {
            return;
        }
        this.rendered = true;

		try {
			await loadScript(this, CHARTJS + '/moment.min.js');
			await loadScript(this, CHARTJS + '/chart.js');
			await loadScript(this, CHARTJS + '/chartjs-plugin-streaming.js');

			this.initializeCharJS();
		}
		catch(error) {
			console.error(error);
			this.dispatchEvent(
				new ShowToastEvent({
					title: 'Error loading ChartJS',
					message: error,
					variant: 'error'
				})
			);
		}
    }

	registerForEvents() {
        const messageCallback = (eventReceived) => {
			//console.log('Received event ', JSON.stringify(eventReceived));

			const moduleName = eventReceived.data.payload.Module__c;
			this.addDataset(moduleName);

			if(!this.events[moduleName]) this.events[moduleName] = [];
			this.events[moduleName].push(eventReceived.data.payload);
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

	initializeCharJS() {
		Chart.plugins.unregister(ChartStreaming);

		const onRefresh = chart => {
			try {
				if(!this.events) return;

				chart.config.data.datasets.forEach(dataset => {
					const moduleEvents = this.events[dataset.label];
					if(!moduleEvents) {
						return;
					}

					const data = new Map();
					moduleEvents.forEach(payload => {
						if(!data.get(payload.CreatedDate)) data.set(payload.CreatedDate,0);
						data.set(payload.CreatedDate,data.get(payload.CreatedDate)+1);
					});

					moduleEvents.forEach(payload => {
						let y = data.get(payload.CreatedDate);
						if(!y) y = 1;
						dataset.data.push({
							x: payload.CreatedDate,
							y: y,
							r: y * 10,
							error: payload.Error_Message__c || 'OK'
						});
					});
				});
				this.events = {};
			}
			catch(error) {
				console.error(error);
			}
        };

        const config = {
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

        const ctx = this.template.querySelector('canvas').getContext('2d');
		this.chart = new Chart(ctx, config);
	}

	addDataset(moduleName) {
        try {
			const config = this.chart.config;
			let datasetExists = false;
			config.data.datasets.forEach(function(dataset) {
				if(dataset.label == moduleName) {
					datasetExists = true;
					return;
				}
			})
			if(datasetExists) return;

			const color = Chart.helpers.color;
			const chartColors = {
				red: 'rgb(255, 99, 132)',
				blue: 'rgb(54, 162, 235)',
				orange: 'rgb(255, 159, 64)',
				purple: 'rgb(153, 102, 255)',
				yellow: 'rgb(255, 205, 86)',
				green: 'rgb(75, 192, 192)',
				grey: 'rgb(201, 203, 207)'
			};
			const colorNames = Object.keys(chartColors);

			const colorName = colorNames[config.data.datasets.length % colorNames.length];
			const newColor = chartColors[colorName];
			const newDataset = {
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
		catch(error) {
			console.error(error);
		}
	}
}