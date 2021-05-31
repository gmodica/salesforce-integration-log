import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import CHARTJS from '@salesforce/resourceUrl/ChartJSWithStreaming';

export default class IntegrationLogStatisticsChart extends LightningElement {
	label = {
		cardTitle: "Integration Log Statistics",
		clear: "Clear"
	};

	rendered;
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
			await loadScript(this, CHARTJS + '/chart.js');
			await loadScript(this, CHARTJS + '/chartjs-plugin-datalabels.min.js');

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

			this.addEvent(eventReceived.data.payload);
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
        Chart.plugins.unregister(ChartDataLabels);

        const color = Chart.helpers.color;

        const chartColors = {
            red: 'rgb(255, 99, 132)',
            orange: 'rgb(255, 159, 64)',
            yellow: 'rgb(255, 205, 86)',
            green: 'rgb(75, 192, 192)',
            blue: 'rgb(54, 162, 235)',
            purple: 'rgb(153, 102, 255)',
            grey: 'rgb(201, 203, 207)'
        };

		const config = {
            plugins: [ChartDataLabels],
            type: 'doughnut',
            data: {
                labels: [],
                datasets: [
                    {
                        label: "Logs",
                        data: [],
                        backgroundColor: [
                            color(chartColors.red).alpha(0.5).rgbString(),
                            color(chartColors.blue).alpha(0.5).rgbString(),
                            color(chartColors.orange).alpha(0.5).rgbString(),
                            color(chartColors.purple).alpha(0.5).rgbString(),
                            color(chartColors.yellow).alpha(0.5).rgbString(),
                            color(chartColors.green).alpha(0.5).rgbString(),
                            color(chartColors.grey).alpha(0.5).rgbString()
                        ],
                        datalabels: {
                            anchor: 'end'
                        }
                    },
                    {
                        label: "Errors",
                        data: [],
                        backgroundColor: [
                            chartColors.red,
                            chartColors.blue,
                            chartColors.orange,
                            chartColors.purple,
                            chartColors.yellow,
                            chartColors.green,
                            chartColors.grey
                        ],
                        datalabels: {
                            anchor: 'start'
                        }
                    }
                ]
            },
            options: {
                responsive: true,
                title: {
                    display: false,
                    text: '',
                    position: 'bottom'
                },
                legend: {
                    display: true,
                    position: 'right'
                },
				animation: {
					animateScale: true,
					animateRotate: true
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
                            label += data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index];
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
						borderColor: 'white',
						borderRadius: 25,
						borderWidth: 2,
						color: 'white',
						display: true,
						font: {
							weight: 'bold'
						},
						formatter: Math.round
					}
				}
            }
        };

        const ctxLogs = this.template.querySelector('canvas').getContext('2d');
		this.chart = new Chart(ctxLogs, config);
	}

	clear() {
        const config = this.chart.config;
        config.data.labels = [];
        config.data.datasets[0].data = [];
        config.data.datasets[1].data = [];
        this.chart.update();
	}

	addEvent(payload) {
        try {
			const config = this.chart.config;
			const moduleName = payload.Module__c;
			let datasetExists = false;
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

			let index = -1;
			config.data.labels.forEach(function(label, i) {
				if(label == moduleName) {
					index = i;
				}
			});
			if(index < 0) return;

			let total = config.data.datasets[0].data[index];
			config.data.datasets[0].data[index] = total + 1;

			if(payload.Error_Message__c) {
				let errors = config.data.datasets[1].data[index];
				config.data.datasets[1].data[index] = errors + 1;
			}

			this.chart.update();
		}
		catch(error) {
			console.error(error);
		}
    }
}