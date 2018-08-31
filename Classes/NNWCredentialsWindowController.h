//
//  NNWCredentialsWindowController.h
//  nnw
//
//  Created by Brent Simmons on 12/29/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*To run a modal credentials window:
 
 1. Create the window controller: wc = [[[NNWCredentialsWindowController alloc] init] autorelease];
 
 2. Set initial username and password: wc.username = something; wc.password = something
 
 3. If you want to change anything in imageView, messageTextField, usernameTextField, or passwordTextField,
 load the window first: [wc window]; [wc.imageView setImage:someImage]; etc.
 
 You probably *do* want to set the text in messageTextField.
 
 4. Call runModalForBackgroundWindow:someWindow to run it. (The backgroundWindow may be nil.)
 
 5. The runModalForBackgroundWindow method will return an NNWCredentialsResult, which is what you want.
 It may return nil -- if it couldn't run, because another modal thing is happening, then it will return nil.*/
 

@interface NNWCredentialsResult : NSObject {
@private
    BOOL userDidCancel;
    NSString *password;
    NSString *username;
}

@property (assign) BOOL userDidCancel;
@property (copy) NSString *password;
@property (copy) NSString *username;

@end


#pragma mark -


@interface NNWCredentialsWindowController : NSWindowController {
@private
    BOOL userDidCancel;
    NSImageView *imageView;
    NSString *password;
    NSString *username;
    NSTextField *messageTextField;
    NSTextField *passwordTextField;
    NSTextField *usernameTextField;
}

@property (strong) IBOutlet NSImageView *imageView;
@property (strong) IBOutlet NSTextField *messageTextField;
@property (strong) IBOutlet NSTextField *passwordTextField;
@property (strong) IBOutlet NSTextField *usernameTextField;

@property (strong) NSString *username; //username and password are bound to usernameTextField and passwordTextField
@property (strong) NSString *password;

- (NNWCredentialsResult *)runModalForBackgroundWindow:(NSWindow *)aBackgroundWindow; //aBackgroundWindow may be nil

@end


