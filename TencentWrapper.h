//
//  TencentWrapper.h
//  Slate
//
//  Created by lin yize on 16-6-3.
//  Copyright (c) 2016年 islate. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TencentWrapper : NSObject

@property (nonatomic, assign) BOOL isSigning;

// 单例
+ (instancetype)sharedWrapper;

// 初始化设置参数
- (void)setAppId:(NSString *)appId;

- (void)qqLogin:(void (^)(BOOL isLogin, NSString *openId, NSString *nickname, NSString *avatarUrl, NSString *userAddingInfo))loginBlock;
- (void)qqLogout;
- (BOOL)isQQInstalled;
- (BOOL)isQQLoginSupported;

- (BOOL)canHandleOpenURL:(NSURL *)url;
- (BOOL)handleOpenURL:(NSURL *)url;


- (void)login:(void (^)(BOOL success, NSError * _Nullable error, NSString * _Nullable openId, NSString * _Nullable accessToken, NSString * _Nullable nickname, NSString * _Nullable avatarUrl, NSDate * _Nullable expireDate, NSString * _Nullable rawInfo))loginBlock;

- (void)qqShareWithContent:(NSString *)content
                           url:(NSString *)sourceUrl
                         image:(UIImage *)image
                         title:(NSString *)title
                    shareBlock:(void(^)(BOOL success, BOOL isQQInstalled))shareBlock;

@end
