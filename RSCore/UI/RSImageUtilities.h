//
//  RSImageUtilities.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 10/31/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


/*Do things with CGImageRef.
Mac + iOS. Thread-safe. Requires OS X 10.4 or iOS 4.0.*/


/*If the imageData includes an image smaller than maximumSize, return it.
 Otherwise create a thumbnail where width and height are no greater than maxPixelSize.*/

CGImageRef RSCGImageFromDataWithMaxPixelSize(NSData *imageData, NSInteger maxPixelSize);

/*Creates a thumbnal from largest image in imageData. Doesn't look for an existing image.*/

CGImageRef RSCGImageThumbnailFromImageSourceWithMaxPixelSize(CGImageSourceRef imageSourceRef, NSInteger maxPixelSize);

CGImageRef RSCGImageWithFilePath(NSString *filePath);

CGImageRef RSCGImageInResources(NSString *filename);


