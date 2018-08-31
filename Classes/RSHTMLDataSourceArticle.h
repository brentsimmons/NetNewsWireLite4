//
//  RSHTMLDataSourceArticle.h
//  nnw
//
//  Created by Brent Simmons on 12/18/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class RSDataArticle;


@interface RSHTMLDataSourceArticle : NSObject {
@private
	RSDataArticle *article;
}


- (id)initWithArticle:(RSDataArticle *)anArticle; //anArticle may be nil -- everything gets replaced with @""


@end
