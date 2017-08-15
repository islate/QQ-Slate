//
//  TencentWrapper.m
//  Slate
//
//  Created by lin yize on 16-6-3.
//  Copyright (c) 2016年 islate. All rights reserved.
//

#import "TencentWrapper.h"

#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/TencentApiInterface.h>
#import <TencentOpenAPI/QQApiInterface.h>

typedef void (^TencentWrapperLoginBlock)(BOOL success, NSError * _Nullable error, NSString * _Nullable openId, NSString * _Nullable accessToken, NSString * _Nullable nickname, NSString * _Nullable avatarUrl, NSDate * _Nullable expireDate, NSString * _Nullable rawInfo);

@interface TencentWrapper () <TencentSessionDelegate, QQApiInterfaceDelegate>
{
    BOOL login;
    void(^shareQQBlock)(BOOL success, BOOL isQQInstalled);
}

@property (nonatomic, strong) TencentOAuth *oauth;
@property (nonatomic, strong) NSString *currentAppId;
@property (nonatomic, strong) NSString *userAddingInfo;
@property (nonatomic, copy) TencentWrapperLoginBlock loginBlock;

@end


@implementation TencentWrapper
@synthesize isSigning, oauth, currentAppId, loginBlock;

// 单例
+ (instancetype)sharedWrapper
{
    static id sharedInstance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (void)qqShareWithContent:(NSString *)content
                       url:(NSString *)sourceUrl
                     image:(UIImage *)image
                     title:(NSString *)title
                shareBlock:(void(^)(BOOL success, BOOL isQQInstalled))shareBlock
{
    if ([TencentOAuth iphoneQQInstalled])
    {
        if (!oauth && currentAppId.length >0)
        {
            oauth = [[TencentOAuth alloc] initWithAppId:currentAppId
                                            andDelegate:self];
            //读取授权信息，避免二次授权
            NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:@"QQOauthData"];
            if (dict)
            {
                oauth.accessToken = [dict objectForKey:@"AccessToken"];
                oauth.expirationDate = [dict objectForKey:@"ExpirationDate"];
                oauth.openId = [dict objectForKey:@"OpenId"];
            }
        }
        
        if (shareBlock)
        {
            shareQQBlock = shareBlock;
        }
        
        QQApiObject *message = nil;
        
        if (sourceUrl != nil && ![sourceUrl isEqualToString:@""])
        {
            NSData *preImg = UIImagePNGRepresentation(image);
            if (title.length > 50)
            {
                title = [title substringToIndex:50];
            }
            message = [QQApiNewsObject objectWithURL:[NSURL URLWithString:sourceUrl] title:title description:content previewImageData:preImg];
        }
        else
        {
            message = [QQApiTextObject objectWithText:content];
        }
        
        SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:message];
        QQApiSendResultCode code = [QQApiInterface sendReq:req];
        
        if (code != EQQAPISENDSUCESS)
        {
            NSLog(@"发起QQ分享失败");
        }   
    }
    else
    {
        if (shareBlock)
        {
            shareBlock(NO, NO);
        }
    }
}

// 初始化设置参数
- (void)setAppId:(NSString *)appId
{
    isSigning = NO;
    currentAppId = appId;
}

- (void)qqLogin:(void (^)(BOOL isLogin, NSString *openId, NSString *nickname, NSString *avatarUrl, NSString *userAddingInfo))block
{
    [self login:^(BOOL success, NSError * _Nullable error, NSString * _Nullable openId, NSString * _Nullable accessToken, NSString * _Nullable nickname, NSString * _Nullable avatarUrl, NSDate * _Nullable expireDate, NSString * _Nullable rawInfo) {
        if (error) {
            block(NO, nil, nil, nil, nil);
        }
        else {
            block(YES, openId, nickname, avatarUrl, rawInfo);
        }
    }];
}

- (void)login:(void (^)(BOOL success, NSError * _Nullable error, NSString * _Nullable openId, NSString * _Nullable accessToken, NSString * _Nullable nickname, NSString * _Nullable avatarUrl, NSDate * _Nullable expireDate, NSString * _Nullable rawInfo))block
{
    if (!oauth && currentAppId.length >0)
    {
        oauth = [[TencentOAuth alloc] initWithAppId:currentAppId
                                        andDelegate:self];
        //读取授权信息，避免二次授权
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:@"QQOauthData"];
        if (dict)
        {
            oauth.accessToken = [dict objectForKey:@"AccessToken"];
            oauth.expirationDate = [dict objectForKey:@"ExpirationDate"];
            oauth.openId = [dict objectForKey:@"OpenId"];
        }
    }
    
    loginBlock = [block copy];
    isSigning = YES;
    [oauth authorize:[NSArray arrayWithObject:@"all"]];
}

- (void)qqLogout
{
    if (oauth)
    {
        [oauth logout:self];
        oauth = nil;
    }
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"QQOauthData"];
}

- (void)failed
{
    isSigning = NO;
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"qq login error", NSLocalizedDescriptionKey, nil];
    NSError *error = [NSError errorWithDomain:@"QQ-Slate" code:1 userInfo:userInfo];
    
    if (loginBlock)
    {
        loginBlock(NO, error, nil,nil,nil,nil,nil,nil);
    }
}

- (BOOL)isQQInstalled
{
    return [TencentOAuth iphoneQQInstalled];
}

#pragma mark - oauth代理
/**
 * 登录成功后的回调
 */
- (void)tencentDidLogin
{
    if (oauth.openId.length > 0)
    {
        //记录QQ授权信息
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        if (oauth.accessToken)
        {
            [dict setObject:oauth.accessToken forKey:@"AccessToken"];
        }
        if (oauth.expirationDate)
        {
            [dict setObject:oauth.expirationDate forKey:@"ExpirationDate"];
        }
        if (oauth.openId)
        {
            [dict setObject:oauth.openId forKey:@"OpenId"];
        }
        [[NSUserDefaults standardUserDefaults] setObject:dict forKey:@"QQOauthData"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [oauth getUserInfo];
    }
}

/**
 * 登录失败后的回调
 * \param cancelled 代表用户是否主动退出登录
 */
- (void)tencentDidNotLogin:(BOOL)cancelled
{
    [self failed];
}

/**
 * 登录时网络有问题的回调
 */
- (void)tencentDidNotNetWork
{
    [self failed];
}

- (void)getUserInfoResponse:(APIResponse*) response
{
    NSDictionary *dict = [response jsonResponse];
    self.userAddingInfo = [response message];
    
    if (dict && oauth.openId.length > 0)
    {
        isSigning = NO;
        
        NSString *nickname = [dict objectForKey:@"nickname"];
        NSString *avatar = [dict objectForKey:@"figureurl_qq_2"];
        if (loginBlock && nickname.length > 0)
        {
            loginBlock(YES,nil, oauth.openId, oauth.accessToken, nickname, avatar, oauth.expirationDate,self.userAddingInfo);
            return;
        }
    }

    [self failed];
}

- (BOOL)isQQLoginSupported
{
    if (currentAppId.length > 0)
    {
        if ([currentAppId isEqualToString:@"QQAppId"])
        {
            return NO;
        }
        
        if ([self isQQInstalled])
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)canHandleOpenURL:(NSURL *)url
{
    login = [TencentOAuth CanHandleOpenURL:url];
    if (!login)
    {
        return [QQApiInterface handleOpenURL:url delegate:self];
    }
    return login;
}

- (BOOL)handleOpenURL:(NSURL *)url
{
    if (login)
    {
        return [TencentOAuth HandleOpenURL:url];
    }
    return YES;
}

#pragma mark - 
/**
 处理来至QQ的请求
 */
- (void)onReq:(QQBaseReq *)req
{

}

/**
 处理来至QQ的响应
 */
- (void)onResp:(QQBaseResp *)resp
{
    if (!shareQQBlock)
    {
        return;
    }
    
    if (resp.errorDescription == nil)
    {
        shareQQBlock(YES, YES);
    }
    else
    {
         shareQQBlock(NO, YES);
    }
}

/**
 处理QQ在线状态的回调
 */
- (void)isOnlineResponse:(NSDictionary *)response
{

}

@end
