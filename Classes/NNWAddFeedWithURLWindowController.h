//
//  NNWAddFeedWithURLViewController.h
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class NNWSubscriber;
@class NNWSubscribeRequest;

@interface NNWAddFeedWithURLWindowController : NSWindowController {
@private
	NNWSubscriber *subscriber;
	NSPopUpButton *folderPopupButton;
	NSString *initialURLString;
	NNWSubscribeRequest *initialSubscribeRequest;
	NSTextField *titleTextField;
	NSTextField *urlTextField;
}


@property (nonatomic, retain) IBOutlet NSPopUpButton *folderPopupButton;
@property (nonatomic, retain) IBOutlet NSTextField *titleTextField;
@property (nonatomic, retain) IBOutlet NSTextField *urlTextField;

- (id)initWithURLString:(NSString *)aURLString; //caller may have grabbed URL from pasteboard, for instance
- (id)initWithSubscribeRequest:(NNWSubscribeRequest *)aSubscribeRequest;

@end
