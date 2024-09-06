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

/// 开始从表格导入多语言到项目
+ (void)mappingLanguage:(NSString *)csvURL
         localizblePath:(NSString *)localizbleURL
            compeletion:(void (^)(BOOL checkSuccess, NSString *tipString, BOOL tipStatus))compeletion;



/// 本地英语翻译key
+ (NSString *)englishCSVKey;

/// 本地中文翻译key
+ (NSString *)chineseCSVKey;

/**
 * 此字典是全球前40种主流语言：用来映射CSV文件中的每列的翻译需要对应添加到项目的哪个翻译文件中去的
 * 列举映射了一些常规的国家，后续如果有新需要映射的，可自行追加到后面
 */
+ (NSDictionary *)mappingLanguageDict;

/// 过滤字符串的各种空格和换行符等
+ (NSString *)fileFieldValue:(NSString *)fieldValue;

/// 映射关键字
+ (NSString *)matchLanguageKey:(NSString *)fileName
            csvToArrayDataDict:(NSDictionary *)csvToArrayDataDict;

@end

NS_ASSUME_NONNULL_END
