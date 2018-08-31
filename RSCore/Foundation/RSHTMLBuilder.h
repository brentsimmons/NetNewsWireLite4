//
//  RSHTMLBuilder.h
//  nnw
//
//  Created by Brent Simmons on 12/18/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RSHTMLBuilder : NSObject {
@private
	BOOL includeHTMLFooter;
	BOOL includeHTMLHeader;
	NSString *htmlTemplate;
	NSString *renderedHTML;
	NSString *styleSheetPath;
	id dataSource;
}

- (id)initWithDataSource:(id)aDataSource andHTMLTemplate:(NSString *)anHTMLTemplate;

@property (nonatomic, assign) BOOL includeHTMLFooter;
@property (nonatomic, assign) BOOL includeHTMLHeader;
@property (nonatomic, retain) NSString *styleSheetPath;

@property (nonatomic, retain, readonly) NSString *renderedHTML;


@end
