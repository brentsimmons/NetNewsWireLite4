//
//  NNWMainWindowContentView.h
//  NetNewsWire
//
//  Created by Brent Simmons on 9/29/06.
//  Copyright 2006 Ranchero Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSContainerView.h"


@interface RSMainWindowContentView : RSContainerView {
@private
	NSViewController *principalViewController;
}


@property (nonatomic, retain, readonly) NSViewController *principalViewController;

@end
