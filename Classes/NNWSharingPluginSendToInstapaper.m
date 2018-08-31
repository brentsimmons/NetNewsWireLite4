//
//  NNWSharingPluginSendToInstapaper.m
//  nnw
//
//  Created by Brent Simmons on 1/16/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSharingPluginSendToInstapaper.h"
#import "NNWPluginCommandSendToInstapaper.h"


@interface NNWSharingPluginSendToInstapaper ()

@property (nonatomic, strong, readwrite) NSArray *allCommands;
@end


@implementation NNWSharingPluginSendToInstapaper

@synthesize allCommands;

#pragma mark Dealloc



#pragma mark RSPlugin

- (BOOL)shouldRegister:(id<RSPluginManager>)pluginManager {
    self.allCommands = [NSArray arrayWithObject:[[NNWPluginCommandSendToInstapaper alloc] init]];
    return YES;
}



@end
