//
//  RSPluginCommand.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/19/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSPluginProtocols.h"


@interface RSPluginCommand : NSObject {
@private
	id<RSPluginCommand> representedCommand;
	NSInteger tag;
	NSInteger pluginType;
}


- (id)initWithRSPluginCommand:(id<RSPluginCommand>)command tag:(NSInteger)aTag pluginType:(NSInteger)aPluginType;

@property (nonatomic, retain) id<RSPluginCommand> representedCommand;
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, assign) NSInteger pluginType;

- (BOOL)validateCommandWithArray:(NSArray *)items;
- (BOOL)performCommandWithArray:(NSArray *)itemsArray error:(NSError **)error;
	
@end
