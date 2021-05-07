public class IntegrationLogUtility {
    @testVisible
    private static Boolean testFutureMethod = false;

    public enum Module {
        Siebel,
        SAP
    }

    public enum Direction {
        Inbound,
        Outbound
    }

    public enum Method {
        GET,
        POST,
        PUT,
        PATCH
    }

    @future
    public static void createLogAsync(String module, String direction, String endpoint, String method, String requestBody, String responseBody, Integer responseStatusCode, String errorMessage) {
        publishLog(module, direction, endpoint, method, requestBody, responseBody, responseStatusCode, errorMessage);
    }

    public static void createLogSync(String module, String direction, String endpoint, String method, String requestBody, String responseBody, Integer responseStatusCode, String errorMessage) {
        publishLog(module, direction, endpoint, method, requestBody, responseBody, responseStatusCode, errorMessage);
    }

    public static void createLog(String module, String direction, String endpoint, String method, String requestBody, String responseBody, Integer responseStatusCode, String errorMessage) {
        if(!System.isFuture() && !testFutureMethod)
            createLogAsync(module, direction, endpoint, method, requestBody, responseBody, responseStatusCode, errorMessage);
        else {
            createLogSync(module, direction, endpoint, method, requestBody, responseBody, responseStatusCode, errorMessage);
        }
    }

    public static Integration_Log_Event__e newLog(String module, String direction) {
        Integration_Log_Event__e e = new Integration_Log_Event__e (
            Module__c = module,
			Direction__c = direction,
			Start_Time__c = DateTime.now()
        );

        return e;
    }

    public static void includeHttpRequest(Integration_Log_Event__e e, HttpRequest request) {
        e.Endpoint__c = request.getEndpoint();
        e.Method__c = request.getMethod();
        e.Request_Body__c = request.getBody();
        //e.Request_Headers__c = request.
        e.Request_Agent__c = request.getHeader('User-Agent');
    }

    public static void includeHttpResponse(Integration_Log_Event__e e, HttpResponse response) {
        e.Response_StatusCode__c = String.valueOf(response.getStatusCode());
        e.Response_Body__c = response.getBody();
    }

    public static void includeRestContext(Integration_Log_Event__e e) {
		if(RestContext.request != null) {
			e.Endpoint__c = RestContext.request.requestURI;
			e.Method__c = RestContext.request.httpMethod;
			e.Request_Body__c = RestContext.request.requestBody != null ? RestContext.request.requestBody.toString().left(131072) : null;
			if(RestContext.request.headers != null) {
				e.Request_Agent__c = RestContext.request.headers.get('User-Agent');
				String headers = '';
				for(String headerKey : RestContext.request.headers.keySet()) {
					headers += headerKey + ' = ' + RestContext.request.headers.get(headerKey) + '\r\n';
				}
				e.Request_Headers__c = headers;
			}
		}
		if(RestContext.response != null) {
			e.Response_StatusCode__c = String.valueOf(RestContext.response.statusCode);
			e.Response_Body__c = RestContext.response.responseBody != null ? RestContext.response.responseBody.toString().left(131072) : null;
		}
    }

    private static List<Integration_Log_Event__e> logs = new List<Integration_Log_Event__e>();

    public static void publishLogs(List<Integration_Log_Event__e> e) {
        for(Integration_Log_Event__e event : e){
            event.End_Time__c = Datetime.now();
            event.Duration__c = event.Start_Time__c != null ? event.End_Time__c.getTime() - event.Start_Time__c.getTime() : null;
        }
        EventBus.publish(e);
    }

    public static void publishLog(Integration_Log_Event__e e) {
        e.End_Time__c = Datetime.now();
        e.Duration__c = e.Start_Time__c != null ? e.End_Time__c.getTime() - e.Start_Time__c.getTime() : null;
        publishLog(e, false);
    }

    public static void publishLog(Integration_Log_Event__e e, Boolean differ) {
		if(String.isBlank(e.Request_Id__c)) e.Request_Id__c = System.Request.getCurrent().getRequestId();
		if(String.isBlank(e.Quiddity__c)) e.Quiddity__c = String.valueOf(System.Request.getCurrent().getQuiddity());
        e.End_Time__c = Datetime.now();
        e.Duration__c = e.Start_Time__c != null ? e.End_Time__c.getTime() - e.Start_Time__c.getTime() : null;
        if(e.Endpoint__c != null && e.Endpoint__c.length() > 255) {
			e.Request_Body__c = e.Endpoint__c + (e.Request_Body__c == null ? '' : ('\r\n\r\n' + e.Request_Body__c));
			e.Endpoint__c = e.Endpoint__c.substring(0,255);
		}
        if(e.Request_Body__c != null && e.Request_Body__c.length() > 131072) e.Request_Body__c = e.Request_Body__c.substring(0,131072);
        if(e.Response_Body__c != null && e.Response_Body__c.length() > 131072) e.Response_Body__c = e.Response_Body__c.substring(0,131072);
        if(e.Error_Message__c != null && e.Error_Message__c.length() > 131072) e.Error_Message__c = e.Error_Message__c.substring(0,131072);
        if(e.Origin_Data__c != null && e.Origin_Data__c.length() > 131072) e.Origin_Data__c = e.Origin_Data__c.substring(0,131072);
        if(differ) {
            logs.add(e);
        }
        else {
            EventBus.publish(e);
        }
    }

    public static void publishPending() {
        if(!logs.isEmpty()) EventBus.publish(logs);
    }

    private static void publishLog(String module, String direction, String endpoint, String method, String requestBody, String responseBody, Integer responseStatusCode, String errorMessage) {
        Integration_Log_Event__e e = new Integration_Log_Event__e (
            Module__c = module,
            Endpoint__c = endpoint,
            Method__c = method,
            Direction__c = direction,
            Request_Body__c = requestBody,
            Response_Body__c = responseBody,
            Response_StatusCode__c = String.valueOf(responseStatusCode),
            Error_Message__c = errorMessage
        );

        EventBus.publish(e);
    }

    @InvocableMethod(label='Retry Integration' description='Retry Integration')
    public static void retryIntegration(List<String> recordId) {

            List<Integration_Log__c> integration = [SELECT Origin_Data__c
            FROM Integration_Log__c WHERE ID=:recordId];

            if(integration.isEmpty()) return;
            if(integration[0].Origin_Data__c == null) return;

            List<SObject> eventsToPublish = new List<SObject>();
            String jsonStr = integration[0].Origin_Data__c;
            eventsToPublish = (List<SObject>)JSON.deserialize(integration[0].Origin_Data__c, List<SObject>.class);

            if(eventsToPublish.isEmpty()) return;

            EventBus.publish(eventsToPublish);

    }

    public static void saveIntegrationLogs(List<Integration_Log_Event__e> integrationLogEvents) {
        Map<String,Integration_Log_Setting__mdt> moduleToSettings = getSettingsByModule();

        List<Integration_Log__c> integrationLogs = new List<Integration_Log__c>();

		Map<String,Id> requestIdToIntegrationLogId = new Map<String,Id>();
		Set<String> requestIds = new Set<String>();
		for(Integration_Log_Event__e e : integrationLogEvents) {
			if(String.isNotBlank(e.Parent_Request_Id__c)) requestIds.add(e.Parent_Request_Id__c);
		}
		if(!requestIds.isEmpty()) {
			List<Integration_Log__c> logs = [select Id,Request_Id__c from Integration_Log__c where Request_Id__c in :requestIds];
			for(Integration_Log__c log : logs) {
				requestIdToIntegrationLogId.put(log.Request_Id__c, log.Id);
			}
		}

        for(Integration_Log_Event__e e : integrationLogEvents) {
            String module = String.isBlank(e.Module__c) ? '*' : e.Module__c;
            Integration_Log_Setting__mdt setting = moduleToSettings.get(module);
            if(setting == null) {
                setting = moduleToSettings.get('*');
            }
            if(setting == null) continue;

            if(String.isBlank(e.Error_Message__c) && !setting.Log_Success__c) continue;

			Id parentLogId = null;
			if(String.isNotBlank(e.Parent_Request_Id__c)) parentLogId = requestIdToIntegrationLogId.get(e.Parent_Request_Id__c);

            Integration_Log__c log = convertLog(e, parentLogId);
            integrationLogs.add(log);
        }

        if(!integrationLogs.isEmpty()) {
            insert integrationLogs;
        }
    }

    private static Integration_Log__c convertLog(Integration_Log_Event__e eventLog, Id parentLogId) {
        return new Integration_Log__c(
            Module__c = eventLog.Module__c,
            Endpoint__c = eventLog.Endpoint__c,
            Method__c = eventLog.Method__c,
            Direction__c = eventLog.Direction__c,
            Request_Body__c = eventLog.Request_Body__c,
            Response_Body__c = eventLog.Response_Body__c,
            Request_Headers__c = eventLog.Request_Headers__c,
            Request_Agent__c = eventLog.Request_Agent__c,
            Response_StatusCode__c = eventLog.Response_StatusCode__c,
            Error_Message__c = eventLog.Error_Message__c,
            Successful__c = String.isBlank(eventLog.Error_Message__c),
            Origin_Data__c = eventLog.Origin_Data__c,
            End_Time__c = eventLog.End_Time__c,
            Start_Time__c = eventLog.Start_Time__c,
            Duration__c = eventLog.Duration__c,
			Request_Id__c = eventLog.Request_Id__c,
			Quiddity__c = eventLog.Quiddity__c,
			Retry_Number__c = eventLog.Retry_Number__c,
			Parent_Integration_Log__c = parentLogId
        );
    }

    public static String buildIntegrationLogExpirationQuery() {
        List<Integration_Log_Setting__mdt> settings = selectSettingsForExpirations();

        String whereCondition = 'WHERE ';

        List<String> modules = new List<String>();
        String soqlDateForGeneral = null;

        for(Integration_Log_Setting__mdt setting : settings) {
            Integer expirationDays = Test.isRunningTest() ? -10 : Integer.valueOf(setting.Expiration_Days__c);
            expirationDays -= 1;

            Date paramDate = Date.today().addDays(-1 * expirationDays);
            DateTime dt = Datetime.newInstance(paramDate.Year(), paramDate.Month(), paramDate.Day());
            String soqlDate = dt.format('YYYY-MM-dd\'T\'hh:mm:ss\'Z\'');

            if(String.isBlank(setting.Module__c)) {
                soqlDateForGeneral = soqlDate;
                continue;
            }

            modules.add(setting.Module__c);

            String currentCondition = '(Module__c = \'' + setting.Module__c + '\' AND ';
            currentCondition += 'CreatedDate < ' + soqlDate;
            currentCondition += ') OR ';

            whereCondition += currentCondition;
        }

        if(soqlDateForGeneral != null) {
            String currentCondition = '(Module__c not in (\'' + String.join(modules,'\',\'') + '\') AND ';
            currentCondition += 'CreatedDate < ' + soqlDateForGeneral;
            currentCondition += ') OR ';

            whereCondition += currentCondition;
        }

        if(whereCondition.endsWith('OR '))
            whereCondition = whereCondition.removeEnd('OR ');
        else // no settings were found
            whereCondition += 'Id = null'; // do not return anything

        String result = 'select Id from Integration_Log__c ' + whereCondition;

        return result;
    }

    private static Map<String,Integration_Log_Setting__mdt> getSettingsByModule() {
        Map<String,Integration_Log_Setting__mdt> moduleToSetting = new Map<String,Integration_Log_Setting__mdt>();

        for(Integration_Log_Setting__mdt setting : selectSettings()) {
            String module = setting.Module__c;
            if(String.isBlank(module)) module = '*';
            moduleToSetting.put(module,setting);
        }

        return moduleToSetting;
    }

    // SELECTORS

    private static List<Integration_Log_Setting__mdt> selectSettings() {
        return [
            select
                Id,
                Module__c,
                Log_Success__c
            from
                Integration_Log_Setting__mdt
            where
                Disabled__c = false
        ];
    }

    private static List<Integration_Log_Setting__mdt> selectSettingsForExpirations() {
        
        return Test.isRunningTest()? [select Id,Expiration_Days__c,Module__c from Integration_Log_Setting__mdt] : [
            select
                Id,
                Expiration_Days__c,
                Module__c
            from
                Integration_Log_Setting__mdt
            where
                Expires__c = true and
                Expiration_Days__c != null and
                Disabled__c = false
        ];
    }
}