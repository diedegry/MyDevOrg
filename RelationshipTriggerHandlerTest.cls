/**
 * @description       : 
 * @author            : First Name Last Name
 * @group             : 
 * @last modified on  : 2021-12-30
 * @last modified by  : First Name Last Name
**/
@isTest
public with sharing class RelationshipTriggerHandlerTest {
    
    @TestSetup
    static void makeData(){
        //insert user
        User u = new User();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        u.LastName = 'Test Code';
        u.Email = 'test@test.com';
        u.Alias = 'Tcode';
        u.Username = 'test12394444@test.com';
        u.CommunityNickname = 'test12';
        u.LocaleSidKey = 'en_US';
        u.TimeZoneSidKey = 'GMT';
        u.ProfileID = p.Id;
        u.LanguageLocaleKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';

        insert u;
        //insert contact
        Contact contact = new Contact(
            LastName = 'Test', 
            OwnerId = u.Id
        );
        insert contact;
        //insert enrollment
        Enrollment__c enroll = new Enrollment__c(
            Name = 'Test Enrollment',
            Contact__c = contact.Id
        );
        insert enroll;
    }
    
    @isTest
    public static void updateEnrollmentTest(){

        //get Enrollment__c 
        Enrollment__c enrollment = [SELECT Id, Status__c, OwnerId FROM Enrollment__c LIMIT 1];
        //List of relationship to insert
        List<Relationship__c> relationshipList = new List<Relationship__c>();
        //insert Relationship__c related to Enrollment__c
        for(Integer i = 0; i < 4; i++){
            Relationship__c relation = new Relationship__c(
                Name = 'Test Relation ' + i,
                Enrollment__c = enrollment.Id,
                Status__c = 'Accepted',
                Type__c = '1'
            );
            relationshipList.add(relation);
        }
        insert relationshipList;
        //query enrollment with same Status__c as Relationship Status__c
        List<Enrollment__c> enrollList = [SELECT Id, Status__c FROM Enrollment__c WHERE Status__c = 'Accepted'];
        System.assertEquals(1, enrollList.size(), 'Expected 1 record with Status__c value = Accepted');
        List<Relationship__c> relList = [SELECT Id, Status__c FROM Relationship__c WHERE Enrollment__c = :enrollment.Id];
        System.assertEquals(4, relList.size(), 'Expected 4 Relationship records related to Enrollment');
        //get one relationship record and update its Status to invoke AfterUpdate trigger
        Relationship__c relationship = new Relationship__c(
            Name = 'Test Relation 4',
            Enrollment__c = enrollment.Id,
            Status__c = 'Rejected',
            Type__c = '4'
        );
        insert relationship;
        //update relationship
        relationship.Type__c = '1';
        update relationship;
        //check if Status__c of Enrollment changed
        List<Enrollment__c> enrollList1 = [SELECT Id, Status__c FROM Enrollment__c WHERE Status__c = 'Rejected'];
        System.assertEquals(1, enrollList1.size(), 'Expected 1 record with Status__c value = Rejected');
    }

    @isTest
    public static void createTaskTest(){
        List<Relationship__c> relList = new List<Relationship__c>();
        //insert Relationship
        for(Integer i = 0; i < 3; i++){
            Relationship__c relationship = new Relationship__c(
                Name = 'Test Relation ' + i,
                Type__c = '1'
            );
            relList.add(relationship);
        }
        /*for(Integer i = 0; i < 3; i++){
            Relationship__c relationship = new Relationship__c(
                Name = 'Test relation ' + i,
                Type__c = '2'
            );
            relList.add(relationship);
        }
        for(Integer i = 0; i < 3; i++){
            Relationship__c relationship = new Relationship__c(
                Name = 'test Relation ' + i,
                Type__c = '3'
            );
            relList.add(relationship);
        }
        for(Integer i = 0; i < 3; i++){
            Relationship__c relationship = new Relationship__c(
                Name = 'test relation ' + i,
                Type__c = '4'
            );
            relList.add(relationship);
        }*/
        insert relList;

        Relationship__c relation = [SELECT Id FROM Relationship__c LIMIT 1];

        List<Task> taskList = [SELECT Id FROM Task WHERE WhatId = :relation.Id];
        System.assertEquals(1, taskList.size(), 'Expected 1 tasks created and related to Relationship');
        List<Task> allTasks = [SELECT Id FROM Task]; 
        System.assertEquals(18, allTasks.size(), 'Expected 18 tasks inserted');
        // System.debug('The number of queries: ' + Limits.getQueries());
        // System.debug('The total number of queries: ' + Limits.getLimitQueries());

        relation.Type__c = '1';
        update relation;
        relation.Type__c = '2';
        update relation;
        relation.Type__c = '3';
        update relation;
        relation.Type__c = '4';
        update relation;

        List<Task> taskList1 = [SELECT Id FROM Task WHERE WhatId = :relation.Id];
        System.assertEquals(7, taskList1.size(), 'Expected 7 tasks created and related to Relationship');
    }
}
