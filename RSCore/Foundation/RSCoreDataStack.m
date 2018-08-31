//
//  RSCoreDataStack.m
//  RSCoreTests
//
//  Created by Brent Simmons on 9/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSCoreDataStack.h"


@implementation RSCoreDataStack

@synthesize persistentStoreCoordinator;
@synthesize mainThreadManagedObjectContext;


#pragma mark Init

- (id)initWithModelResourceName:(NSString *)modelResourceName storeFileName:(NSString *)storeFileName {
    self = [super init];
    if (self == nil)
        return nil;
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:modelResourceName ofType:@"momd"];
    if (modelPath == nil)
        modelPath = [[NSBundle mainBundle] pathForResource:modelResourceName ofType:@"mom"];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:modelPath]];
    NSString *storeFilePath = [rs_app_delegate.pathToDataFolder stringByAppendingPathComponent:storeFileName];
    NSURL *storeURL = [NSURL fileURLWithPath:storeFilePath];
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]); //TODO: handle persistent store creation error. See notes in template version of Core Data app.
        abort();
    }    
    mainThreadManagedObjectContext = [[NSManagedObjectContext alloc] init];
    [mainThreadManagedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
    [mainThreadManagedObjectContext setUndoManager:nil];
    [mainThreadManagedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:nil];
    return self;
}



#pragma mark Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark Notifications

- (void)managedObjectContextDidSave:(NSNotification *)note {
    if ([note object] == self.mainThreadManagedObjectContext)
        return;
    if (![NSThread isMainThread])
        [self.mainThreadManagedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:note waitUntilDone:NO];
    else
        [self.mainThreadManagedObjectContext mergeChangesFromContextDidSaveNotification:note];
}


@end
