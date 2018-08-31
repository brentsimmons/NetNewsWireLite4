//
//  NNWArticleContent.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/8/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDataArticleContent.h"


@implementation RSDataArticleContent

@dynamic htmlText;
@dynamic xmlBaseURL;

@dynamic article;

static NSString *NNWArticleContentEntityName = @"ArticleContent";

+ (RSDataArticleContent *)createArticleContentInManagedObjectContext:(NSManagedObjectContext *)moc {
	return (RSDataArticleContent *)[NSEntityDescription insertNewObjectForEntityForName:NNWArticleContentEntityName inManagedObjectContext:moc];
}


@end
