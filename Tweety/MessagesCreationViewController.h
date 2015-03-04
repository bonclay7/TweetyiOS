//
//  MessagesCreationViewController.h
//  Tweety
//
//  Created by Ro on 04/03/15.
//  Copyright (c) 2015 Ro. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MessagesCreationViewController;
typedef void(^MTMessageCreationViewControllerDidFinish) (MessagesCreationViewController * messageCreationViewController);


@interface MessagesCreationViewController : UIViewController

@property (copy) MTMessageCreationViewControllerDidFinish completionHandler;

@end
