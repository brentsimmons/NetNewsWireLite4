//
//  NNWHTMLBuilderArticle.m
//  nnw
//
//  Created by Brent Simmons on 12/18/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWHTMLBuilderArticle.h"
#import "RSDataArticle.h"
#import "RSHTMLBuilder.h"
#import "RSHTMLDataSourceArticle.h"



@interface NNWHTMLBuilderArticle ()

@property (nonatomic, retain) RSDataArticle *article;
@property (nonatomic, retain) NSString *htmlTemplate;
@property (nonatomic, retain) NSString *styleSheetPath;

@end


@implementation NNWHTMLBuilderArticle

@synthesize article;
@synthesize htmlTemplate;
@synthesize includeHTMLFooter;
@synthesize includeHTMLHeader;
@synthesize styleSheetPath;


#pragma mark Init

- (id)initWithArticle:(RSDataArticle *)anArticle htmlTemplate:(NSString *)anHTMLTemplate styleSheetPath:(NSString *)aStyleSheetPath {
	self = [super init];
	if (self == nil)
		return nil;
	article = [anArticle retain];
	htmlTemplate = [anHTMLTemplate retain];
	styleSheetPath = [aStyleSheetPath retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[article release];
	[htmlTemplate release];
	[styleSheetPath release];
	[super dealloc];
}


#pragma mark HTML

- (NSString *)renderedHTML {
	RSHTMLDataSourceArticle *htmlDataSourceArticle = [[[RSHTMLDataSourceArticle alloc] initWithArticle:self.article] autorelease];
	RSHTMLBuilder *htmlBuilder = [[[RSHTMLBuilder alloc] initWithDataSource:htmlDataSourceArticle andHTMLTemplate:self.htmlTemplate] autorelease];
	htmlBuilder.includeHTMLHeader = self.includeHTMLHeader;
	htmlBuilder.includeHTMLFooter = self.includeHTMLFooter;
	htmlBuilder.styleSheetPath = self.styleSheetPath;
	return htmlBuilder.renderedHTML;
}

@end
