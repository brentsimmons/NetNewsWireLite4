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


@property (nonatomic, retain) NSNumber *bitRate;
@property (nonatomic, retain) NSNumber *fileSize;
@property (nonatomic, retain) NSNumber *height;
@property (nonatomic, retain) NSNumber *mediaType;
@property (nonatomic, retain) NSString *medium;
@property (nonatomic, retain) NSString *mimeType;
@property (nonatomic, retain) NSString *URL;
@property (nonatomic, retain) NSNumber *width;

@property (nonatomic, retain) NSSet *articles;

+ (NSSet *)enclosuresWithArrayOfParsedEnclosures:(NSArray *)parsedEnclosures moc:(NSManagedObjectContext *)moc;

@end


@interface RSDataEnclosure (CoreDataGeneratedAccessors)

- (void)addArticlesObject:(RSDataArticle *)value;
- (void)removeArticlesObject:(RSDataArticle *)value;
- (void)addArticles:(NSSet *)value;
- (void)removeArticles:(NSSet *)value;

@end
