//
//  MessagesCreationViewController.m
//  Tweety
//
//  Created by Ro on 04/03/15.
//  Copyright (c) 2015 Ro. All rights reserved.
//

#import "MessagesCreationViewController.h"

@interface MessagesCreationViewController ()

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
