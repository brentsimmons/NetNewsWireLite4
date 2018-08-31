//
//  RSFetchTinyURLOperation.h
//  ModalView
//
//  Created by Nick Harris on 3/13/10.
//  Copyright 2010 Sirrahsoft LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSDownloadOperation.h"


/*This should have a superclass, so we have a single API for creating shortened URLs.
 Or maybe this should be a single class that handles different services. We'll have to look
 to see how different they all are.
 In addition, we should probably have a cache for shortened URLs -- for looking them up.
 But that's for another day.*/

extern NSString *RSFetchShortenedURLOperationDidComplete;
extern NSString *RSFetchShortenedURLOperationDidFail;

/*userInfo keys*/
extern NSString *RSOriginalURLKey;
extern NSString *RSShortenedURLKey;

@interface RSFetchTinyURLOperation : RSDownloadOperation {
@private
	NSString *shortenedURLString;
	NSString *originalURLString;
}

@property (nonatomic, retain) NSString *shortenedURLString;
@property (nonatomic, retain) NSString *originalURLString;

- (id)initWithOriginalURLString:(NSString *)anOriginalURLString;


@end
