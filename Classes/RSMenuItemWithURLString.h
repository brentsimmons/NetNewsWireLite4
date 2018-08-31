//
//  RSMenuItemWithURLString.h
//  nnw
//
//  Created by Brent Simmons on 12/31/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*Use IB's User Defined Runtime Attributes to add a urlString with the URL
 that should be opened in front in the web browser.
 
 Benefits:
 
 1. Menu items that open URLs can all be configured in IB. Less code.
 
 2. This allows all URL-opening menu items to have a single action method. (Less code.)
 
 That action method should just open the URL that it gets from the
 menu item. Example:
 
 - (void)openAssociatedURL:(id)sender {
    NSParameterAssert([sender respondsToSelector:@selector(urlString)]);
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[sender valueForKey:@"urlString"]]];
 }
 */


@interface RSMenuItemWithURLString : NSMenuItem {
@private
    NSString *urlString;    
}

@property (nonatomic, strong) NSString *urlString;

@end
