//
//  NNWSendToInstapaper.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 6/20/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NNWInstapaperCredentialsViewController.h"


@class NNWInstapaperCredentialsViewControllerm, NGModalViewPresenter;

@interface NNWSendToInstapaper : NSObject <NNWCredentialsSheetDelegate> {
@private
	NSDictionary *_infoDict;
	id _callbackTarget;
	NSURLConnection *_urlConnection;
	int _statusCode;
	NNWInstapaperCredentialsViewController *_credentialsController;
	NSString *_feedbackOperationIdentifier; /*for feedback window, to identify this operation*/
	NGModalViewPresenter *_modalViewPresenter;
}


- (id)initWithInfoDict:(NSDictionary *)infoDict callbackTarget:(id)callbackTarget;
- (void)run;


@end
