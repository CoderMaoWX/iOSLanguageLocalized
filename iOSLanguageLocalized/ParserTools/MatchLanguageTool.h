//
//  MatchLanguageTool.h
//  TestDemo
//
//  Created by Luke on 2024/7/13.
//

#import <Foundation/Foundation.h>

static NSString * _Nullable kLanguageLocalized = @"iOSLanguageLocalized";

NS_ASSUME_NONNULL_BEGIN

@interface MatchLanguageTool : NSObject

/// 开始导入多语言
+ (void)mappingLanguage:(NSString *)csvURL
         localizblePath:(NSString *)localizbleURL
            compeletion:(void (^)(BOOL checkSuccess, NSString *tipString, BOOL tipStatus))compeletion;

@end

NS_ASSUME_NONNULL_END
