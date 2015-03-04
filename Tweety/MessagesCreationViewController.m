//
//  MessagesCreationViewController.m
//  Tweety
//
//  Created by Ro on 04/03/15.
//  Copyright (c) 2015 Ro. All rights reserved.
//

#import "MessagesCreationViewController.h"

@interface MessagesCreationViewController (){
    int topValue;
}

@end

@implementation MessagesCreationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(endEditing:)];

    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                          target:self
                                                                          action:@selector(cancelEditing:)];
    
    self.navigationItem.rightBarButtonItem = done;
    self.navigationItem.leftBarButtonItem = cancel;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    topValue = self.tweetTextView.contentInset.top;
    
}

- (IBAction)cancelEditing:(id)sender{
    self.completionHandler(self);
}


- (IBAction)endEditing:(id)sender{
    self.completionHandler(self);

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)keyboardWasShown:(NSNotification *)notification {
    if (self.tweetTextView != nil) {
        NSDictionary* info = [notification userInfo];
        CGRect keyboardRect = [self.tweetTextView convertRect:[[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
        CGSize keyboardSize = keyboardRect.size;
        
        self.tweetTextView.contentInset = UIEdgeInsetsMake(topValue, 0, keyboardSize.height, 0);
        self.tweetTextView.scrollIndicatorInsets = self.tweetTextView.contentInset;
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)notification {
    self.tweetTextView.scrollIndicatorInsets = UIEdgeInsetsZero;
    self.tweetTextView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
