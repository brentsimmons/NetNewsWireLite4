/*
 *  RSPlatformDefines.h
 *  padlynx
 *
 *  Created by Brent Simmons on 10/15/10.
 *  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
 *
 */

#if TARGET_OS_IPHONE

#define RS_PLATFORM_IMAGE UIImage
#define RS_PLATFORM_WINDOW UIWindow
#define RS_PLATFORM_VIEW UIView
#define RS_PLATFORM_VIEWCONTROLLER UIViewController

#else //Mac

#define RS_PLATFORM_IMAGE NSImage
#define RS_PLATFORM_WINDOW NSWindow
#define RS_PLATFORM_VIEW NSView
#define RS_PLATFORM_VIEWCONTROLLER NSViewController

#endif
