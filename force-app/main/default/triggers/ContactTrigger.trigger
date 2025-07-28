/**
 * ContactTrigger Trigger Description:
 * 
 * The ContactTrigger is designed to handle various logic upon the insertion and update of Contact records in Salesforce. 
 * 
 * Key Behaviors:
 * 1. When a new Contact is inserted and doesn't have a value for the DummyJSON_Id__c field, the trigger generates a random number between 0 and 100 for it.
 * 2. Upon insertion, if the generated or provided DummyJSON_Id__c value is less than or equal to 100, the trigger initiates the getDummyJSONUserFromId API call.
 * 3. If a Contact record is updated and the DummyJSON_Id__c value is greater than 100, the trigger initiates the postCreateDummyJSONUser API call.
 * 
 * Best Practices for Callouts in Triggers:
 * 
 * 1. Avoid Direct Callouts: Triggers do not support direct HTTP callouts. Instead, use asynchronous methods like @future or Queueable to make the callout.
 * 2. Bulkify Logic: Ensure that the trigger logic is bulkified so that it can handle multiple records efficiently without hitting governor limits.
 * 3. Avoid Recursive Triggers: Ensure that the callout logic doesn't result in changes that re-invoke the same trigger, causing a recursive loop.
 * 
 * Optional Challenge: Use a trigger handler class to implement the trigger logic.
 */
trigger ContactTrigger on Contact(before insert, after insert, after update) {
	
	// BEFORE INSERT: 
	if (Trigger.isBefore && Trigger.isInsert) {
	// When a contact is inserted
		for (Contact cont : Trigger.new) {
			// if DummyJSON_Id__c is null, generate a random number between 0 and 100 and set this as the contact's DummyJSON_Id__c value
			if (String.isBlank(cont.DummyJSON_Id__c)) {
				cont.DummyJSON_Id__c = String.valueOf(Integer.valueOf(Math.round(Math.random() * 100)));
			}
		}
	}

	// AFTER INSERT: 
	if (Trigger.isAfter && Trigger.isInsert) {
		for (Contact cont : Trigger.new) {
			// if DummyJSON_Id__c is less than or equal to 100, call the getDummyJSONUserFromId API
			if (String.isBlank(cont.DummyJSON_Id__c)) {
				System.debug('Skipping callout for Contact ' + cont.Id + ' due to missing DummyJSON_Id__c');
			} else {
				Integer dummyId = Integer.valueOf(cont.DummyJSON_Id__c);
				if (dummyId <= 100) {
					DummyJSONCallout.getDummyJSONUserFromId(cont.DummyJSON_Id__c);
				}
			}
		}
		
	}

	// AFTER UPDATE: 
	if (Trigger.isAfter && Trigger.isUpdate) {
		if (System.isFuture()) {
			return; // prevents recursion
		} 
		for (Contact cont : Trigger.new) {
			// if DummyJSON_Id__c is greater than 100, call the postCreateDummyJSONUser API
			Contact old = Trigger.oldMap.get(cont.Id);
			if (!String.isBlank(cont.DummyJSON_Id__c)) {
				Integer dummyId = Integer.valueOf(cont.DummyJSON_Id__c);
				Integer oldDummyId = String.isBlank(old.DummyJSON_Id__c) ? null : Integer.valueOf(old.DummyJSON_Id__c);
				if (dummyId > 100 && dummyId != oldDummyId) {
					DummyJSONCallout.postCreateDummyJSONUser(cont.Id);
				}
			}
		}
	}
	
}