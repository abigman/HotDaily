//
//  HDFuninfoViewModel.h
//  HotDaily
//
//  Created by weizhou on 8/12/14.
//  Copyright (c) 2014 fengweizhou. All rights reserved.
//

@import Foundation;

@interface HDFuninfoViewModel : NSObject

@property (copy, nonatomic) NSDictionary *data;
//table
@property (copy, nonatomic) NSArray *listArray;
@property (nonatomic) NSInteger numOfSections;

- (NSInteger)numberOfRowsInSection:(NSInteger)section;
- (void)insertItemsCompletion:(void (^)(void))completion;
//table cell
- (NSDictionary *)dataAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)titleAtIndexPath:(NSIndexPath *)indexPath;
- (UIColor *)bottomViewColorAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)bottomViewWidthAtIndexPath:(NSIndexPath *)indexPath;

- (void)GETFuninfoListSuccess:(void (^)(void))success
                      failure:(void (^)(void))failure;

@end
