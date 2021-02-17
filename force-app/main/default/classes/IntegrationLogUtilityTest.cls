@isTest
private class IntegrationLogUtilityTest {

    @testSetup
    private static void setup() {

    }

    @isTest
    private static void testOutbound() {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('callou:Postman_Echo/post');
        request.setHeader('Content-Type','application/json');
        request.setBody('{"name": "Giovanni"}');
        HttpResponse response = new HttpResponse();

		Test.startTest();

        Integer randomNumberForModule = Integer.valueof((math.random() * 10));
        List<String> modules = new List<String> { 'Salesforce'};
        String requestModule = modules[Math.mod(randomNumberForModule,modules.size())];
        Integration_Log_Event__e log = IntegrationLogUtility.newLog(requestModule,String.valueOf(IntegrationLogUtility.Direction.Outbound));

        IntegrationLogUtility.includeHttpRequest(log, request);
        IntegrationLogUtility.includeHttpResponse(log, response);
        IntegrationLogUtility.publishLog(log);

        Test.stopTest();
    }

	@isTest
    private static void testInbound() {
        RestRequest request = new RestRequest();
		RestResponse response = new RestResponse();
		request.httpMethod = 'GET';
		request.requestUri = '/customers';
		RestContext.request = request;
		RestContext.response = response;

        Test.startTest();

        Integer randomNumberForModule = Integer.valueof((math.random() * 10));
        List<String> modules = new List<String> { 'Salesforce'};
        String requestModule = modules[Math.mod(randomNumberForModule,modules.size())];
        Integration_Log_Event__e log = IntegrationLogUtility.newLog(requestModule,String.valueOf(IntegrationLogUtility.Direction.Inbound));

		IntegrationLogUtility.includeRestContext(log);
		IntegrationLogUtility.publishLog(log);

        Test.stopTest();
    }

	@isTest
    private static void testExpierationQuery() {
		Test.startTest();

        String query = IntegrationLogUtility.buildIntegrationLogExpirationQuery();

        Test.stopTest();
	}

	@isTest
    private static void testRetry() {
		Integer randomNumberForModule = Integer.valueof((math.random() * 10));
        List<String> modules = new List<String> { 'Salesforce'};
        String requestModule = modules[Math.mod(randomNumberForModule,modules.size())];

		Integration_Log__c log = new Integration_Log__c(
			Module__c = requestModule,
			Origin_Data__c = JSON.serialize(new List<Integration_Log_Event__e> { new Integration_Log_Event__e(Module__c = requestModule) })
		);
		insert log;

		Test.startTest();

        IntegrationLogUtility.retryIntegration(new List<String> { log.Id });

        Test.stopTest();
	}

    @isTest
    private static void testOthers() {
        Test.startTest();

        Integer randomNumberForModule = Integer.valueof((math.random() * 10));
        List<String> modules = new List<String> { 'Salesforce'};
        String requestModule = modules[Math.mod(randomNumberForModule,modules.size())];
        Integration_Log_Event__e log = IntegrationLogUtility.newLog(requestModule,String.valueOf(IntegrationLogUtility.Direction.Outbound));

        IntegrationLogUtility.publishLog(log);
        IntegrationLogUtility.createLogAsync('','','','','','',200,'');
        IntegrationLogUtility.createLogSync('','','','','','',200,'');

        Test.stopTest();
    }
}