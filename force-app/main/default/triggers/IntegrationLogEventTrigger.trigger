trigger IntegrationLogEventTrigger on Integration_Log_Event__e (after insert) {
    IntegrationLogUtility.saveIntegrationLogs(Trigger.new);
}