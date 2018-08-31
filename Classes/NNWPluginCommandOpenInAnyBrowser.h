//
//  NNWPluginCommandOpenInBrowser.h
//  nnw
//
//  Created by Brent Simmons on 1/4/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSPluginProtocols.h"


@interface NNWPluginCommandOpenInAnyBrowser : NSObject <RSPluginCommand> {
@private
    NSImage *appIcon;
    NSString *appName;
    NSString *appPath;
    NSString *bundleID;
}


- (id)initWithAppName:(NSString *)anAppName bundleID:(NSString *)aBundleID path:(NSString *)aPath;

@property (nonatomic, strong, readonly) NSImage *appIcon;


@end
