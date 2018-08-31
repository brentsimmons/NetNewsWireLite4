//
//  NNWSendToInstapaper.h
//  nnw
//
//  Created by Brent Simmons on 1/16/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSPluginProtocols.h"


/*Does the actual work of calling Instapaper.*/

@class NNWInstapaperCredentialsEditor;

@interface NNWSendToInstapaper : NSObject {
@private
    NNWInstapaperCredentialsEditor *instapaperCredentialsEditor;
    NSString *password;
    NSString *username;
    SEL callbackSelector;
    id callbackTarget;
    id<RSSharableItem> sharableItem;
    id<RSPluginHelper> pluginHelper;
    NSURLConnection *URLConnection;
    NSInteger statusCode;
    BOOL runningFeedbackWindow;
}


- (id)initWithSharableItem:(id<RSSharableItem>)aSharableItem pluginHelper:(id<RSPluginHelper>)aPluginHelper callbackTarget:(id)aCallbackTarget callbackSelector:(SEL)aCallbackSelector;
- (void)sendToInstapaper;

@property (nonatomic, assign, readonly) BOOL didSucceed;
@property (nonatomic, strong, readonly) id<RSSharableItem> sharableItem;

@end

