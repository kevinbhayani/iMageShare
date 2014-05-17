//
//  ReceiveServerController.h
//  FinalProject3
//
//  Created by Kevin Bhayani on 12/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//


/* 
 All of the networking code in this file has been copied/pasted from an ios sample app (MVC networking sample)
 
 code has been added to this file such that we receive image and present it. Hence this is a subclass of UIViewcontroller
 
 */

#import <UIKit/UIKit.h>

@interface ReceiveServerController : UIViewController <NSStreamDelegate, NSNetServiceDelegate>
{
    NSNetService *              _netService;
    CFSocketRef                 _listeningSocket;
    NSInputStream *             _networkStream;
    NSOutputStream *            _fileStream;
    NSString *                  _filePath;
}


@end
