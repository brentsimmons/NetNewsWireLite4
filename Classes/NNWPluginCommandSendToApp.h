//
//  NNWSendToAppCommand.h
//  nnw
//
//  Created by Brent Simmons on 1/3/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSPluginProtocols.h"


extern NSString *NNWSendToAppBundleIDKey;

/*Identifies a single app and how to send to it.*/

@interface NNWSendToAppSpecifier : NSObject {
@private
    BOOL appExistsOnDisk;
    BOOL usesAPI;
    BOOL usesURLScheme;
    NSImage *icon;
    NSString *URLSchemeTemplate;
    NSString *appBundleID;
    NSString *appName;
    NSString *appPath;
}

/*ConfigInfo is either a string or a dictionary. If string, it should be the bundleID.*/

- (id)initWithAppName:(NSString *)anAppName configInfo:(id)configInfo;

@property (nonatomic, assign, readonly) BOOL appExistsOnDisk;
@property (nonatomic, assign, readonly) BOOL usesAPI; /* http://ranchero.com/netnewswire/developers/externalinterface */
@property (nonatomic, assign, readonly) BOOL usesURLScheme;
@property (nonatomic, strong, readonly) NSImage *icon;
@property (nonatomic, strong, readonly) NSString *URLSchemeTemplate;
@property (nonatomic, strong, readonly) NSString *appBundleID;
@property (nonatomic, strong, readonly) NSString *appName;
@property (nonatomic, strong, readonly) NSString *appPath;


@end


@interface NNWPluginCommandSendToApp : NSObject <RSPluginCommand> {
@private
    NNWSendToAppSpecifier *sendToAppSpecifier;
    id<RSSharableItem> sharableItem;
}


- (id)initWithAppSpecifier:(NNWSendToAppSpecifier *)aSendToAppSpecifier;

@property (nonatomic, strong, readonly) NNWSendToAppSpecifier *sendToAppSpecifier;

@end
