@isTest
private class IntegrationLogUtilityTest {

    @testSetup
    private static void setup() {

    }

    @isTest
    private static void test() {
        Test.startTest();

        Integer randomNumberForModule = Integer.valueof((math.random() * 10));
        List<String> modules = new List<String> { 'Verifiable'};
        String requestModule = modules[Math.mod(randomNumberForModule,modules.size())];
        Integration_Log_Event__e log = IntegrationLogUtility.newLog(requestModule,String.valueOf(IntegrationLogUtility.Direction.Inbound));

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('callou:Postman_Echo/post');
        request.setHeader('Content-Type','application/json');
        request.setBody('{"name": "Giovanni"}');

        IntegrationLogUtility.includeHttpRequest(log, request);
        HttpResponse response = new HttpResponse();
        IntegrationLogUtility.includeHttpResponse(log, response);
        IntegrationLogUtility.publishLog(log);
        IntegrationLogUtility.createLogAsync('','','','','','',200,'');
        IntegrationLogUtility.createLogSync('','','','','','',200,'');

        String aux1 = IntegrationLogUtility.buildIntegrationLogExpirationQuery();

        Test.stopTest();
    }
}