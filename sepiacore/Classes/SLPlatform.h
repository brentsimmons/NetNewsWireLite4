/*
 *  SLPlatform.h
 *  nnwiphone
 *
 *  Created by Brent Simmons on 1/30/11.
 *  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
 *
 */


#if TARGET_OS_IPHONE

#define SL_PLATFORM_APPLICATION UIApplication
#define SL_APPLICATION_DELEGATE UIApplicationDelegate
#define SL_PLATFORM_IMAGE UIImage
#define SL_PLATFORM_WINDOW UIWindow
#define SL_PLATFORM_VIEW UIView
#define SL_PLATFORM_VIEWCONTROLLER UIViewController

#else //Mac

#define SL_PLATFORM_APPLICATION NSApplication
#define SL_APPLICATION_DELEGATE NSApplicationDelegate
#define SL_PLATFORM_IMAGE NSImage
#define SL_PLATFORM_WINDOW NSWindow
#define SL_PLATFORM_VIEW NSView
#define SL_PLATFORM_VIEWCONTROLLER NSViewController

#endif

