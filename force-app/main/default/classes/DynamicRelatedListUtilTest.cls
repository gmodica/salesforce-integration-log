@isTest
private class DynamicRelatedListUtilTest {
	private static final String FIELD_SET_NAME = 'Dynamic_Related_List_Test';
	private static Boolean usePagination = false;

	@TestSetup
	private static void setup() {
		Account a1 = new Account(Name = 'Test');
		insert new Account[] { a1 };

		Contact c1 = new Contact(FirstName = 'First', LastName = 'Last', AccountId = a1.Id);
		insert new Contact[] { c1 };

		Case case1 = new Case(ContactId = c1.Id, Subject = 'Test 1');
		Case case2 = new Case(ContactId = c1.Id, Subject = 'Test 2');
		insert new Case[] { case1, case2 };
	}

	@IsTest
	private static void testGetRelatedList() {
		Contact c = [select Id from Contact limit 1];
		Schema.FieldSet fs = SObjectType.Case.fieldSets.getMap().get(FIELD_SET_NAME);
		if(fs == null) return;

		Test.startTest();

		DynamicRelatedListUtil.Info info = DynamicRelatedListUtil.getRelatedList(c.Id, 'DynamicRelatedListUtilTest.DynamicRelatedListUtilTestDataProvider', FIELD_SET_NAME);

		Test.stopTest();

		System.assertEquals(2, info.data.size()); // the contact has 2 cases

		Set<String> infoColumnLabels = new Set<String>();
		for (DynamicRelatedListUtil.TableColumn tableColumn : info.columns) {
			infoColumnLabels.add(tableColumn.label);
		}
		Set<String> fieldSetColumnLabels = new Set<String>();
		for(Schema.FieldSetMember fsm :  fs.getFields()) {
			fieldSetColumnLabels.add(fsm.getLabel());
		}

		System.debug('fieldSetColumnLabels: ' + fieldSetColumnLabels);
		System.debug('infoColumnLabels: ' + infoColumnLabels);
		System.assertEquals(true,infoColumnLabels.containsAll(new List<String>(fieldSetColumnLabels)));
		System.assertEquals(null,info.sortedBy);
		System.assertEquals(null,info.selectedRows);

	}

	@IsTest
	private static void testGetRelatedListWithPagination() {
		Contact c = [select Id from Contact limit 1];

		Test.startTest();

		usePagination = true;
		DynamicRelatedListUtil.Info info = DynamicRelatedListUtil.getRelatedList(c.Id, 'DynamicRelatedListUtilTest.DynamicRelatedListUtilTestDataProvider', FIELD_SET_NAME);

		Test.stopTest();

		System.assertEquals(1, info.data.size()); // the contact has 2 cases, but 1 only is showed because of pagination

	}

	public class DynamicRelatedListUtilTestDataProvider implements DynamicRelatedListUtil.DynamicRelatedListDataProvider {
		public DynamicRelatedListUtil.Info getRelatedListInfo(Id recordId, String fieldSetName) {
			List<Contact> contacts = [select Id from Contact where Id = :recordId];
			if(contacts.isEmpty()) return null;

			Map<String, Schema.FieldSet> fieldSetMap = SObjectType.Case.fieldSets.getMap();
			Schema.FieldSet fs = fieldSetMap.get(fieldSetName);

			String sql = DynamicRelatedListUtil.buildSoqlFromFieldSet(SObjectType.Case.name, fs);
			sql += ' where ContactId = :recordId';
			List<Case> cases = Database.query(sql);

			DynamicRelatedListUtil.Info relatedListInfo = usePagination ? new DynamicRelatedListUtil.Info(cases, fs, 0, 1) : new DynamicRelatedListUtil.Info(cases, fs);

			return relatedListInfo;
		}
	}
}