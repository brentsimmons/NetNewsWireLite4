//
//  NNWDownloadsSQLite3DatabaseController.h
//  NetNewsWire
//
//  Created by Brent Simmons on 4/2/08.
//  Copyright 2008 NewsGator Technologies, Inc. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "RSSQLiteDatabaseController.h"


/*For remembering files downloaded -- enclosures downloaded by NetNewsWire/Mac, for instance*/

void RSDownloadsDatabaseAddURL(NSString *url);
void RSDownloadsDatabaseRemoveURL(NSString *url);
BOOL RSDownloadsDatabaseDidDownloadURL(NSString *url);


@interface RSDownloadsDatabase : RSSQLiteDatabaseController {
@private
	pthread_mutex_t databaseLock;

}

@end


