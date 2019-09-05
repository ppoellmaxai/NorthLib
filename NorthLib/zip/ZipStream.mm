//
//  ZipStream.mm
//  taz
//
//  Copyright (c) 2013 Norbert Thies. All rights reserved.
//

#include "zip.hh"
#import  "ZipStream.h"

class ZipDelegate;

@interface ZipStream ()
@property (copy) void (^onFileClosure)(NSString *, NSData *);
@end

@implementation ZipStream

{
  zip::Stream *_zipStream;
  ZipDelegate *_zipStreamDelegate;
}

// Getters and setters

- (ZipDelegate *) zipStreamDelegate {
  if ( !_zipStreamDelegate ) {
    _zipStreamDelegate = new ZipDelegate( self );
  }
  return _zipStreamDelegate;
}

- (zip::Stream *) zipStream {
  if ( !_zipStream ) {
    _zipStream = new zip::Stream( *(self.zipStreamDelegate) );
    _bytesReceived = 0;
    _bytesProcessed = 0;
  }
  return _zipStream;
}

- (void) scanData: (NSData *) data {
  self.zipStream -> scan( (const char *) data.bytes, (int) data.length );
  _bytesReceived += data.length;
}

- (void) onFile:(void (^)(NSString *, NSData *))closure {
  self.onFileClosure = closure;
}

- (void) dealloc {
  if ( _zipStream ) delete _zipStream;
  if ( _zipStreamDelegate ) delete _zipStreamDelegate;
}

class ZipDelegate : public zip::StreamDelegate {
private:
  ZipStream *_stream;
public:
  ZipDelegate( ZipStream *stream ) { _stream = stream; };
  void handleFile( zip::File *file );
};

void ZipDelegate::handleFile( zip::File *file ) {
  NSData *data = [NSData dataWithBytes:file->data() length:file->size()];
  NSString *fname = [NSString stringWithUTF8String:file->name()];
  _stream.bytesProcessed = _stream -> _zipStream -> bytesRead();
  if ( _stream -> _onFileClosure ) 
    _stream -> _onFileClosure( fname, data );
  delete file;
}


@end
