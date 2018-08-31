//
//  RSCoreDataStack.h
//  RSCoreTests
//
//  Created by Brent Simmons on 9/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface RSCoreDataStack : NSObject {
@private
	NSManagedObjectModel *managedObjectModel;
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSManagedObjectContext *mainThreadManagedObjectContext;
	
}


- (id)initWithModelResourceName:(NSString *)modelResourceName storeFileName:(NSString *)storeFileName;


@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectContext *mainThreadManagedObjectContext;


@end
