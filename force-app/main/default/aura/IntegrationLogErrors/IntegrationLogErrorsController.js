({
	onInit : function(component, event, helper) {
		if(window.integrationLogMonitorErrorsSubscribed) {
			console.log('already subscribed... unsubscribing');
			helper.unsubscribe(component, window.integrationLogMonitorErrorsSubscribed);
		}
		helper.subscribe(component);
	},

	onTabClosed: function(component, event, helper) {
		helper.unsubscribe(component);
	},

    onToggleExpand : function(component, event, helper) {
        var id = event.srcElement.getAttribute("data-id");
        var errors = component.get("v.errors");
        for(var i = 0; i < errors.length; i++) {
            if(errors[i].Id == id) {
                errors[i].expanded = !errors[i].expanded;
                break;
            }
        }
        component.set("v.errors", errors);
    },

    onDelete : function(component, event, helper) {
        component.set("v.errors", []);
    }

})