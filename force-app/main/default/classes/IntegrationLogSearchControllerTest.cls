@isTest
private class IntegrationLogSearchControllerTest {
	@TestSetup
	private static void setup() {
		Integration_Log__c l1 = new Integration_Log__c(Module__c = 'Test', Method__c = 'GET', Endpoint__c = 'http://systemx.com?recordId=123456', Request_Body__c = 'Some request from system X');
		Integration_Log__c l2 = new Integration_Log__c(Module__c = 'Test', Method__c = 'GET', Endpoint__c = 'http://systemy.com?recordId=123456', Request_Body__c = 'Some request from system Y');
		Integration_Log__c l3 = new Integration_Log__c(Module__c = 'Test', Method__c = 'GET', Endpoint__c = 'http://systemz.com?recordId=654321', Request_Body__c = 'Some request from system Z');
		insert new Integration_Log__c[] { l1, l2, l3 };
	}

	@IsTest
	private static void testSingleTerm() {

		Test.startTest();

		List<Integration_Log__c> logs = IntegrationLogSearchController.search('123456');

		Test.stopTest();

		System.assertEquals(2, logs.size());
	}

	@IsTest
	private static void testMultipleTerm() {

		Test.startTest();

		List<Integration_Log__c> logs = IntegrationLogSearchController.search(new List<String> { 'systemx', 'systemy'});

		Test.stopTest();

		System.assertEquals(2, logs.size());
	}

	@IsTest
	private static void testDynamicListForAccount() {
		Account a = new Account(Name = 'Test', AccountNumber = '123456');
		insert a;

		Test.startTest();

		IntegrationLogSearchController.LogsRelatedListProvider provider = new IntegrationLogSearchController.LogsRelatedListProvider();
		DynamicRelatedListUtil.Info info = provider.getRelatedListInfo(a.Id, SObjectType.Integration_Log__c.fieldSets.Latest_Logs.name);

		Test.stopTest();

		System.assertEquals(2, info.data.size());
	}
}
