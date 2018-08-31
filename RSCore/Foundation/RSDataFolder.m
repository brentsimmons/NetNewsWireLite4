//
//  RSDataFolder.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/8/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDataFolder.h"
#import "RSCoreDataUtilities.h"
#import "RSDataConstants.h"


@implementation RSDataFolder

@dynamic accountIdentifier;
@dynamic isRootFolder;
@dynamic serviceID;
@dynamic title;

@dynamic childFolders;
@dynamic feeds;
@dynamic parentFolder;


+ (RSDataFolder *)insertFolderInManagedObjectContext:(NSManagedObjectContext *)moc {
	return (RSDataFolder *)RSInsertObject(RSDataEntityNameFolder, moc);
}


@end

