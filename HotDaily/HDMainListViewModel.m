//
//  HDMainListViewModel.m
//  HotDaily
//
//  Created by weizhou on 7/21/14.
//  Copyright (c) 2014 fengweizhou. All rights reserved.
//

#import "HDHTTPManager.h"
#import "HDMainListViewModel.h"

#import <ReactiveCocoa/RACEXTScope.h>

@implementation HDMainListViewModel

- (NSArray *)listArray {
    if (_listArray) return _listArray;
    NSRange range;
    range.location = 0;
    range.length = 20;
    _listArray = [_data[@"data"][@"list"] subarrayWithRange:range];
    return _listArray;
}

- (NSInteger)numOfSections {
    if (_numOfSections) return _numOfSections;
    _numOfSections = 1;
    return _numOfSections;
}

- (void)moreItemsIn:(UITableView *)tableView {
    self.numOfSections += 1;
    if (self.numOfSections%5 != 0) {
        NSRange range;
        range.location = self.numOfSections%5 * 20;
        range.length = 20;
        self.listArray = [self.listArray arrayByAddingObjectsFromArray:[self.data[@"data"][@"list"] subarrayWithRange:range]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [tableView insertSections:[NSIndexSet indexSetWithIndex:self.numOfSections-1] withRowAnimation:UITableViewRowAnimationNone];
        });
    } else {
        @weakify(self);
        NSDictionary *params = @{@"pageNo": @(self.numOfSections/5 + 1),
                                 @"pageSize": @(100),
                                 @"orderBy": @1,
                                 @"pageBy": @1};
        [[HDHTTPManager sharedHTTPManager] GET:hotListURLString
                                    parameters:params
                                       success:^(NSURLSessionDataTask *task, id responseObject) {
                                           @strongify(self);
                                           self.data = responseObject;
                                           NSRange range;
                                           range.location = 0;
                                           range.length = 20;
                                           self.listArray = [self.listArray arrayByAddingObjectsFromArray:[self.data[@"data"][@"list"] subarrayWithRange:range]];
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               [tableView insertSections:[NSIndexSet indexSetWithIndex:self.numOfSections-1] withRowAnimation:UITableViewRowAnimationNone];
                                           });
                                       } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                           [[HDHTTPManager sharedHTTPManager] networkFailAlert];
                                       }];
    }
    
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    return 20;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section {
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"yyyy-MM-dd EEEE"];
    return [NSString stringWithFormat:@"今天是: %@",NSLocalizedString([df stringFromDate:[NSDate date]], nil)];
}

- (NSDictionary *)dataAtIndexPath:(NSIndexPath *)indexPath {
    return self.listArray[indexPath.row + indexPath.section*20];
}

- (NSString *)titleAtIndexPath:(NSIndexPath *)indexPath {
    return self.listArray[indexPath.row + indexPath.section*20][@"title"];
}

- (BOOL)hasImageAtIndexPath:(NSIndexPath *)indexPath {
    if (self.listArray[indexPath.row + indexPath.section*20][@"pic"]) {
        return ![self.listArray[indexPath.row + indexPath.section*20][@"pic"] isEqualToString:@""];
    }
    return NO;
}

- (NSURL *)imageURLAtIndexPath:(NSIndexPath *)indexPath {
    if ([self hasImageAtIndexPath:indexPath]) {
        NSURL *url = [NSURL URLWithString:self.listArray[indexPath.row + indexPath.section*20][@"pic"]];
        return url;
    } else {
        return nil;
    }
}

- (UIColor *)bottomViewColorAtIndexPath:(NSIndexPath *)indexPath {
    return UIColorFromRGB(0xD0021B);
}

- (NSArray *)headerImages {
    NSMutableArray *images = [NSMutableArray array];
    for (NSDictionary *dic in self.data[@"data"][@"list"]) {
        if (dic[@"pic"] && ![dic[@"pic"] isEqualToString:@""]) {
            [images addObject:@{@"url": dic[@"pic"],
                                @"title": dic[@"title"]}];
        }
        if (images.count == 5) {
            break;
        }
    }
    //headerView must be 5
    if (images.count < 5) {
        while (images.count < 6) {
            [images addObject:@{@"url": @"http://img3.laibafile.cn/p/m/173672485.jpg",
                                @"title": @"五张图片都没有要不要这么烂！"}];
        }
    }
    return images;
}

- (void)GETHotListSuccess:(void (^)(NSURLSessionDataTask *, id))success
                  failure:(void (^)(NSURLSessionDataTask *, NSError *))failure {
    NSDictionary *params = @{@"pageNo": @(1),
                             @"pageSize": @(100),
                             @"orderBy": @1,
                             @"pageBy": @1};
    [[HDHTTPManager sharedHTTPManager] GET:hotListURLString
                                parameters:params
                                   success:^(NSURLSessionDataTask *task, id responseObject) {
                                       success(task, responseObject);
                                   } failure:^(NSURLSessionDataTask *task, NSError *error) {
                                       failure(task, error);
                                   }];
}

@end
