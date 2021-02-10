@RestResource(urlMapping='/rest/*') 
global class RestApiWrapperService {
    @HttpPatch
    global static void httpPatch() {
        processRequest();
    }

    @HttpPost
    global static void httpPost() {
        processRequest();
    }

    @HttpGet
    global static void httpGet() {
        processRequest();
    }

    @HttpPut
    global static void httpPut() {
        processRequest();
    }

    @HttpDelete
    global static void httpDelete() {
        processRequest();
    }

    private static void processRequest() {
        Integration_Log_Event__e log = IntegrationLogUtility.newLog('Wrapper',String.valueOf(IntegrationLogUtility.Direction.Inbound));

        try {
            RequestUri parsedUri = new RequestUri().parse(RestContext.request.requestUri);

            log.Module__c = parsedUri.module.capitalize();

            String endpoint = Url.getSalesforceBaseUrl().toExternalForm() + parsedUri.apiUri;

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod(RestContext.request.httpMethod);
            if(RestContext.request.requestBody != null) request.setBody(RestContext.request.requestBody.toString());
            for(String key : RestContext.request.headers.keySet()) {
                if(key.startsWith('X-Salesforce')) continue;
                request.setHeader(key, RestContext.request.headers.get(key));
            }
            request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());

            HttpResponse response = http.send(request);

            RestContext.response.responseBody = response.getBodyAsBlob();
//            Blob.valueOf(response.getBody());
            RestContext.response.statusCode = response.getStatusCode();
            for(String key : response.getHeaderKeys()) {
                System.debug(key + '=' + response.getHeader(key));
                RestContext.response.headers.put(key, response.getHeader(key));
            }

            if(!String.valueOf(response.getStatusCode()).startsWith('2') || response.getBody().contains('"success":false') || response.getBody().contains('"isSuccessful":false')) {
				List<Error> errors = null;
                try {
					errors = (List<Error>)JSON.deserialize(response.getBody(), List<Error>.class);
				}
				catch(Exception e) {
				}
                log.Error_Message__c = errors == null || errors.isEmpty() || String.isBlank(errors[0].message) ? 'Some errors occurred' :  errors[0].message;
            }
        }
        catch(Exception e) {
            String error = e.getMessage() + '\r\n' + e.getStackTraceString();
            System.debug(error);
            convertExceptionToResponse(e);
            log.Error_Message__c = error;
        }
        finally {
            IntegrationLogUtility.includeRestContext(log);
            IntegrationLogUtility.publishLog(log);
        }
    }

    private static void convertExceptionToResponse(Exception e) {
        Error err = new Error(e);
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.statusCode = 500;
        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(new List<Error> { err }));
    }

    private class RequestUri {
        public String apiUri {get; set;}
        public String module {get; set;}

        public RequestUri parse(String requestUri) {
            if(String.isBlank(requestUri)) return this;
            String uri = requestUri.startsWith('/') ? requestUri.substring(1) : requestUri;

            String[] requestUriParts = uri.split('/');
            if(requestUriParts.size() > 1) module = requestUriParts[1];

            if(String.isBlank(module)) throw new WebServiceException('No module specified in request URI');

            this.apiUri = requestUri.replace(requestUriParts[0] + '/' + requestUriParts[1],'');

            return this;
        }
    }

    private class Error {
        public String errorCode {get; set;}
        public String message {get; set;}
        public String stackTrace {get; set;}

        public Error(String message, String stackTrace) {
            this.message = message;
            this.stackTrace = stackTrace;
        }

        public Error(Exception e) {
            this.message = e.getMessage();
            this.stackTrace = e.getStackTraceString();
        }
    }

    private class WebServiceException extends Exception {}
}
