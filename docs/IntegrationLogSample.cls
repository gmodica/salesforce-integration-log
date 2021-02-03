@RestResource(urlMapping='/integration-log/*')
global class IntegrationLogServiceSample {
    public static final String MODULE = 'Test';

    // INBOUND

    @HttpPost
    global static void post() {
        Integer randomNumberForFailure = Integer.valueof((math.random() * 10));
        Boolean fail = Math.mod(randomNumberForFailure,2) == 0 ? true : false;

        Integer randomNumberForModule = Integer.valueof((math.random() * 10));
        List<String> modules = new List<String> { 'SAP', 'Siebel', 'Odoo', 'Prestashop'};
        String requestModule = modules[Math.mod(randomNumberForModule,modules.size())];


        Integration_Log_Event__e log = IntegrationLogUtility.newLog(requestModule,String.valueOf(IntegrationLogUtility.Direction.Inbound));

        try {
            Request request = (Request)JSON.deserialize(RestContext.request.requestBody.toString(), Request.class);

            RestContext.response.headers.put('Content-Type','application/json');
            if(fail) {
                RestContext.response.statusCode = 400;
                RestContext.response.responseBody = Blob.valueOf('{"error": "Something is wrong"}');
                throw new IntegrationLogServiceException('Failed');
            }
            else {
                RestContext.response.statusCode = 200;
                RestContext.response.responseBody = Blob.valueOf('{"result": "ok"}');
            }
        }
        catch(Exception e) {
            String error = e.getMessage() + '\r\n' + e.getStackTraceString();
            System.debug(error);
            log.Error_Message__c = error;
        }
        finally {
            IntegrationLogUtility.includeRestContext(log);
            IntegrationLogUtility.publishLog(log);
        }
    }

    public class Request {
        public String info {get; set;}
    }

    // OUTBOUND

    public static void SimulateOutboundSuccessCall() {
        Integration_Log_Event__e log = IntegrationLogUtility.newLog(MODULE,String.valueOf(IntegrationLogUtility.Direction.Outbound));
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint('callou:Postman_Echo/post');
            request.setHeader('Content-Type','application/json');
            request.setBody('{"name": "Giovanni"}');
            IntegrationLogUtility.includeHttpRequest(log, request);
            HttpResponse response = http.send(request);
            IntegrationLogUtility.includeHttpResponse(log, response);

            if(response.getStatusCode() != 200) {
                throw new IntegrationLogServiceException('Failed. Status: ' + response.getStatus());
            }
        }
        catch(Exception e) {
            String error = e.getMessage() + '\r\n' + e.getStackTraceString();
            System.debug(error);
            log.Error_Message__c = error;
        }
        finally {
            IntegrationLogUtility.publishLog(log);
        }
    }

    public static void SimulateOutboundErrorCall() {
        Integration_Log_Event__e log = IntegrationLogUtility.newLog(MODULE,String.valueOf(IntegrationLogUtility.Direction.Outbound));
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setEndpoint('callou:Postman_Echo/basic-auth');
            request.setHeader('Content-Type','application/json');
            IntegrationLogUtility.includeHttpRequest(log, request);
            HttpResponse response = http.send(request);
            IntegrationLogUtility.includeHttpResponse(log, response);

            if(response.getStatusCode() != 200) {
                throw new IntegrationLogServiceException('Failed. Status: ' + response.getStatus());
            }
        }
        catch(Exception e) {
            String error = e.getMessage() + '\r\n' + e.getStackTraceString();
            System.debug(error);
            log.Error_Message__c = error;
        }
        finally {
            IntegrationLogUtility.publishLog(log);
        }
    }

    public class IntegrationLogServiceException extends Exception {}
}