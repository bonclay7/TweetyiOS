//
//  TWFeedTableViewController.m
//  Tweety
//
//  Created by Ro on 04/03/15.
//  Copyright (c) 2015 Ro. All rights reserved.
//

#import "TWFeedTableViewController.h"
#import "MessagesCreationViewController.h"

#import <CoreData/CoreData.h>
#import "FBDataProvider.h"

@interface TWFeedTableViewController ()

@property NSFetchedResultsController *fetchedResultsController;

@end

@implementation TWFeedTableViewController


- (void)viewWillAppear:(BOOL)animated{
    [[FBDataProvider sharedInstance] updateNow];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *newMessage = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                                target:self
                                                                                action:@selector(showMessageCreationView:)];
    
    self.navigationItem.rightBarButtonItem = newMessage;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Message"];
    
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
    
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[[FBDataProvider sharedInstance] managedObjectContext]
                                                                          sectionNameKeyPath:nil cacheName:nil];
    self.fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller{
    NSLog(@"data changed");
    [self.tableView reloadData];
}


- (IBAction)showMessageCreationView:(id)sender{
    NSLog(@"clicked");
    MessagesCreationViewController *messagesCreationView = [[MessagesCreationViewController alloc] initWithNibName:nil
                                                                                                            bundle:nil];
    messagesCreationView.completionHandler = ^(MessagesCreationViewController *messageCreation){
        [self.navigationController.tabBarController dismissViewControllerAnimated:YES
                                                                       completion:^{
                                                                       }];
    };
    
    UINavigationController *msgNav = [[UINavigationController alloc] initWithRootViewController:messagesCreationView];
    [self.navigationController.tabBarController presentViewController:msgNav animated:YES completion:^{
        NSLog(@"popo");
    }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sections = [self.fetchedResultsController sections];
    id <NSFetchedResultsSectionInfo> sectionsContent = [sections objectAtIndex:section];
    return [sectionsContent numberOfObjects];
}

//*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    NSManagedObject *tweet = [[self.fetchedResultsController fetchedObjects] objectAtIndex:indexPath.row] ;
    NSManagedObject *user = [tweet valueForKey:@"author"];
    

    cell.textLabel.text = [user valueForKey:@"handle"];
    cell.detailTextLabel.text =[tweet valueForKey:@"content"];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.textLabel.appearance ]

    
    return cell;
}


@end
