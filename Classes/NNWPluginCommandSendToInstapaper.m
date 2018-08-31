//
//  NNWPluginCommandSendToInstapaper.m
//  nnw
//
//  Created by Brent Simmons on 1/16/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWPluginCommandSendToInstapaper.h"
#import "NNWSendToInstapaper.h"


@interface NNWPluginCommandSendToInstapaper ()

@property (nonatomic, strong) id<RSPluginHelper> pluginHelper;
@property (nonatomic, strong) NNWSendToInstapaper *sendToInstapaper;
@end


@implementation NNWPluginCommandSendToInstapaper

@synthesize pluginHelper;
@synthesize sendToInstapaper;

#pragma mark Dealloc



#pragma mark Send to Instapaper Callback

- (void)sendToInstapaperDidComplete:(NNWSendToInstapaper *)aSendToInstapaper {
    if (aSendToInstapaper.didSucceed)
        [self.pluginHelper noteUserDidShareItem:aSendToInstapaper.sharableItem viaServiceIdentifier:@"com.instapaper"];
    self.sendToInstapaper = nil;
}


#pragma mark RSPluginCommand

- (NSString *)commandID {
    return @"com.ranchero.NetNewsWire.plugin.sharing.SendToInstapaper";
}


- (NSString *)title {
    return NSLocalizedStringFromTable(@"Send to Instapaper", @"Instapaper", @"Menu item title");
}


- (NSString *)shortTitle {
    return @"Instapaper";
}


- (NSImage *)image {
    return [NSImage imageNamed:@"toolbar_main_instapaper"];
}


- (NSArray *)commandTypes {
    return [NSArray arrayWithObject:[NSNumber numberWithInteger:RSPluginCommandTypeSharing]];
}


- (BOOL)validateCommandWithArray:(NSArray *)items {
    
    if (items == nil || [items count] != 1)
        return NO;
    id<RSSharableItem> aSharableItem = [items objectAtIndex:0];
    return aSharableItem.URL != nil || aSharableItem.permalink != nil;
}


- (BOOL)performCommandWithArray:(NSArray *)items userInterfaceContext:(id<RSUserInterfaceContext>)userInterfaceContext pluginHelper:(id<RSPluginHelper>)aPluginHelper error:(NSError **)error {
    
    self.pluginHelper = aPluginHelper;
    self.sendToInstapaper = [[NNWSendToInstapaper alloc] initWithSharableItem:[items objectAtIndex:0] pluginHelper:aPluginHelper callbackTarget:self callbackSelector:@selector(sendToInstapaperDidComplete:)];
    [self.sendToInstapaper sendToInstapaper];

    return YES; //well, probably
}


@end
