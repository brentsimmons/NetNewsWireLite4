//
//  NNWImportOPMLViewController.h
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NNWImportOPMLController  : NSObject {
@private
    NSWindow *backgroundWindow;
    NSString *errorTitle;
    NSString *errorMessage;
    id __unsafe_unretained callbackTarget;
    SEL callbackSelector;
    NSArray *outlineItems;
}


@property (nonatomic, strong) NSWindow *backgroundWindow; //runs as a sheet on this window
@property (nonatomic, strong, readonly) NSArray *outlineItems; //on success, the parsed OPML file

- (void)runChooseOPMLFileSheet:(id)aCallbackTarget callbackSelector:(SEL)aCallbackSelector;


@end
