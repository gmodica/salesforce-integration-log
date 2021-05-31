public without sharing class IntegrationLogSearchController {
	@AuraEnabled
	public static List<Integration_Log__c> search(String text) {
		return search(new List<String> { text });
	}

	public static List<Integration_Log__c> search(List<String> searchTerms) {
		List<Integration_Log__c> filteredLogs = new List<Integration_Log__c>();

		if(searchTerms == null || searchTerms.isEmpty()) return filteredLogs;

		List<Integration_Log__c> logs = [select Id,CreatedDate,Name,Module__c,Successful__c,Request_Body__c,Endpoint__c,Method__c from Integration_Log__c where CreatedDate = TODAY order by CreatedDate desc limit 50000];
		for(Integration_Log__c log : logs) {
			Boolean include = false;
			for(String searchTerm : searchTerms) {
				if(log.Request_Body__c != null && log.Request_Body__c.containsIgnoreCase(searchTerm)) include = true;
				if(log.Endpoint__c != null && log.Endpoint__c.containsIgnoreCase(searchTerm)) include = true;
			}
			if(include) filteredLogs.add(log);
		}

		return filteredLogs;
	}

	public class LogsRelatedListProvider implements DynamicRelatedListUtil.DynamicRelatedListDataProvider {
		public DynamicRelatedListUtil.Info getRelatedListInfo(Id recordId, String fieldSetName) {
			if(recordId == null) return null;

			List<String> searchTerms = new List<String>();

			if(recordId.getSobjectType() == Account.getSObjectType()) {
				List<Account> accounts = [select Id,AccountNumber from Account where Id = :recordId];
				if(accounts.isEmpty()) return null;
				Account a = accounts[0];
				searchTerms.add(String.valueOf(a.Id));
				searchTerms.add(String.valueOf(a.AccountNumber));
			}

			List<Integration_Log__c> logs = search(searchTerms);

			Map<String, Schema.FieldSet> fieldSetMap = SObjectType.Integration_Log__c.fieldSets.getMap();
			Schema.FieldSet fs = fieldSetMap.get(fieldSetName);

			DynamicRelatedListUtil.Info relatedListInfo = new DynamicRelatedListUtil.Info(logs, fs);

			relatedListInfo.sortedBy = SObjectType.Integration_Log__c.fields.CreatedDate.name;
			relatedListInfo.sortedDirection = 'desc';

			return relatedListInfo;
		}
	}
}
