//
//  NNWHTMLBuilderArticle.h
//  nnw
//
//  Created by Brent Simmons on 12/18/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class RSDataArticle;


@interface NNWHTMLBuilderArticle : NSObject {
@private
	BOOL includeHTMLFooter;
	BOOL includeHTMLHeader;
	NSString *htmlTemplate;
	NSString *styleSheetPath;
	RSDataArticle *article;
}

- (id)initWithArticle:(RSDataArticle *)anArticle htmlTemplate:(NSString *)anHTMLTemplate styleSheetPath:(NSString *)aStyleSheetPath;

@property (nonatomic, assign) BOOL includeHTMLFooter;
@property (nonatomic, assign) BOOL includeHTMLHeader;

@property (nonatomic, retain, readonly) NSString *renderedHTML; //re-renders each time, in case properties changed

@end
