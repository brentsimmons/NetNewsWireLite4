//
//  NNWSubscribeRequest.h
//  nnw
//
//  Created by Brent Simmons on 1/5/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSRefreshProtocols.h"

void shutupcompiler(void);

@class RSFolder;


@interface NNWSubscribeRequest : NSObject {
@private
	NSString *title;
	NSURL *feedURL;
	NSWindow *backgroundWindow;
	RSFolder *parentFolder;
	id<RSAccount> account;
}

@property (nonatomic, retain) RSFolder *parentFolder;
@property (nonatomic, retain) id<RSAccount> account;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSURL *feedURL;
@property (nonatomic, retain) NSWindow *backgroundWindow; //because UI gets displayed over the window


@end

