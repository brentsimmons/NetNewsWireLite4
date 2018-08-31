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


@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) NSManagedObjectContext *mainThreadManagedObjectContext;


@end
