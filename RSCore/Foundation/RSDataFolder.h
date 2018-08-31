//
//  RSDataFolder.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/8/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@class RSDataFeed;

@interface RSDataFolder : NSManagedObject {
}

@property (nonatomic, retain) NSString *accountIdentifier;
@property (nonatomic, retain) NSNumber *isRootFolder;
@property (nonatomic, retain) NSString *serviceID;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSSet *childFolders;
@property (nonatomic, retain) NSSet *feeds;
@property (nonatomic, retain) RSDataFolder *parentFolder;

+ (RSDataFolder *)insertFolderInManagedObjectContext:(NSManagedObjectContext *)moc;

@end


@interface RSDataFolder (CoreDataGeneratedAccessors)
- (void)addChildFoldersObject:(RSDataFolder *)value;
- (void)removeChildFoldersObject:(RSDataFolder *)value;
- (void)addChildFolders:(NSSet *)value;
- (void)removeChildFolders:(NSSet *)value;

- (void)addFeedsObject:(RSDataFeed *)value;
- (void)removeFeedsObject:(RSDataFeed *)value;
- (void)addFeeds:(NSSet *)value;
- (void)removeFeeds:(NSSet *)value;

@end
