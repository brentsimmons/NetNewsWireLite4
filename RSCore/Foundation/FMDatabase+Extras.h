/*
	FMDatabase+Extras.h
	NetNewsWire

	Created by Brent Simmons on 5/30/06.
	Copyright 2006 Ranchero Software. All rights reserved.
*/


#import <Foundation/Foundation.h>
#import "FMDatabase.h"


@interface FMDatabase (Extras)


+ (FMDatabase *)openDatabaseWithPath:(NSString *)f;


@end

FMDatabase *FMDBOpenDatabaseWithPath(NSString *f); //linker doesn't like categories sometimes, but it's good with C

