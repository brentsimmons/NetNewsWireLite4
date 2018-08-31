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

@property (nonatomic, strong) RSDataArticle *article;
@property (nonatomic, strong) NSString *htmlTemplate;
@property (nonatomic, strong) NSString *styleSheetPath;

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
    article = anArticle;
    htmlTemplate = anHTMLTemplate;
    styleSheetPath = aStyleSheetPath;
    return self;
}


#pragma mark Dealloc



#pragma mark HTML

- (NSString *)renderedHTML {
    RSHTMLDataSourceArticle *htmlDataSourceArticle = [[RSHTMLDataSourceArticle alloc] initWithArticle:self.article];
    RSHTMLBuilder *htmlBuilder = [[RSHTMLBuilder alloc] initWithDataSource:htmlDataSourceArticle andHTMLTemplate:self.htmlTemplate];
    htmlBuilder.includeHTMLHeader = self.includeHTMLHeader;
    htmlBuilder.includeHTMLFooter = self.includeHTMLFooter;
    htmlBuilder.styleSheetPath = self.styleSheetPath;
    return htmlBuilder.renderedHTML;
}

@end
