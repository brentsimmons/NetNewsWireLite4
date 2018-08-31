//
//  NNWSendToAppPlugin.h
//  nnw
//
//  Created by Brent Simmons on 1/3/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSPluginProtocols.h"


@interface NNWSharingPluginSendToApp : NSObject <RSPlugin> {
@private
	NSArray *allCommands;
	id<RSPluginHelper> pluginHelper;
}

@end
