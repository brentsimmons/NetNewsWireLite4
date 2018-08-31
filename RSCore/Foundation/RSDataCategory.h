//
//  RSDataCategory.h
//  nnw
//
//  Created by Brent Simmons on 11/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RSDataArticle;


@interface RSDataCategory : NSManagedObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSSet *articles;

@end

@interface RSDataCategory (CoreDataGeneratedAccessors)

- (void)addArticlesObject:(RSDataArticle *)value;
- (void)removeArticlesObject:(RSDataArticle *)value;
- (void)addArticles:(NSSet *)value;
- (void)removeArticles:(NSSet *)value;

@end
