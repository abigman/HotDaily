//
//  HDFuninfoViewController.m
//  HotDaily
//
//  Created by weizhou on 8/12/14.
//  Copyright (c) 2014 fengweizhou. All rights reserved.
//

#import "HDFuninfoViewController.h"
#import "HDFuninfoViewModel.h"

#import <ReactiveCocoa/RACEXTScope.h>
#import "HDFuninfoCell.h"
#import "MJRefresh.h"

@interface HDFuninfoViewController ()

@end

@implementation HDFuninfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.viewModel = [HDFuninfoViewModel new];
    
    [self configureView];
    
    [self bindViewModel];
    
    [self.refreshButton.rac_command execute:nil];
}

- (void)configureView {
    @weakify(self);
    [self.tableView addHeaderWithCallback:^{
        @strongify(self);
        [self.refreshButton.rac_command execute:nil];
    }];
    [self.tableView addFooterWithCallback:^{
        @strongify(self);
        [self.viewModel insertItemsCompletion:^{
            if (self.viewModel.numOfSections == 1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView footerEndRefreshing];
                    [self.tableView reloadData];
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView footerEndRefreshing];
                    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:self.viewModel.numOfSections-1] withRowAnimation:UITableViewRowAnimationNone];
                });
            }
        }];
    }];
}

- (void)bindViewModel {
    @weakify(self);
    self.refreshButton.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal*(id input) {
        @strongify(self);
        [self.viewModel GETFuninfoListSuccess:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [self.tableView headerEndRefreshing];
            });
        } failure:^{
            //
        }];
        return [RACSignal empty];
    }];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.viewModel.numOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.viewModel numberOfRowsInSection:section];
}

- (HDFuninfoCellWithoutImage *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifierWithoutImage = @"FuninfoCellWithoutImage";
    HDFuninfoCellWithoutImage *cell = [tableView dequeueReusableCellWithIdentifier:identifierWithoutImage];
    [cell configureWithViewModel:self.viewModel atIndexPath:indexPath];
    return cell;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
//get rid of undeclared selector warning
#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UITableViewCell*)sender {
    [(UIViewController*)segue.destinationViewController setHidesBottomBarWhenPushed:YES];
    if ([segue.destinationViewController respondsToSelector:@selector(setViewModelData:)]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        NSDictionary *data = [self.viewModel dataAtIndexPath:indexPath];
        [segue.destinationViewController performSelector:@selector(setViewModelData:) withObject:data];
    }
}
#pragma clang diagnostic pop







//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}


@end
