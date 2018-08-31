//
//  NNWAddFolderViewController.h
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NNWAddFolderWindowController : NSWindowController {
@private
	NSTextField *folderNameTextField;
}


@property (nonatomic, retain) IBOutlet NSTextField *folderNameTextField;


@end
