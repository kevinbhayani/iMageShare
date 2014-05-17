//
//  ImageScrollView.m
//  FinalProject3
//
//  Created by Kevin Bhayani on 12/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

/* Creates a custom scroll view such that image is centered and zooming is correct. Parts such as image centering taken from sample ios apps */

#import "ImageScrollView.h"
@interface ImageScrollView(){
UIView        *imageView;
}
@end

@implementation ImageScrollView

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;        
    }
    return self;
}


- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = imageView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    imageView.frame = frameToCenter;
    
    
}

//Delegate callback fir zooming
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return imageView;
}

- (void)imageSetup:(UIImage *)image
{
    // clear the previous image
    [imageView removeFromSuperview];
    imageView = nil;
    self.zoomScale = 1.0;
    
    //New Image View
    imageView = [[UIImageView alloc] initWithImage:image];
    //Add this to the scrollview
    [self addSubview:imageView];
    
    self.contentSize = [image size];
    CGFloat minScale = MIN(self.bounds.size.width/imageView.bounds.size.width, self.bounds.size.height/imageView.bounds.size.height);           
    CGFloat maxScale = 1.0 / [[UIScreen mainScreen] scale];
    
    //Scale should never be more than  minimum scale
    if (minScale > maxScale) 
        minScale = maxScale;
    
    
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;

    self.zoomScale = self.minimumZoomScale;
}




  
   







@end
