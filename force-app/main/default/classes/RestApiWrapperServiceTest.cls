@isTest
global class RestApiWrapperServiceTest {
    @testSetup
    private static void setup() {

    }

    @isTest
    private static void testHttpPost() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new RestApiWrapperHttpMock());
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/rest/';
        RestContext.request = req; 
        RestContext.response= res;
        Test.startTest();
        RestApiWrapperService.httpPost();
        Test.stopTest();
        System.assertEquals(RestContext.response.responseBody.toString(),'successful execution');
    }

    @isTest
    private static void testHttpPatch() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new RestApiWrapperHttpMock());
        req.httpMethod = 'PATCH';
        req.requestUri = '/services/apexrest/rest/';
        RestContext.request = req; 
        RestContext.response= res;
        Test.startTest();
        RestApiWrapperService.httpPatch();
        Test.stopTest();
        System.assertEquals(RestContext.response.responseBody.toString(),'successful execution');
    }

    @isTest
    private static void testHttpGetWithResponseError() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new RestApiWrapperHttpMock());
        //req.addHeader('httpMethod', 'POST');
        req.httpMethod = 'GET';
        req.requestUri = '/services/apexrest/rest/';
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        RestApiWrapperService.httpGet();
        Test.stopTest();
        System.assertEquals(RestContext.response.statusCode,400);
    }

    @isTest
    private static void testHttpPutWithExceptionError() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.httpMethod = 'PUT';
        req.requestUri = '/services/apexrest/rest/';
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        RestApiWrapperService.httpPut();
        Test.stopTest();
        System.assertEquals(RestContext.response.statusCode,500);
    }

    @isTest
    private static void testHttpDeleteWithHeader() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new RestApiWrapperHttpMock());
        req.httpMethod = 'PUT';
        req.requestUri = '/services/apexrest/rest/';
        req.addHeader('TestHeader','Test header value');
        RestContext.request = req;
        RestContext.response= res;
        Test.startTest();
        RestApiWrapperService.httpDelete();
        Test.stopTest();
        System.assertEquals(RestContext.response.responseBody.toString(),'successful execution');
    }

    global class RestApiWrapperHttpMock implements HttpCalloutMock {

        global HTTPResponse respond(HTTPRequest req) {

            HttpResponse resp=new HttpResponse();

            switch on req.getMethod(){

                when 'GET'{
                    resp.setHeader('TEST', 'Test RestApiWrapperService');
                    resp.setBody('[{"errorCode":"200","message": "error test","stackTrace":"test wrapper"}]');
                    resp.setStatusCode(400);
                }
                when else{
                    resp.setHeader('TEST', 'Test RestApiWrapperService');
                    resp.setBody('successful execution');
                    resp.setStatusCode(200);
                }
            }
            return resp;
        }
    }

}