//
//  Facebook+RSCore.h
//  padlynx
//
//  Created by Brent Simmons on 10/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FBConnect.h"


/*Have to do at least one C method to get categories here to load
 because of that stupid business with static libraries and Objective-C
 linking and categories.*/

/*hostViewController specifies a view controller with a host view.*/

void RSFacebookAuthorize(Facebook *facebook, NSString *applicationID, NSArray *permissions, id<FBSessionDelegate>delegate, UIViewController *hostViewController);

	
@interface Facebook (RSCore)

- (void)authorize:(NSString*)application_id permissions:(NSArray*)permissions delegate:(id<FBSessionDelegate>)delegate hostViewController:(UIViewController *)hostViewController;

@end


@interface FBDialog (RSCore)

- (void)showWithHostViewController:(UIViewController *)viewController;

@end
