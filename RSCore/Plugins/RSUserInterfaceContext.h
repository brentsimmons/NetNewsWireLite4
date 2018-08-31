//
//  RSUserInterfaceContext.h
//  padlynx
//
//  Created by Brent Simmons on 10/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif
#import "RSPluginProtocols.h"


@interface RSUserInterfaceContext : NSObject <RSUserInterfaceContext> {
@private
#if TARGET_OS_IPHONE
	UIWindow *window;
	UIViewController *rootViewController;
	UIViewController *hostViewController;
	UIEvent *event;
	UIView *view;
	UIControl *control;
	UIBarButtonItem *barButtonItem;
#else
	NSWindow *window;
	NSViewController *rootViewController;
	NSViewController *hostViewController;
	NSEvent *event;
	NSView *view;
	NSControl *control;
#endif
}


+ (RSUserInterfaceContext *)contextWithViewController:(id)aViewController view:(id)aView control:(id)aControl barButtonItem:(id)barButtonItem event:(id)anEvent;
- (RSUserInterfaceContext *)initWithViewController:(id)aViewController view:(id)aView control:(id)aControl barButtonItem:(id)aBarButtonItem event:(id)anEvent;


@end
