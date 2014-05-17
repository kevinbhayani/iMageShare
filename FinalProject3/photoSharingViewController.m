//
//  photoSharingViewController.m
//  FinalProject3
//
//  Created by Kevin Bhayani on 12/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

/* 
 Sender Program. Both networking and UI for the sender (client) is done here.
 Ideally networking code should have been as a separate model. 
 */

#import "photoSharingViewController.h"
#import "ImageScrollView.h"

@interface photoSharingViewController()

@property (nonatomic,strong)   NSNetService *    netService;
@property (nonatomic,strong)   NSOutputStream *  networkStream;
@property (nonatomic,strong)   NSInputStream *   fileStream;
@property (nonatomic,readonly) uint8_t *          buffer;
@property (nonatomic)   size_t            bufferOffset;
@property (nonatomic)   size_t            bufferLimit;

@property (weak, nonatomic) IBOutlet UITextField *webAddr;

@end

@implementation photoSharingViewController

@synthesize netService    = _netService;
@synthesize networkStream = _networkStream;
@synthesize fileStream    = _fileStream;
@synthesize bufferOffset  = _bufferOffset;
@synthesize bufferLimit   = _bufferLimit;
@synthesize webAddr = _webAddr;
@synthesize imgPicker = _imgPicker ; 


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (uint8_t *)buffer
{
    return self->_buffer;
}

- (void)disconnect
{
    /* Cleanup */
        self.networkStream.delegate = nil;
        [self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.networkStream close];
        self.networkStream = nil;
        
        [self.netService stop];
        self.netService = nil;
        
        [self.fileStream close];
        self.fileStream = nil;
       
        self.bufferOffset = 0;
        self.bufferLimit  = 0;
}

//Delegate callback if any activity on  stream

/* This method based off sample ios apps for Streams and networking */
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"streaming");
    
    if(eventCode == NSStreamEventHasSpaceAvailable)
    {
        NSLog(@"Sending");
        
        // Read the next chunk of data from filestream to buffer
        
        if (self.bufferOffset == self.bufferLimit) {
            NSInteger   bytesRead;
            
            bytesRead = [self.fileStream read:self.buffer maxLength:BUF_SIZE];
            
            if (bytesRead == -1 || bytesRead ==0 ) {
                [self disconnect];
            } else {
                self.bufferOffset = 0;
                self.bufferLimit  = bytesRead;
            }
        }
        
        //Send next chunk of data 
        if (self.bufferOffset != self.bufferLimit) {
            NSInteger   bytesWritten;
            bytesWritten = [self.networkStream write:&self.buffer[self.bufferOffset] maxLength:self.bufferLimit - self.bufferOffset];
            if (bytesWritten != -1)
                self.bufferOffset += bytesWritten;
            
            
            
        }

    }
    else if (eventCode == NSStreamEventErrorOccurred)
    {
        [self disconnect];
    }
   }



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

//This delegate callback method will hide keyboard when the user presses return
//This is the keyboard that pops up when the textfield for web photos is selected
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{ 
    [self.webAddr resignFirstResponder];
    return NO;
}


- (IBAction)webPhotosPressed:(id)sender {

    
    /* 
     Creates a ViewController and inserts a scroll view with the corresponsing image
      Pushes this onto the navigation controller stack
     */
    UIViewController *tmp = [[UIViewController alloc] init ];
    ImageScrollView *one = [[ImageScrollView alloc] initWithFrame:CGRectMake(0, 0, tmp.view.bounds.size.width, tmp.view.bounds.size.height )];
    NSString *url;
    url = self.webAddr.text ;
    UIImage *image ;
    image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
    [one imageSetup:image];
    
    
    [tmp.view addSubview:one];  

    [self.navigationController pushViewController:tmp animated:YES]; 
    [self connect:[self setupImage:image]];
    

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    //Set the delegate and sample default URL for web Photos
    //Any JPEG file should work here
    self.webAddr.delegate = self; 
    self.webAddr.text = @"http://music.evansville.edu/images/slideshow/global.jpg";   
}


- (void) connect: (NSData *) data {
    
    /* All the networking related stuff goes on here. Currently with Bonjour I am only using local domain. This along with authentication needs to be implemented to make this app more realistic 
     */
    
    /* I connect the input stream with the data (which here is the image and  associate the output stream with the socket 
     */
    
    NSLog(@"connect");
    NSOutputStream *output; 
    BOOL success;
    self.fileStream = [NSInputStream inputStreamWithData:data];
    assert(self.fileStream != nil);
    [self.fileStream open];
    self.netService = [[NSNetService alloc] initWithDomain:@"local." type:@"_x-SNSUpload._tcp." name:@"Test2"];
    success = [self.netService getInputStream:NULL outputStream:&output];
    assert(success);
    self.networkStream = output;
    
    self.networkStream.delegate = self;
    [self.networkStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    assert(self.networkStream != nil);
    [self.networkStream open];  
}

- (NSData *) setupImage: (UIImage *) image {
  
    //Uncompress Image from JPEG to NSData. Separate method so that various media input files 
    //can be eventually supported
    return UIImageJPEGRepresentation(image, 10);   
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)img editingInfo:(NSDictionary *)editInfo {

    NSLog(@"Delegate callback for imagepicker");
    
    //   [self dismissModalViewControllerAnimated:YES];
    
    /* Make a viewcontroller with the scrollview (for image zoom/pan) and push it on to the nav controller */
    UIViewController *tmp = [[UIViewController alloc] init ];
    ImageScrollView *one = [[ImageScrollView alloc] initWithFrame:CGRectMake(0, 0, tmp.view.bounds.size.width, tmp.view.bounds.size.height )];
    [one imageSetup:img];
    [tmp.view addSubview:one];    
    [picker pushViewController:tmp animated:YES];

    /* Take the image that is displayed, uncompress it and send it out on the network */
    [self connect:[self setupImage:img]];

}

- (IBAction)sendImage:(id)sender {
    /* Image picker alloc, delegate setup and present */
    self.imgPicker = [[UIImagePickerController alloc] init];
	self.imgPicker.delegate = self;	
    [self presentModalViewController:self.imgPicker animated:YES];

}

- (void)viewDidUnload
{
    
    [self setWebAddr:nil];
    [self disconnect];
    [super viewDidUnload];
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
