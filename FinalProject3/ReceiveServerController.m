//
//  ReceiveServerController.m
//  FinalProject3
//
//  Created by Kevin Bhayani on 12/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

/* 
 =====================================================================================================================================================================
 All of the networking code in this file has been copied/pasted from an ios sample app (MVC networking sample)
 
 code has been added to this file such that we receive image and present it. Hence this is a subclass of UIViewcontroller
 
 =====================================================================================================================================================================
*/


#import "ReceiveServerController.h"
#include "ImageScrollView.h"
#import "AssetsLibrary/AssetsLibrary.h"
#include <CFNetwork/CFNetwork.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

@interface ReceiveServerController ()

// Properties that don't need to be seen by the outside world.

@property (nonatomic, readonly) BOOL                isStarted;
@property (nonatomic, readonly) BOOL                isReceiving;
@property (nonatomic, retain)   NSNetService *      netService;
@property (nonatomic, assign)   CFSocketRef         listeningSocket;
@property (nonatomic, retain)   NSInputStream *     networkStream;
@property (nonatomic, retain)   NSOutputStream *    fileStream;
@property (nonatomic, copy)     NSString *          filePath;

@property (nonatomic, strong)  UIImage *              currentImage;


// Forward declarations

- (void)_stopServer:(NSString *)reason;

@end

@implementation ReceiveServerController
@synthesize currentImage = _currentImage;
#pragma mark * Status management

// These methods are used by the core transfer code to update the UI.

- (void)_serverDidStartOnPort:(int)port
{
    assert( (port > 0) && (port < 65536) );
}

- (void)_serverDidStopWithReason:(NSString *)reason
{
    if (reason == nil) {
        reason = @"Stopped";
    }

}

/* ============================= BELOW IS THE UI RELATED CODE ADDED TO THIS FILE=============================================================== */

- (void)_receiveDidStopWithStatus:(NSString *)statusString
{
    if (statusString == nil) {
        assert(self.filePath != nil);
       // self.imageView.image = [UIImage imageWithContentsOfFile:self.filePath];
        
        //ImageScrollView *one = [[ImageScrollView alloc] initWithFrame:self.view.bounds];
        //[one imageSetup:[UIImage imageWithContentsOfFile:self.filePath]];
        //[self.view addSubview:one];
        // UIImage *img = [UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"nature-beauty" ofType:@"jpg"]];
        //[self.view addSubview:self.imageView];
        
        //    [self.imageView setImage:img];
        //	self.imageView = [[UIImageView alloc] initWithImage:img];
        //	[self.imageView setUserInteractionEnabled:NO];	
        //  NSLog(@"I am here");
        
        
        // self.imageView.image =  [UIImage imageNamed:@"nature-beauty.jpg"];
        //[self.view addSubview:self.imageView];
        
        if([self.view subviews].count > 1)
        {
        
           [[[self.view subviews] objectAtIndex:1 ] removeFromSuperview]; 
        }
        
        
        ImageScrollView *one = [[ImageScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 50.0)];
        self.currentImage = [UIImage imageWithContentsOfFile:self.filePath];

        [one imageSetup:self.currentImage];
        [self.view addSubview:one];

        
       self.currentImage = [UIImage imageWithContentsOfFile:self.filePath];
    /*
            UIImageView *imageView = [[UIImageView alloc] initWithImage:self.currentImage]; 
        
        UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        scrollView.contentMode = UIViewContentModeTopLeft;
        scrollView.contentSize = self.currentImage.size;
        
         [scrollView addSubview:imageView] ;
        [self.view addSubview:scrollView];
    */
         
        statusString = @"Receive succeeded";
    }
}

/* ============================= BELOW IS THE CODE WHERE I TRIED TO USE ASSET LIBRARY. I MAKE USE OF IT TO SAVE IMAGE THAT IS REVCEIVED TO DISK =================== */


- (IBAction)saveImageToDisk:(id)sender 
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init]; 
        
    [library writeImageToSavedPhotosAlbum:[self.currentImage CGImage] orientation:ALAssetOrientationUp completionBlock:^(NSURL *newURL, NSError *error) {
    }   ];

    
}


/* 
 ====================================================================================================ALL NETWORKING CODE BELOW COPIED/PASTED FROM IOS SAMPLE APP
 ====================================================================================================
*/
@synthesize netService      = _netService;
@synthesize networkStream   = _networkStream;
@synthesize listeningSocket = _listeningSocket;
@synthesize fileStream      = _fileStream;
@synthesize filePath        = _filePath;

- (BOOL)isStarted
{
    return (self.netService != nil);
}

- (BOOL)isReceiving
{
    return (self.networkStream != nil);
}

// Have to write our own setter for listeningSocket because CF gets grumpy 
// if you message NULL.

- (void)setListeningSocket:(CFSocketRef)newValue
{
    if (newValue != self->_listeningSocket) {
        if (self->_listeningSocket != NULL) {
            CFRelease(self->_listeningSocket);
        }
        self->_listeningSocket = newValue;
        if (self->_listeningSocket != NULL) {
            CFRetain(self->_listeningSocket);
        }
    }
}
- (NSString *)pathForTemporaryFileWithPrefix:(NSString *)prefix
{
    NSString *  result;
    CFUUIDRef   uuid;
    CFStringRef uuidStr;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFUUIDCreateString(NULL, uuid);
    assert(uuidStr != NULL);
    
    result = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@", prefix, uuidStr]];
    assert(result != nil);
    
    CFRelease(uuidStr);
    CFRelease(uuid);
    
    return result;
}

- (void)_startReceive:(int)fd
{
    CFReadStreamRef     readStream;
    
    assert(fd >= 0);

    assert(self.networkStream == nil);      // can't already be receiving
    assert(self.fileStream == nil);         // ditto
    assert(self.filePath == nil);           // ditto

    // Open a stream for the file we're going to receive into.

    self.filePath = [self pathForTemporaryFileWithPrefix:@"Receive"];
    assert(self.filePath != nil);

    self.fileStream = [NSOutputStream outputStreamToFileAtPath:self.filePath append:NO];
    assert(self.fileStream != nil);
    
    [self.fileStream open];

    // Open a stream based on the existing socket file descriptor.  Then configure 
    // the stream for async operation.

    CFStreamCreatePairWithSocket(NULL, fd, &readStream, NULL);
    assert(readStream != NULL);
    
    self.networkStream = (__bridge NSInputStream *) readStream;
    
    CFRelease(readStream);

    [self.networkStream setProperty:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket];

    self.networkStream.delegate = self;
    [self.networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.networkStream open];

    // Tell the UI we're receiving.
    
}

- (void)_stopReceiveWithStatus:(NSString *)statusString
{
    if (self.networkStream != nil) {
        self.networkStream.delegate = nil;
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.networkStream close];
        self.networkStream = nil;
    }
    if (self.fileStream != nil) {
        [self.fileStream close];
        self.fileStream = nil;
    }
    [self _receiveDidStopWithStatus:statusString];
    self.filePath = nil;
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
    // An NSStream delegate callback that's called when events happen on our 
    // network stream.
{
    #pragma unused(aStream)
    assert(aStream == self.networkStream);

    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
        } break;
        case NSStreamEventHasBytesAvailable: {
            NSInteger       bytesRead;
            uint8_t         buffer[65536];


            // Pull some data off the network.
            
            bytesRead = [self.networkStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead == -1) {
                [self _stopReceiveWithStatus:@"Network read error"];
            } else if (bytesRead == 0) {
                [self _stopReceiveWithStatus:nil];
            } else {
                NSInteger   bytesWritten;
                NSInteger   bytesWrittenSoFar;

                // Write to the file.
                
                bytesWrittenSoFar = 0;
                do {
                    bytesWritten = [self.fileStream write:&buffer[bytesWrittenSoFar] maxLength:bytesRead - bytesWrittenSoFar];
                    assert(bytesWritten != 0);
                    if (bytesWritten == -1) {
                        [self _stopReceiveWithStatus:@"File write error"];
                        break;
                    } else {
                        bytesWrittenSoFar += bytesWritten;
                    }
                } while (bytesWrittenSoFar != bytesRead);
            }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventErrorOccurred: {
            [self _stopReceiveWithStatus:@"Stream open error"];
        } break;
        case NSStreamEventEndEncountered: {
            
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (void)_acceptConnection:(int)fd
{
    int     junk;

    // If we already have a connection, reject this new one.  This is one of the 
    // big simplifying assumptions in this code.  A real server should handle 
    // multiple simultaneous connections.

    if ( self.isReceiving ) {
        junk = close(fd);
        assert(junk == 0);
    } else {
        [self _startReceive:fd];
    }
}

static void AcceptCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
    // Called by CFSocket when someone connects to our listening socket.  
    // This implementation just bounces the request up to Objective-C.
{
    ReceiveServerController *  obj;
    
    #pragma unused(type)
    assert(type == kCFSocketAcceptCallBack);
    #pragma unused(address)
    // assert(address == NULL);
    assert(data != NULL);
    
    obj = (__bridge ReceiveServerController *) info;
    assert(obj != nil);

    #pragma unused(s)
    assert(s == obj->_listeningSocket);
    
    [obj _acceptConnection:*(int *)data];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
    // A NSNetService delegate callback that's called if our Bonjour registration 
    // fails.  We respond by shutting down the server.
    //
    // This is another of the big simplifying assumptions in this sample. 
    // A real server would use the real name of the device for registrations, 
    // and handle automatically renaming the service on conflicts.  A real 
    // client would allow the user to browse for services.  To simplify things 
    // we just hard-wire the service name in the client and, in the server, fail 
    // if there's a service name conflict.
{
    #pragma unused(sender)
    assert(sender == self.netService);
    #pragma unused(errorDict)
    
    [self _stopServer:@"Registration failed"];
}

- (void)_startServer
{
    BOOL        success;
    int         err;
    int         fd;
    int         junk;
    struct sockaddr_in addr;
    int         port;
    
    // Create a listening socket and use CFSocket to integrate it into our 
    // runloop.  We bind to port 0, which causes the kernel to give us 
    // any free port, then use getsockname to find out what port number we 
    // actually got.

    port = 0;
    
    fd = socket(AF_INET, SOCK_STREAM, 0);
    success = (fd != -1);
    
    if (success) {
        memset(&addr, 0, sizeof(addr));
        addr.sin_len    = sizeof(addr);
        addr.sin_family = AF_INET;
        addr.sin_port   = 0;
        addr.sin_addr.s_addr = INADDR_ANY;
        err = bind(fd, (const struct sockaddr *) &addr, sizeof(addr));
        success = (err == 0);
    }
    if (success) {
        err = listen(fd, 5);
        success = (err == 0);
    }
    if (success) {
        socklen_t   addrLen;

        addrLen = sizeof(addr);
        err = getsockname(fd, (struct sockaddr *) &addr, &addrLen);
        success = (err == 0);
        
        if (success) {
            assert(addrLen == sizeof(addr));
            port = ntohs(addr.sin_port);
        }
    }
    if (success) {
        CFSocketContext context = { 0, (__bridge void*)self, NULL, NULL, NULL };
        
        self.listeningSocket = CFSocketCreateWithNative(
            NULL, 
            fd, 
            kCFSocketAcceptCallBack, 
            AcceptCallback, 
            &context
        );
        success = (self.listeningSocket != NULL);
        
        if (success) {
            CFRunLoopSourceRef  rls;
            
            CFRelease(self.listeningSocket);        // to balance the create

            fd = -1;        // listeningSocket is now responsible for closing fd

            rls = CFSocketCreateRunLoopSource(NULL, self.listeningSocket, 0);
            assert(rls != NULL);
            
            CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
            
            CFRelease(rls);
        }
    }

    // Now register our service with Bonjour.  See the comments in -netService:didNotPublish: 
    // for more info about this simplifying assumption.
    
    if (success) {
        self.netService = [[NSNetService alloc] initWithDomain:@"local." type:@"_x-SNSUpload._tcp." name:@"Test2" port:port];
        success = (self.netService != nil);
    }
    if (success) {
        self.netService.delegate = self;
        
        [self.netService publishWithOptions:NSNetServiceNoAutoRename];
        
        // continues in -netServiceDidPublish: or -netService:didNotPublish: ...
    }
    
    // Clean up after failure.
    
    if ( success ) {
        assert(port != 0);
        [self _serverDidStartOnPort:port];
    } else {
        [self _stopServer:@"Start failed"];
        if (fd != -1) {
            junk = close(fd);
            assert(junk == 0);
        }
    }
}

- (void)_stopServer:(NSString *)reason
{
    if (self.isReceiving) {
        [self _stopReceiveWithStatus:@"Cancelled"];
    }
    if (self.netService != nil) {
        [self.netService stop];
        self.netService = nil;
    }
    if (self.listeningSocket != NULL) {
        CFSocketInvalidate(self.listeningSocket);
        self.listeningSocket = NULL;
    }
    [self _serverDidStopWithReason:reason];
}


#pragma mark * Actions

- (IBAction)startOrStopAction:(id)sender
{
    #pragma unused(sender)
    if (self.isStarted) {
        [self _stopServer:nil];
    } else {
        [self _startServer];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.isStarted) {
        [self _stopServer:nil];
    } else {
        [self _startServer];
    }

}

- (void)viewDidUnload
{
    [super viewDidUnload];

}



@end
