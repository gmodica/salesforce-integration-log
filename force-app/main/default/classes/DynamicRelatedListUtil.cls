public class DynamicRelatedListUtil {
	public interface DynamicRelatedListDataProvider {
		Info getRelatedListInfo(Id recordId, String fieldSetName);
	}

	@AuraEnabled(cacheable=true)
	public static Info getRelatedList(Id recordId, String className, String fieldSetName) {
		try {
			Type t = Type.forName(className);
			DynamicRelatedListDataProvider provider = (DynamicRelatedListDataProvider)t.newInstance();
			Info relatedListInfo = provider.getRelatedListInfo(recordId, fieldSetName);

			return relatedListInfo;
		}
        catch(Exception e) {
            System.debug(e.getMessage() + '\r\n' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
	}

	public static String buildSoqlFromFieldSet(String objectName, Schema.FieldSet fs) {
		Set<String> fields = new Set<String>();
		fields.add('Id');

		if(fs != null) {
			for(Schema.FieldSetMember fsm : fs.getFields()) {
				fields.add(fsm.getFieldPath());
				if(fsm.getType() == Schema.DisplayType.Reference) {
					Schema.sObjectType obj = fsm.getSObjectField().getDescribe().getReferenceTo()[0];
					for(Schema.SObjectField field : obj.getDescribe().fields.getMap().values()) {
						Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
						if(fieldDescribe.isNameField()) {
							String relatedFieldName = fsm.getSObjectField().getDescribe().getRelationshipName() + '.' + fieldDescribe.getName();
							fields.add(relatedFieldName);
						}
					}
				}
			}
		}

		String soql = 'SELECT ' + String.join(new List<String>(fields), ',') + ' FROM ' + objectName;

		return soql;
	}

	/**
	 * @description:
	 */
    public class Info {

        @AuraEnabled
		public List<TableColumn> columns {get; set;}

        @AuraEnabled
		public List<Object> data {get; set;}

        @AuraEnabled
		public String baseUrl {get; set;}

        @AuraEnabled
		public String sortedBy {get; set;}

        @AuraEnabled
		public String sortedDirection {get; set;}

        @AuraEnabled
		public List<String> selectedRows {get; set;}

        @AuraEnabled
		public Boolean hasMore {get; set;}

        @AuraEnabled
        public Integer total {get; set;}

        private Map<String,String> renameMap {get; set;}
		private FieldSet fs {get; set;}

        public Info(List<SObject> data, Schema.FieldSet fs) {
            this.data = convertData(data);
			total = data != null ? data.size() : 0;
            hasMore = false;
			this.fs = new FieldSet(fs);
            build();
        }

		public Info(List<Object> data, FieldSet fs) {
			this.data = data;
            total = data != null ? data.size() : 0;
            hasMore = false;
            this.fs = fs;
            build();
        }

        public Info(List<SObject> allData, Schema.FieldSet fs, Integer fromIndex, Integer quantity) {
            if(fromIndex != null && quantity != null) {
                this.data = new List<Object>();
                if(allData == null || allData.isEmpty()) {
                    hasMore = false;
                }
                else {
                    Integer toIndex = fromIndex + quantity;
					//System.debug('loading data from ' + fromIndex + ' to ' + toIndex);
                    for(Integer i = fromIndex; i < toIndex; i++) {
                        if(allData.size() > i) {
                            this.data.add(convertData(allData[i]));
                        }
                    }
                    hasMore = toIndex <= allData.size();
                }
            }
            else {
                this.data = convertData(allData);
            }

            total = allData != null ? allData.size() : 0;

            this.fs = new FieldSet(fs);
            build();
		}

		public Info(List<Object> allData, FieldSet fs, Integer fromIndex, Integer quantity) {
            if(fromIndex != null && quantity != null) {
                this.data = new List<Object>();
                if(allData == null || allData.isEmpty()) {
                    hasMore = false;
                }
                else {
                    Integer toIndex = fromIndex + quantity;
					System.debug('loading data from ' + fromIndex + ' to ' + toIndex);
                    for(Integer i = fromIndex; i < toIndex; i++) {
                        if(allData.size() > i) {
                            this.data.add(allData[i]);
                        }
                    }
                    hasMore = toIndex <= allData.size();
                }
            }
            else {
                this.data = allData;
            }

            total = allData != null ? allData.size() : 0;

            this.fs = fs;
            build();
		}

		private List<Object> convertData(List<SObject> records) {
			List<Object> data = new List<Object>();
			for(SObject record : records) {
				data.add(convertData(record));
			}
			return data;
		}

		private Object convertData(SObject record) {
			return (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(record));
		}

        private void build() {
			createColumnList(fs, renameMap);

            baseUrl = Url.getSalesforceBaseUrl().getHost();
            if(!baseUrl.endsWith('/')) baseUrl += '/';

			if(fs.fieldSet != null) augmentData(fs.fieldSet);
		}

		private void augmentData(Schema.FieldSet fs) {
			for(Object item : data) {
				Map<String,Object> record = (Map<String,Object>)item;

				for(Schema.FieldSetMember fsm : fs.getFields()) {
					Schema.DisplayType displayType = fsm.getType();

					if(fsm.getSObjectField().getDescribe().isNameField()) {
						Schema.sObjectType obj = fs.getSObjectType();
						for(Schema.SObjectField field : obj.getDescribe().fields.getMap().values()) {
							Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
							if(fieldDescribe.isNameField()) {
								String nameField = fieldDescribe.getName();
								record.put(fsm.getFieldPath() + '__link', baseUrl + String.valueOf(record.get('Id')));
								record.put(fsm.getFieldPath() + '__label', record.get(nameField));
								record.put(fsm.getFieldPath() + '__tooltip', record.get(nameField));
							}
						}
					}
					else if(displayType == Schema.DisplayType.Reference) {
						Schema.sObjectType obj = fsm.getSObjectField().getDescribe().getReferenceTo()[0];
						for(Schema.SObjectField field : obj.getDescribe().fields.getMap().values()) {
							Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
							if(fieldDescribe.isNameField()) {
								String relationshipName = fsm.getSObjectField().getDescribe().getRelationshipName();
								String relationshipField = fieldDescribe.getName();

								Map<String,Object> relationship = (Map<String,Object>)record.get(relationshipName);
								record.put(fsm.getFieldPath() + '__link', baseUrl + String.valueOf(record.get('Id')));
								record.put(fsm.getFieldPath() + '__label', relationship.get(relationshipField));
								record.put(fsm.getFieldPath() + '__tooltip', relationship.get(relationshipField));
							}
						}
					}
				}
			}
		}

		private void createColumnList(FieldSet fs, Map<String,String> renameMap) {
            columns = new List<TableColumn>();

            if(fs == null) return;

            for(Field fsm : fs.fields) {
                TableColumn tc = new TableColumn(fsm.label, fsm.path, renameMap);
                tc.type = getType(fsm, tc);

                columns.add(tc);
            }
        }

		private String getType(Field fsm, TableColumn tc) {
			Schema.DisplayType displayType = fsm.type;

			if(fsm.fieldSet != null && fsm.fieldSet.fieldSet != null && fsm.fieldSetMember != null) {
				Schema.DescribeFieldResult describe = fsm.fieldSetMember.getSObjectField().getDescribe();
				if(describe.isNameField()) {
					UrlTypeAttributes attributes = new UrlTypeAttributes(tc.FieldName);
					tc.fieldName = tc.FieldName + '__link';

					Schema.sObjectType obj = fsm.fieldSet.fieldSet.getSObjectType();
					for(Schema.SObjectField field : obj.getDescribe().fields.getMap().values()) {
						Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
						if(fieldDescribe.isNameField()) {
							attributes.relationshipName = describe.getRelationshipName();
							attributes.relationshipField = fieldDescribe.getName();
						}
					}
					tc.typeAttributes = attributes;
					return 'url';
				}
				else if(displayType == Schema.DisplayType.Reference) {
					UrlTypeAttributes attributes = new UrlTypeAttributes(tc.FieldName);
					tc.fieldName = tc.FieldName + '__link';

					Schema.sObjectType obj = describe.getReferenceTo()[0];
					for(Schema.SObjectField field : obj.getDescribe().fields.getMap().values()) {
						Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
						if(fieldDescribe.isNameField()) {
							attributes.relationshipName = describe.getRelationshipName();
							attributes.relationshipField = fieldDescribe.getName();
						}
					}
					tc.typeAttributes = attributes;
					return 'url';
				}
				else {
					return getType(displayType, tc);
				}
			}
			else {
				return getType(displayType, tc);
			}
		}

		private String getType(Schema.DisplayType displayType, TableColumn tc) {
            if(displayType == Schema.DisplayType.String || displayType == Schema.DisplayType.Picklist || displayType == Schema.DisplayType.TextArea) {
                return 'text';
            }
            else if(displayType == Schema.DisplayType.Date) {
                tc.typeAttributes = new DateTypeAttributes();
                return 'date-local';
            }
			else if(displayType == Schema.DisplayType.DateTime) {
                tc.typeAttributes = new DateTypeAttributes();
                return 'date';
            }
			else if(displayType == Schema.DisplayType.Currency) {
                tc.cellAttributes = new CurrencyCellAttributes();
                return 'currency';
            }
			else if(displayType == Schema.DisplayType.Boolean) {
                return 'boolean';
            }
			else if(displayType == Schema.DisplayType.Percent) {
                return 'percent';
            }
            else if(displayType == Schema.DisplayType.Phone) {
                return 'phone';
            }
			else if(displayType == Schema.DisplayType.Email) {
                return 'email';
            }
			else if(displayType == Schema.DisplayType.Url) {
                return 'url';
            }
            else if(displayType == Schema.DisplayType.Integer || displayType == Schema.DisplayType.Long) {
                tc.typeAttributes = new NumberTypeAttributes();
                return 'number';
            }
            else if(displayType == Schema.DisplayType.Double) {
                return 'number';
            }

            return 'text';
        }
    }

	public class FieldSet {
		public Schema.FieldSet fieldSet {get; set;}
		public List<Field> fields {get; set; }

		public FieldSet() {
			fields = new List<Field>();
		}

		public FieldSet(Schema.FieldSet fieldSet) {
			this();
			this.fieldSet = fieldSet;
			for(Schema.FieldSetMember fsm : fieldSet.getFields()) {
				fields.add(new Field(this, fsm));
            }
		}
	}

	public class Field {
		public FieldSet fieldSet {get; set;}
		public String label {get; set;}
		public String path {get; set;}
		public Schema.DisplayType type {get; set;}
		public Schema.FieldSetMember fieldSetMember {get; set;}

		public Field(String label, String path, Schema.DisplayType type) {
			this.label = label;
			this.path = path;
			this.type = type;
		}

		public Field(FieldSet fieldSet, Schema.FieldSetMember fieldSetMember) {
			this.fieldSet = fieldSet;
			this.fieldSetMember = fieldSetMember;
			this.label = fieldSetMember.getLabel();
			this.path = fieldSetMember.getFieldPath();
			this.type = fieldSetMember.getType();
		}
	}

	/**
	 * @description:
	 */
    public class TableColumn {

        @AuraEnabled
		public String label {get; set;}

        @AuraEnabled
		public String fieldName {get; set;}

        @AuraEnabled
		public String type {get; set;}

        @AuraEnabled
		public TypeAttributes typeAttributes {get; set;}

        @AuraEnabled
		public CellAttributes cellAttributes {get; set;}

        @AuraEnabled
		public Integer initialWidth {get;set;}

		@AuraEnabled
		public Boolean wrapText {get; set;}

		@AuraEnabled
		public Boolean sortable {get; set;}

		private TableColumn() {
			this.sortable = true;
		}

        public TableColumn(String label, String fieldName) {
			this();
			this.wrapText = false;
            this.label = label;
            this.fieldName = fieldName;
        }

        public TableColumn(String label, String fieldName, Map<String,String> renameMap) {
        	this(label, fieldName);
            if(renameMap != null && renameMap.containsKey(this.fieldName)) {
                this.fieldName = renameMap.get(this.fieldName);
            }
        }
    }

    public abstract class TypeAttributes {

    }

	/**
	 * @description:
	 */
    public class DateTypeAttributes extends TypeAttributes {

        @AuraEnabled
		public String year {get; set;}

        @AuraEnabled
		public String month {get; set;}

        @AuraEnabled
		public String day {get; set;}

        @AuraEnabled
		public String hour {get; set;}

        @AuraEnabled
		public String minute {get; set;}

        @AuraEnabled
        public Boolean hour12 {get; set;}

        public DateTypeAttributes() {
            this.year = 'numeric';
            this.hour = '2-digit';
            this.minute = '2-digit';
            this.hour12 = false;
            this.month = '2-digit';
            this.day = '2-digit';
        }
    }

    public abstract class CellAttributes {

    }

	/**
	 * @description:
	 */
    public class CurrencyCellAttributes extends CellAttributes {

		@AuraEnabled
        public String alignment {get; set;}

        public CurrencyCellAttributes() {
            alignment = 'right';
        }
    }

	/**
	 * @description:
	 */
    public class MiddleCellAttributes extends CellAttributes {

		@AuraEnabled
        public String alignment {get; set;}

        public MiddleCellAttributes() {
            alignment = 'center';
        }
	}

	/**
	 * @description:
	 */
    public class IconCellAttributes extends CellAttributes {

		@AuraEnabled
		public IconCellAttributesName iconName {get; set;}

        public IconCellAttributes() {

        }
	}

	/**
	 * @description:
	 */
    public class IconCellAttributesName extends CellAttributes {

		@AuraEnabled
        public String fieldName {get; set;}

        public IconCellAttributesName(String fieldName) {
			this.fieldName = fieldName;
        }
    }

	/**
	 * @description:
	 */
    public class NumberTypeAttributes extends TypeAttributes {

        @AuraEnabled
        public String maximumFractionDigits {get; set;}

        public NumberTypeAttributes() {
            this.maximumFractionDigits = '2';
        }
    }

	/**
	 * @description:
	 */
    public class ButtonTypeAttributes extends TypeAttributes {

        @AuraEnabled
		public String label {get; set;}

        @AuraEnabled
		public String name {get; set;}

        @AuraEnabled
        public UrlTypeAttributesTooltip tooltip {get; set;}

        public ButtonTypeAttributes(String label) {
            this.name = 'open_record';
            this.label = label;
            this.tooltip = new UrlTypeAttributesTooltip(label);
        }
    }

	/**
	 * @description:
	 */
    public class UrlTypeAttributes extends TypeAttributes {

        @AuraEnabled
		public UrlTypeAttributesLabel label {get; set;}

        @AuraEnabled
		public String target {get; set;}

        @AuraEnabled
		public UrlTypeAttributesTooltip tooltip {get; set;}

        @AuraEnabled
		public String relationshipName {get; set;}

        @AuraEnabled
        public String relationshipField {get; set;}

        public UrlTypeAttributes(String label) {
            this.target = '_self';
            this.label = new UrlTypeAttributesLabel(label + '__label');
            this.tooltip = new UrlTypeAttributesTooltip(label + '__tooltip');
        }
    }

	/**
	 * @description:
	 */
    public class UrlTypeAttributesTooltip {

        @AuraEnabled
        public String fieldName {get; set;}

        public UrlTypeAttributesTooltip(String fieldName) {
            this.fieldName = fieldName;
        }
    }

	/**
	 * @description:
	 */
    public class UrlTypeAttributesLabel {

        @AuraEnabled
        public String fieldName {get; set;}

        public UrlTypeAttributesLabel(String fieldName) {
            this.fieldName = fieldName;
        }
    }

	/**
	 * @description:
	 */
    public class ButtonTypeAttributesLabel {

        @AuraEnabled
        public String fieldName {get; set;}

        public ButtonTypeAttributesLabel(String fieldName) {
            this.fieldName = fieldName;
        }
	}

	/**
	 * @description:
	 */
	// public static Set<String> getColumsFromFieldSet(Schema.FieldSet fs) {
    //     Set<String> fields = new Set<String>();
    //     fields.add('Id');
    //     if(fs != null) {
    //         for(Schema.FieldSetMember fsm : fs.getFields()) {
    //             fields.add(fsm.getFieldPath());
    //             if(fsm.getType() == Schema.DisplayType.Reference) {
    //                 Schema.sObjectType obj = fsm.getSObjectField().getDescribe().getReferenceTo()[0];
    //                 for(Schema.SObjectField field : obj.getDescribe().fields.getMap().values()) {
    //                     Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
    //                     if(fieldDescribe.isNameField()) {
    //                         String relatedFieldName = fsm.getSObjectField().getDescribe().getRelationshipName() + '.' + fieldDescribe.getName();
    //                         fields.add(relatedFieldName);
    //                     }
    //                 }
    //             }
    //         }
	// 	}
	// 	return fields;
	// }


}