//
//  RSScrollView.h
//  RSCoreTests
//
//  Created by Brent Simmons on 8/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*You can have it hide/show the horizontal scrollbar as needed.*/

@interface RSScrollView : NSScrollView {
	@private
	BOOL showHorizontalScrollbarWhenNeeded;	
}


@property (nonatomic, assign) BOOL showHorizontalScrollbarWhenNeeded;


@end
