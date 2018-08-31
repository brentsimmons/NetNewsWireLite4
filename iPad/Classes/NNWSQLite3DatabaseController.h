//
//  NNWSQLite3DatabaseController.h
//  NetNewsWire
//
//  Created by Brent Simmons on 4/1/08.
//  Copyright 2008 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/*For sub-classing only. Shared code for handling a simple SQLite3 database.*/

@class FMDatabase;


@interface NNWSQLite3DatabaseController : NSObject {

	@protected
		NSString *_databaseFilePath;
	NSString *_databaseName;
		BOOL _databaseIsNew;
	}


+ (BOOL)databaseFileExistsOnDisk:(NSString *)databaseName;

- (id)initWithDatabaseFileName:(NSString *)databaseName createTableStatement:(NSString *)createTableStatement;
- (FMDatabase *)database;

- (void)beginTransaction;
- (void)endTransaction;


@end
