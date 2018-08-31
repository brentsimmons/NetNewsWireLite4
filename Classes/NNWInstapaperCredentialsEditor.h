//
//  NNWInstapaperCredentialsEditor.h
//  nnw
//
//  Created by Brent Simmons on 1/16/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString *NNWInstapaperAccountUsernameKey;

@interface NNWInstapaperCredentialsEditor : NSObject {

}

- (BOOL)editInstapaperCredentials; //return NO if canceled

@property (nonatomic, strong, readonly) NSString *username;
@property (nonatomic, strong, readonly) NSString *password;


@end
