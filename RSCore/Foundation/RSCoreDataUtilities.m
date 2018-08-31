//
//  RSCoreDataUtilities.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/10/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSCoreDataUtilities.h"
#import "RSCache.h"


NSString *RSDataEqualityFormat = @"%@ == $VALUE";
NSString *RSDataInequalityFormat = @"%@ == $VALUE";
NSString *RSDataGenericSubstitionKey = @"VALUE";

static RSCache *gPredicateCache = nil;

void RSCoreDataUtilitiesStartup(void) {
	if (gPredicateCache == nil)
		gPredicateCache = [[RSCache alloc] init];
}


NSPredicate *RSPredicateWithEquality(NSString *key) {
	NSPredicate *predicate = [gPredicateCache objectForKey:key];
	if (predicate != nil)
		return predicate;	
	predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:RSDataEqualityFormat, key]];
	[gPredicateCache setObject:predicate forKey:key];
	return predicate;
}


NSManagedObject *RSFetchManagedObjectWithPredicate(NSPredicate *predicate, NSString *entityName, NSManagedObjectContext *moc) {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:moc]];
	[request setFetchLimit:1];
	[request setPredicate:predicate];
	NSError *error = nil;
	return [[moc executeFetchRequest:request error:&error] rs_safeObjectAtIndex:0];
}


NSArray *RSFetchManagedObjectArrayWithPredicate(NSPredicate *predicate, NSString *entityName, NSManagedObjectContext *moc) {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:moc]];
	[request setPredicate:predicate];
	NSError *error = nil;
	return [moc executeFetchRequest:request error:&error];			
}


NSArray *RSFetchManagedObjectArrayWithValueForKey(NSString *key, id value, NSString *entityName, NSManagedObjectContext *moc) {
	NSPredicate *localPredicate = [RSPredicateWithEquality(key) predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:value forKey:RSDataGenericSubstitionKey]];
	return RSFetchManagedObjectArrayWithPredicate(localPredicate, entityName, moc);	
}


NSManagedObject *RSFetchManagedObjectWithValueForKey(NSString *key, id value, NSString *entityName, NSManagedObjectContext *moc) {
	NSPredicate *localPredicate = [RSPredicateWithEquality(key) predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:value forKey:RSDataGenericSubstitionKey]];
	return RSFetchManagedObjectWithPredicate(localPredicate, entityName, moc);
}


NSManagedObject *RSInsertObject(NSString *entityName, NSManagedObjectContext *moc) {
	return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:moc];
}


NSManagedObject *RSInsertObjectWithDictionary(NSDictionary *matches, NSString *entityName, NSManagedObjectContext *moc) {
	/*Assumes it doesn't exist already.*/
	NSManagedObject *insertedObject = RSInsertObject(entityName, moc);
	for (NSString *oneKey in matches)
		[insertedObject setValue:[matches objectForKey:oneKey] forKey:oneKey];
	return insertedObject;
}


NSManagedObject *RSInsertObjectWithValueForKey(NSString *key, id value, NSString *entityName, NSManagedObjectContext *moc) {
	return RSInsertObjectWithDictionary([NSDictionary dictionaryWithObject:value forKey:key], entityName, moc);
}


NSManagedObject *RSFetchOrInsertObjectWithValueForKey(NSString *key, id value, NSString *entityName, NSManagedObjectContext *moc, BOOL *didCreate) {
	NSManagedObject *foundObject = RSFetchManagedObjectWithValueForKey(key, value, entityName, moc);
	if (foundObject != nil) {
		*didCreate = NO;
		return foundObject;
	}
	*didCreate = YES;
	return RSInsertObjectWithValueForKey(key, value, entityName, moc);
}


NSPredicate *RSPredicateWithDictionaryMatches(NSDictionary *matches) {
	NSMutableArray *expressionStrings = [NSMutableArray array];
	for (NSString *oneKey in matches)
		[expressionStrings addObject:[NSString stringWithFormat:@"%@ == $%@", oneKey, oneKey]];
	NSString *predicateString = [expressionStrings componentsJoinedByString:@" && "];
	return [NSPredicate predicateWithFormat:predicateString];
}


NSManagedObject *RSFetchManagedObjectWithDictionary(NSDictionary *matches, NSString *entityName, NSManagedObjectContext *moc) {
	/*This is probably slow.*/
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:moc]];
	[request setFetchLimit:1];
	NSPredicate *localPredicate = [RSPredicateWithDictionaryMatches(matches) predicateWithSubstitutionVariables:matches];
	[request setPredicate:localPredicate];
	NSError *error = nil;
	return [[moc executeFetchRequest:request error:&error] rs_safeObjectAtIndex:0];	
}


NSManagedObject *RSFetchOrInsertObjectWithDictionary(NSDictionary *matches, NSString *entityName, NSManagedObjectContext *moc, BOOL *didCreate) {
	/*This is probably slow.*/
	NSManagedObject *foundObject = RSFetchManagedObjectWithDictionary(matches, entityName, moc);
	if (foundObject != nil) {
		*didCreate = NO;
		return foundObject;
	}
	*didCreate = YES;
	return RSInsertObjectWithDictionary(matches, entityName, moc);	
}

													 
void RSSaveManagedObjectContext(NSManagedObjectContext *moc) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *error = nil;
	if ([moc hasChanges] && ![moc save:&error]) {
		NSLog(@"Unresolved Core Data error %@, %@", error, [error userInfo]);
		exit(-1);
	}
	[pool drain];
}
