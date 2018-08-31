//
//  NNWFolderProxy.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/24/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNWFeedProxy.h"


@interface NNWFolderProxy : NNWProxy {
@private
	NSArray *_googleIDsOfDescendants;
}

+ (NNWFolderProxy *)folderProxyWithGoogleID:(NSString *)googleID;
+ (NSArray *)folderProxies;
+ (void)updateUnreadCountsForAllFolders;

@property (retain) NSArray *googleIDsOfDescendants;


@end
