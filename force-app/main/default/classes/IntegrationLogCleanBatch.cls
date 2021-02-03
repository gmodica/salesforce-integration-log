public class IntegrationLogCleanBatch implements Database.Batchable<SObject> {

    public IntegrationLogCleanBatch(){

    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = IntegrationLogUtility.buildIntegrationLogExpirationQuery();
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
        delete scope;
    }

    public void finish(Database.BatchableContext BC){
    }
}