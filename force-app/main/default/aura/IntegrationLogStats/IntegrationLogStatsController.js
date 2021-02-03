({
	onInit : function(component, event, helper) {
		if(window.integrationLogMonitorStatsSubscribed) {
			console.log('already subscribed... unsubscribing');
			helper.unsubscribe(component, window.integrationLogMonitorStatsSubscribed);
		}
		helper.subscribe(component);
	},

	onTabClosed: function(component, event, helper) {
		helper.unsubscribe(component);
	},

    onDelete : function(component, event, helper) {
        var config = helper.chartLogs.config;
        config.data.labels = [];
        config.data.datasets[0].data = [];
        config.data.datasets[1].data = [];
        helper.chartLogs.update();
    },

    onScriptsLoaded : function(component, event, helper) {
        Chart.plugins.unregister(ChartDataLabels);

        var color = Chart.helpers.color;
        var chartColors = {
            red: 'rgb(255, 99, 132)',
            orange: 'rgb(255, 159, 64)',
            yellow: 'rgb(255, 205, 86)',
            green: 'rgb(75, 192, 192)',
            blue: 'rgb(54, 162, 235)',
            purple: 'rgb(153, 102, 255)',
            grey: 'rgb(201, 203, 207)'
        };

        var config = {
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

        var ctxLogs = document.getElementById('chartLogs').getContext('2d');
		helper.chartLogs = new Chart(ctxLogs, config);
    }
})