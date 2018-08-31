//
//  NNWGoogleDatabase.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/18/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNWSQLite3DatabaseController.h"

@interface NNWSyncActionsController : NNWSQLite3DatabaseController {
	@private
	NSThread *_backgroundThread;
	NSTimer *_sendToGoogleTimer;
	BOOL _hasPendingMarkReadChanges;
	BOOL _hasPendingMarkStarredChanges;
}

+ (NNWSyncActionsController *)sharedController;

@property (assign, readonly) BOOL hasPendingMarkReadChanges;
@property (assign, readonly) BOOL hasPendingMarkStarredChanges;

@end
