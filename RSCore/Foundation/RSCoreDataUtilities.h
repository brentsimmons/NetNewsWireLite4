//
//  RSCoreDataUtilities.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/10/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


extern NSString *RSDataEqualityFormat; //@"%@ == $VALUE";
extern NSString *RSDataGenericSubstitionKey; //@"VALUE";


void RSCoreDataUtilitiesStartup(void); //should call from somewhere, sometime. Okay if accidentally called more than once.

NSPredicate *RSPredicateWithEquality(NSString *key);

NSManagedObject *RSFetchManagedObjectWithPredicate(NSPredicate *predicate, NSString *entityName, NSManagedObjectContext *moc);
NSArray *RSFetchManagedObjectArrayWithPredicate(NSPredicate *predicate, NSString *entityName, NSManagedObjectContext *moc);

NSArray *RSFetchManagedObjectArrayWithValueForKey(NSString *key, id value, NSString *entityName, NSManagedObjectContext *moc);

/*When you want one managed object where key == value.*/

NSManagedObject *RSFetchManagedObjectWithValueForKey(NSString *key, id value, NSString *entityName, NSManagedObjectContext *moc);
NSManagedObject *RSFetchManagedObjectWithDictionary(NSDictionary *matches, NSString *entityName, NSManagedObjectContext *moc);

/*Assumes the object doesn't already exist.*/

NSManagedObject *RSInsertObject(NSString *entityName, NSManagedObjectContext *moc);
NSManagedObject *RSInsertObjectWithValueForKey(NSString *key, id value, NSString *entityName, NSManagedObjectContext *moc);
NSManagedObject *RSInsertObjectWithDictionary(NSDictionary *matches, NSString *entityName, NSManagedObjectContext *moc);

/*Use this most of the time -- for when you don't know if it already exists or not. Use didCreate to know if you should save.*/

NSManagedObject *RSFetchOrInsertObjectWithValueForKey(NSString *key, id value, NSString *entityName, NSManagedObjectContext *moc, BOOL *didCreate);
NSManagedObject *RSFetchOrInsertObjectWithDictionary(NSDictionary *matches, NSString *entityName, NSManagedObjectContext *moc, BOOL *didCreate);

/*Will quit app if there's an error.*/

void RSSaveManagedObjectContext(NSManagedObjectContext *moc);

/*It's a predicate that can be saved -- it's not usable as-is: it needs to have substition variables replaced.*/

NSPredicate *RSPredicateWithDictionaryMatches(NSDictionary *matches);

