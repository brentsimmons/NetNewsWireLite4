//
//  RSPluginCommand.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/19/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSPluginCommand.h"


@implementation RSPluginCommand

@synthesize representedCommand;
@synthesize tag;
@synthesize pluginType;


#pragma mark Init

- (id)initWithRSPluginCommand:(id<RSPluginCommand>)command tag:(NSInteger)aTag pluginType:(NSInteger)aPluginType {
	self = [super init];
	if (self == nil)
		return nil;
	representedCommand = [(id)command retain];
	tag = aTag;
	pluginType = aPluginType;
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[(id)representedCommand release];
	[super dealloc];
}


#pragma mark Validation

- (BOOL)validateCommandWithArray:(NSArray *)items {
	return [self.representedCommand validateCommandWithArray:items];
}


#pragma mark Perform

- (BOOL)performCommandWithArray:(NSArray *)itemsArray error:(NSError **)error {
	return [self.representedCommand performCommandWithArray:itemsArray error:error];
}


@end
