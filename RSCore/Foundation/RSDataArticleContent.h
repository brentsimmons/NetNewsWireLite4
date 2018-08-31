//
//  NNWArticleContent.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/8/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@class RSDataArticle;

@interface RSDataArticleContent : NSManagedObject {

}

@property (nonatomic, strong) NSString *htmlText;
@property (nonatomic, strong) NSString *xmlBaseURL;

@property (nonatomic, strong) RSDataArticle *article;

+ (RSDataArticleContent *)createArticleContentInManagedObjectContext:(NSManagedObjectContext *)moc;


@end

