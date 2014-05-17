//
//  photoSharingViewController.h
//  FinalProject3
//
//  Created by Kevin Bhayani on 12/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//


/* 
 Sender Program. Both networking and UI for the sender (client) is done here.
 Ideally networking code should have been as a separate model. 
 */

#import <UIKit/UIKit.h>
#include "ImageScrollView.h"

enum {
    BUF_SIZE = 65536
};


@interface photoSharingViewController : UIViewController <NSStreamDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate>
{

    uint8_t                     _buffer[BUF_SIZE];

}

@property (nonatomic, retain) UIImagePickerController *imgPicker;
- (NSData *) setupImage: (UIImage *) image ;    
- (void) connect: (NSData *) data;
- (void) disconnect: (NSData *) data;

@end
