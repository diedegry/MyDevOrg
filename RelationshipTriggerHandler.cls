/**
 * @description       : 
 * @author            : First Name Last Name
 * @group             : 
 * @last modified on  : 2021-12-30
 * @last modified by  : First Name Last Name
**/
public with sharing class RelationshipTriggerHandler extends TriggerHandler{
    
    public override void afterUpdate(){
        updateEnrollment();
        createTask();
    }

    public override void afterInsert(){
        updateEnrollment();
        createTask();
    }
    //Method that update Enrollment record depending on Relationship Type__c
    public static void updateEnrollment() {
        //gets trigger new
        List<Relationship__c> triggerNew = Trigger.new;
        //gets trigger old map
        Map<Id, Relationship__c> oldMap = (Map<Id, Relationship__c>)Trigger.oldMap;
        //create list of enrollments to update
        List<Enrollment__c> enrollmentToUpdate = new List<Enrollment__c>();
        //Map Enrollment to list of Relationships which it owns
        Map<Enrollment__c, List<Relationship__c>> enrollmentToRelationship = new Map<Enrollment__c, List<Relationship__c>>();
        //List of Relationship records in Trigger New
        List<Relationship__c> relationshipList = [SELECT Id, Status__c, Type__c, Enrollment__c, Enrollment__r.OwnerId FROM Relationship__c WHERE Id IN :triggerNew];

        //iteration must create map with Enrollment__c and list of Relationships which he owns
        //Check whether enrollmentToRelationship contains Enrollment inside or not
        //If map doesnt contain enrollment creates new relationship list and adds record to map
        //If map contains enrollment it gets list of relationship from map and add new relationship
        //And trigger will be invoked if new Type__c value is different from oldMap

        for(Relationship__c relation : relationshipList){
            if(relation.Enrollment__c != null && relation.Type__c != null && (oldMap == null || relation.Type__c != oldMap.get(relation.Id).Type__c)){
                Enrollment__c enrollment = new Enrollment__c(Id = relation.Enrollment__c, OwnerId = relation.Enrollment__r.OwnerId);
                if(enrollmentToRelationship.containsKey(enrollment)){
                    enrollmentToRelationship.get(enrollment).add(relation);
                }
                enrollmentToRelationship.put(enrollment, new List<Relationship__c>{relation});
            }
        }
        //System.debug('EnrollmentToRelationship map ' + enrollmentToRelationship);
        //iterate over map and list of related relationships
        //Create custom notification
        CustomNotificationType notificationType = 
                        [SELECT Id, DeveloperName 
                        FROM CustomNotificationType 
                        WHERE DeveloperName='Relationship_Type'];
        //Iterate over Map
        for(Enrollment__c enroll : enrollmentToRelationship.keySet()){
            for(Relationship__c rel : enrollmentToRelationship.get(enroll)){
                //System.debug('Enrollment ' + enroll);
                if(rel.Type__c == '1'){
                    //System.debug('Enrollment status ' + enroll.Status__c);
                    enroll.Status__c = rel.Status__c;
                    enrollmentToUpdate.add(enroll);
                    //System.debug('Enrollment status after change ' + enroll.Status__c);
                }
                else if(rel.Type__c == '4'){
                    //System.debug('Enrollment OwnerId ' + enroll.OwnerId);
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('Relationship notification');
                    notification.setBody('Relationship type equals 4. Click to view more');
                    notification.setNotificationTypeId(notificationType.Id);
                    notification.setTargetId(rel.Id);
                    notification.send(new Set<String>{enroll.OwnerId});
                }
            }
        }
        //if enrollmentToUpdate size is 1 or bigger it invokes update
        update enrollmentToUpdate;
    }
    //Method that create Task depending on Relationship Type__c
    public static void createTask(){
        //gets trigger new
        List<Relationship__c> triggerNew = Trigger.new;
        //gets trigger old map
        Map<Id, Relationship__c> oldMap = (Map<Id, Relationship__c>)Trigger.oldMap;
        //List of all Task_Scheduler__mdt records
        List<Task_Scheduler__mdt> taskSchedulerList = [SELECT MasterLabel, Time__c, Type_1__c, Type_2__c, Type_3__c, Type_4__c FROM Task_Scheduler__mdt];
        //Map with Relationship and Task_Scheduler__mdt
        Map<Relationship__c, List<Task_Scheduler__mdt>> relationToMdt = new Map<Relationship__c, List<Task_Scheduler__mdt>>();
        //List of task to insert
        List<Task> taskToInsert = new List<Task>();
        
        /*for(Relationship__c relation : [SELECT Id, Type__c, OwnerId FROM Relationship__c WHERE Id IN :triggerNew]){
            if(relation.Type__c != null && relation.OwnerId != null && (oldMap == null || oldMap.get(relation.Id).Type__c != relation.Type__c)){
                String query = 'SELECT MasterLabel, Time__c, Type_' + relation.Type__c + '__c FROM Task_Scheduler__mdt WHERE Type_' + relation.Type__c + '__c = true';
                for(Task_Scheduler__mdt ts : Database.query(query)){
                    Integer days = (Integer)ts.Time__c;
                    Task task = new Task(
                        Subject = ts.MasterLabel,
                        ActivityDate = Date.Today().addDays(days),
                        OwnerId = relation.OwnerId,
                        WhatId = relation.Id
                    );
                    taskToInsert.add(task);
                }
            }
        }*/
        for(Relationship__c relation : [SELECT Id, Type__c, OwnerId FROM Relationship__c WHERE Id IN :triggerNew]){
            if(relation.Type__c != null && relation.OwnerId != null &&(oldMap == null || oldMap.get(relation.Id).Type__c != relation.Type__c)){
                for(Task_Scheduler__mdt ts : taskSchedulerList){
                    if(!relationToMdt.containsKey(relation)){
                        if(relation.Type__c == '1' && ts.Type_1__c == true){
                            relationToMdt.put(relation, new List<Task_Scheduler__mdt>{ts});
                        }
                        else if(relation.Type__c == '2' && ts.Type_2__c == true){
                            relationToMdt.put(relation, new List<Task_Scheduler__mdt>{ts});
                        }
                        else if(relation.Type__c == '3' && ts.Type_3__c == true){
                            relationToMdt.put(relation, new List<Task_Scheduler__mdt>{ts});
                        }
                        else if(relation.Type__c == '4' && ts.Type_4__c == true){
                            relationToMdt.put(relation, new List<Task_Scheduler__mdt>{ts});
                        }
                    }
                    else {
                        if(relation.Type__c == '1' && ts.Type_1__c == true){
                            relationToMdt.get(relation).add(ts);
                        }
                        else if(relation.Type__c == '2' && ts.Type_2__c == true){
                            relationToMdt.get(relation).add(ts);
                        }
                        else if(relation.Type__c == '3' && ts.Type_3__c == true){
                            relationToMdt.get(relation).add(ts);
                        }
                        else if(relation.Type__c == '4' && ts.Type_4__c == true){
                            relationToMdt.get(relation).add(ts);
                        }
                    }
                }
            }
        }
        //System.debug('Map<Relationship__c, List<Task_Scheduler__mdt>>: ' + relationToMdt);
        //iterate over map and create task
        for(Relationship__c relation : relationToMdt.keySet()){
            for(Task_Scheduler__mdt ts : relationToMdt.get(relation)){
                Integer days = (Integer)ts.Time__c;
                    Task task = new Task(
                        Subject = ts.MasterLabel,
                        ActivityDate = Date.Today().addDays(days),
                        OwnerId = relation.OwnerId,
                        WhatId = relation.Id
                    );
                    taskToInsert.add(task);
            }
        }
        System.debug('The number of tasks: ' + taskToInsert.size());
        System.debug('The number of queries: ' + Limits.getQueries());
        //Create Task
        insert taskToInsert;
    }


    // UPDATE ASYNC, USE FUTURE METHOD TO GET MAP<RELATIONSHIP__C, LIST<TASK_SCHEDULER__MDT>>
}
