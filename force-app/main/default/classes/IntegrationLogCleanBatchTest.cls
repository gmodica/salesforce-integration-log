@isTest
private class IntegrationLogCleanBatchTest {
	@testSetup
    private static void setup() {

        Integration_Log__c intlog = new Integration_Log__c(
            Module__c = 'Verifiable'
        );

        insert intlog;
		Test.setCreatedDate(intLog.Id, DateTime.now().addDays(-11));
    }

    @isTest
    private static void testLogCleanBatch() {

        Test.startTest();
        Id batchJobId = Database.executeBatch(new IntegrationLogCleanBatch(), 200);
        Test.stopTest();
        List<Integration_Log__c> logs = [SELECT Id FROM Integration_Log__c ];
        System.assert(logs.isEmpty());
    }
}