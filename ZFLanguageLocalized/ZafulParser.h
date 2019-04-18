//
//  ZafulParser.h
//  ZFLanguageLocalized
//
//  Created by 610582 on 2019/4/18.
//  Copyright © 2019 610582. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZafulParser : NSObject

/**
 * 专业的解析方案, (有可能为空)
 */
+ (NSArray *)professionalParserCsvFileWithPath:(NSString *)filePath;


/**
 * 备选解析方案, (此解析方案可能不准, 只要在上面的专业解析方法失败时才推荐调用)
 */
+ (NSArray *)backupParserCsvFileWithPath:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
