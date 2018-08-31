//
//  NNWPluginCommandSendToInstapaper.h
//  nnw
//
//  Created by Brent Simmons on 1/16/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSPluginProtocols.h"


@class NNWSendToInstapaper;

@interface NNWPluginCommandSendToInstapaper : NSObject <RSPluginCommand> {
@private
	id<RSPluginHelper> pluginHelper;
	NNWSendToInstapaper *sendToInstapaper;
}

@end
