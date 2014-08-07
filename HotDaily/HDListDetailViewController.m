//
//  HDListDetailViewController.m
//  HotDaily
//
//  Created by weizhou on 7/20/14.
//  Copyright (c) 2014 fengweizhou. All rights reserved.
//

#import "HDListDetailViewController.h"
#import "HDListDetailViewModel.h"
#import <WebViewJavascriptBridge/WebViewJavascriptBridge.h>
#import <ReactiveCocoa/RACEXTScope.h>

@interface HDListDetailViewController () <UIScrollViewDelegate, UIActionSheetDelegate,UIAlertViewDelegate>
@property (nonatomic, strong) WebViewJavascriptBridge *bridge;
@end

@implementation HDListDetailViewController

- (void)setViewModelData:(NSDictionary *)data {
    self.viewModel = [HDListDetailViewModel new];
    self.viewModel.abstractData = data;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.bridge = [WebViewJavascriptBridge bridgeForWebView:_webView handler:^(id data, WVJBResponseCallback responseCallback) {
        //no callback now
    }];
    
    self.webView.scrollView.delegate = self;
    
    [self.viewModel loadHTML:self.webView];
    
    self.currentPageNo = @1;
    [self bindViewModel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES];
}

- (void)bindViewModel {
    @weakify(self);
    [self.onlyAuthor.rac_newOnChannel subscribeNext:^(NSNumber* x) {
        @strongify(self);
        if ([x boolValue]) {
            NSMutableDictionary *data = [self.viewModel.detailData[@"data"] mutableCopy];
            NSPredicate *pre = [NSPredicate predicateWithFormat:@"SELF CONTAINS %@", self.viewModel.abstractData[@"authorId"]];
            data[@"list"] = [data[@"list"] filteredArrayUsingPredicate:pre];
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data
                                                               options:0
                                                                 error:&error];
            if (! jsonData) {
                NSLog(@"Got an error: %@", error);
            } else {
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [self.bridge send:jsonString];
            }
        } else {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.viewModel.detailData[@"data"]
                                                               options:0
                                                                 error:&error];
            if (! jsonData) {
                NSLog(@"Got an error: %@", error);
            } else {
                NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [self.bridge send:jsonString];
            }
        }
    }];
    
    RACSignal *pageSignal = RACObserve(self, currentPageNo);
    
    [pageSignal subscribeNext:^(NSNumber* x) {
        @strongify(self);
        [self.viewModel GETDetailAtPageNo:[x integerValue] success:^(NSURLSessionDataTask *task, id jsonString) {
            [self.bridge send:jsonString];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [self showAlertMessage];
        }];
    }];
    
    RACSignal *canGoPrevious = [pageSignal map:^id(NSNumber* value) {
        return @([value integerValue]>1);
    }];
    
    
    RACSignal *canGoNext = [pageSignal map:^id(NSNumber* value) {
        //bad API lead to this
        NSInteger pageCount = [self.viewModel.detailData[@"data"][@"pageCount"] integerValue]?:2;
        return @(pageCount > 1 && [value integerValue] < pageCount);
    }];
    
    self.previousPage.rac_command = [[RACCommand alloc] initWithEnabled:canGoPrevious signalBlock:^RACSignal *(id input) {
            self.currentPageNo = @([self.currentPageNo integerValue]-1);
            return [RACSignal empty];
    }];
    
    self.nextPage.rac_command = [[RACCommand alloc] initWithEnabled:canGoNext
        signalBlock:^RACSignal *(id input) {
            self.currentPageNo = @([self.currentPageNo integerValue]+1);
            return [RACSignal empty];
        }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    static CGFloat lastOffY  = 0.0;
    CGFloat curOffY = scrollView.contentOffset.y;
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    
    if (scrollView.frame.size.height >= scrollView.contentSize.height || //内容高度低于scrollView高度，不隐藏
        fabs(curOffY) + screenHeight > scrollView.contentSize.height  || //拉至最底部时，不做处理
        curOffY < 0                                                      //拉至最顶部时，不做处理
        )
    {
        return;
    }
    if (curOffY - lastOffY > 40)
    {
        //向上
        lastOffY = curOffY;
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [self.navigationController setToolbarHidden:YES animated:YES];
        
    }
    else if(lastOffY - curOffY > 40)
    {
        //向下
        lastOffY = curOffY;
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [self.navigationController setToolbarHidden:NO animated:YES];
    }
}

- (void)showAlertMessage {
    UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"网络请求失败"
                                                   message:@"请检查网络连接后重试"
                                                  delegate:nil
                                         cancelButtonTitle:@"确定"
                                         otherButtonTitles:nil, nil];
    [view show];
}

//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}

- (IBAction)backButtonTapped:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)shareButtonTapped:(id)sender {
    
}
- (IBAction)moreMenu:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"跳页",@"收藏", nil];
    [sheet showFromToolbar:self.navigationController.toolbar];
}

#pragma mark - actionsheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"去哪一页？"
                                                            message:[NSString stringWithFormat:@"%@/%@",self.currentPageNo,self.viewModel.detailData[@"data"][@"pageCount"]]
                                                           delegate:self
                                                  cancelButtonTitle:@"取消"
                                                  otherButtonTitles:@"确定", nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView show];
    } else if (buttonIndex == 1) {
        //
    }
}


#pragma mark - alertview delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSInteger pageNo = [[alertView textFieldAtIndex:0].text integerValue]?:1;
        pageNo = pageNo > 0 ? pageNo : 1;
        pageNo = pageNo < [self.viewModel.detailData[@"data"][@"pageCount"] integerValue] ? pageNo : [self.viewModel.detailData[@"data"][@"pageCount"] integerValue];
        self.currentPageNo = @(pageNo);
    }
}













@end
