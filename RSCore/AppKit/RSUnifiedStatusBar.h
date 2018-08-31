//
//  NNWStatusBar.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/10/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RSUnifiedStatusBar : NSView {
@protected
	BOOL hasGrabberOnRight;
}


@property (nonatomic, assign) BOOL hasGrabberOnRight;


@end
