//
//  NNWEnclosure.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/8/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@class RSDataArticle;

@interface RSDataEnclosure : NSManagedObject {
}


@property (nonatomic, strong) NSNumber *bitRate;
@property (nonatomic, strong) NSNumber *fileSize;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSNumber *mediaType;
@property (nonatomic, strong) NSString *medium;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) NSString *URL;
@property (nonatomic, strong) NSNumber *width;

@property (nonatomic, strong) NSSet *articles;

+ (NSSet *)enclosuresWithArrayOfParsedEnclosures:(NSArray *)parsedEnclosures moc:(NSManagedObjectContext *)moc;

@end


@interface RSDataEnclosure (CoreDataGeneratedAccessors)

- (void)addArticlesObject:(RSDataArticle *)value;
- (void)removeArticlesObject:(RSDataArticle *)value;
- (void)addArticles:(NSSet *)value;
- (void)removeArticles:(NSSet *)value;

@end
