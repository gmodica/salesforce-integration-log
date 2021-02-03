global class IntegrationLogCleanSchedulable  implements Schedulable {
    global void execute(SchedulableContext sc) {
        Id batchJobId = Database.executeBatch(new IntegrationLogCleanBatch(), 200);
    }
}
