//
//  NNWGoogleUtilities.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/6/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *NNWGoogleClientName;


@interface NNWGoogleUtilities : NSObject {

}

+ (NSURL *)urlWithClientAppended:(NSString *)urlString;

@end
