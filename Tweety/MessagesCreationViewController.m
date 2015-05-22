//
//  MessagesCreationViewController.m
//  Tweety
//
//  Created by Ro on 04/03/15.
//  Copyright (c) 2015 Ro. All rights reserved.
//

#import "MessagesCreationViewController.h"
#import "FBDataProvider.h"
#import "FBSession.h"

@interface MessagesCreationViewController (){
    UIEdgeInsets _originalEdgeInsets;
}

@end

@implementation MessagesCreationViewController


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    _originalEdgeInsets = self.tweetTextView.contentInset;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    
    self.tweetTextView.text = @"";
}

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
    
}

- (IBAction)cancelEditing:(id)sender{
    self.completionHandler(self);
}


- (IBAction)endEditing:(id)sender{
    
    [[FBDataProvider sharedInstance] sendMessage:self.tweetTextView.text];
    NSLog(@"%@", self.tweetTextView.text);
    self.completionHandler(self);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)keyboardWasShown:(NSNotification*)notification {
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    keyboardFrame = [self.view convertRect:keyboardFrame fromView:nil];
    
    
    self.tweetTextView.contentInset = UIEdgeInsetsMake(_originalEdgeInsets.top, 0, keyboardFrame.size.height, 0);
    self.tweetTextView.scrollIndicatorInsets = self.tweetTextView.contentInset;
}

- (void)keyboardWillBeHidden:(NSNotification*)notification {
    self.tweetTextView.contentInset = _originalEdgeInsets;
    self.tweetTextView.scrollIndicatorInsets = _originalEdgeInsets;
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
