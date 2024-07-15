//
//  MatchLanguageManager.h
//  TestDemo
//
//  Created by Luke on 2024/7/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MatchLanguageManager : NSObject

//方案444: 通过逐行读取和处理来提高效率 (删除掉多余相同的行，只保留第一个行进行替换)
+ (NSString *)replaceStringInContent:(NSString *)content
                     matchingPattern:(NSString *)pattern
                        withNewValue:(NSString *)newValue;

@end

NS_ASSUME_NONNULL_END
