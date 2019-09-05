//
//  ZipStream.h
//
//  Copyright (c) 2013 Norbert Thies. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZipStream;

@interface ZipStream : NSObject 

/// current position in zip stream
@property (nonatomic,assign) long bytesProcessed;

/// total number of bytes given to 'scanData'
@property (nonatomic,assign) long bytesReceived;

/// scans the given data for enclosed zipped files
- (void) scanData: (NSData *) data;

/// closure to call when file encountered in zip stream
- (void) onFile: (void (^)(NSString *name, NSData *data1)) closure;

@end
