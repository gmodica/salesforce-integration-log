@isTest
private class IntegrationLogCleanSchedulableTest {
    @testSetup
    private static void setup() {

        Integration_Log__c intlog = new Integration_Log__c(
            Module__c = 'Verifiable'
        );

        insert intlog;
    }

    @isTest
    private static  void testSchedule() {
        Test.StartTest();
        IntegrationLogCleanSchedulable sh = new IntegrationLogCleanSchedulable();

        String sch = '0 0 0 3 9 ? 2023';
        String jobId = system.schedule('Test log clean schedulable', sch, sh);

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,
        NextFireTime
        FROM CronTrigger WHERE id = :jobId];

        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2023-09-03 00:00:00', String.valueOf(ct.NextFireTime));

        Test.stopTest();
        List<Integration_Log__c> logs = [SELECT Id FROM Integration_Log__c ];
        System.assertEquals(1,logs.size());
    }

}