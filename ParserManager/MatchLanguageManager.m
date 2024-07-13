//
//  MatchLanguageString.m
//  TestDemo
//
//  Created by Luke on 2024/7/13.
//

#import "MatchLanguageManager.h"

@implementation MatchLanguageManager


//方案1: 正则表达式匹配等号前后的内容 (对于非常大的字符串，正则表达式的处理效率可能会成为瓶颈)
+ (NSString *)replaceStringInContent:(NSString *)content matchingPattern:(NSString *)pattern withNewValue:(NSString *)newValue {
    NSError *error = nil;
    // 正则表达式匹配等号前后的内容
    NSString *regexPattern = [NSString stringWithFormat:@"\"%@\"\\s*=\\s*\"[^\"]*\"", pattern];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:0 error:&error];
    
    if (error) {
        NSLog(@"Error creating regex: %@", error.localizedDescription);
        return content;
    }
    
    // 创建替换模板
    NSString *replacementTemplate = [NSString stringWithFormat:@"\"%@\" = \"%@\"", pattern, newValue];
    
    // 进行替换
    NSString *newContent = [regex stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, [content length]) withTemplate:replacementTemplate];
    
    return newContent;
}


//方案2: 通过逐行读取和处理来提高效率
+ (NSString *)replaceStringInContent2:(NSString *)content matchingPattern:(NSString *)pattern withNewValue:(NSString *)newValue {
    NSMutableString *result = [NSMutableString string];
    NSError *error = nil;
    NSString *regexPattern = [NSString stringWithFormat:@"\"%@\"\\s*=\\s*\"[^\"]*\"", pattern];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:0 error:&error];
    
    if (error) {
        NSLog(@"Error creating regex: %@", error.localizedDescription);
        return content;
    }
    
    NSString *replacementTemplate = [NSString stringWithFormat:@"\"%@\" = \"%@\"", pattern, newValue];
    
    // 使用 NSScanner 来逐行扫描字符串
    NSScanner *scanner = [NSScanner scannerWithString:content];
    NSString *line = nil;
    NSCharacterSet *newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
    
    while (![scanner isAtEnd]) {
        [scanner scanUpToCharactersFromSet:newlineCharacterSet intoString:&line];
        [scanner scanCharactersFromSet:newlineCharacterSet intoString:NULL];
        
        NSString *newLine = [regex stringByReplacingMatchesInString:line options:0 range:NSMakeRange(0, [line length]) withTemplate:replacementTemplate];
        [result appendString:newLine];
        [result appendString:@"\n"];
    }
    
    return result;
}

//方案3: 通过逐行读取和处理来提高效率 (删除掉多余相同的行，只保留最后一个行进行替换,)
// 问题: 删除掉的位置有空行
+ (NSString *)replaceStringInContent3:(NSString *)content matchingPattern:(NSString *)pattern withNewValue:(NSString *)newValue {
    NSMutableString *result = [NSMutableString string];
    NSString *regexPattern = [NSString stringWithFormat:@"\"%@\"\\s*=\\s*\"[^\"]*\"", pattern];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:0 error:&error];
    
    if (error) {
        NSLog(@"Error creating regex: %@", error.localizedDescription);
        return content;
    }
    
    // 使用 NSScanner 来逐行扫描字符串
    NSScanner *scanner = [NSScanner scannerWithString:content];
    NSString *line = nil;
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    NSCharacterSet *newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
    NSInteger lastMatchIndex = NSNotFound;
    
    while (![scanner isAtEnd]) {
        [scanner scanUpToCharactersFromSet:newlineCharacterSet intoString:&line];
        [scanner scanCharactersFromSet:newlineCharacterSet intoString:NULL];
        
        [lines addObject:line];
        NSTextCheckingResult *match = [regex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
        if (match) {
            lastMatchIndex = lines.count - 1;
        }
    }
    
    // 构建结果字符串，删除之前的匹配行，只保留最后一个匹配行
    for (NSInteger i = 0; i < lines.count; i++) {
        if (i == lastMatchIndex) {
            NSString *newLine = [regex stringByReplacingMatchesInString:lines[i] options:0 range:NSMakeRange(0, lines[i].length) withTemplate:[NSString stringWithFormat:@"\"%@\" = \"%@\"", pattern, newValue]];
            [result appendString:newLine];
        } else if (i < lastMatchIndex) {
            NSTextCheckingResult *match = [regex firstMatchInString:lines[i] options:0 range:NSMakeRange(0, lines[i].length)];
            if (!match) {
                [result appendString:lines[i]];
            }
        } else {
            [result appendString:lines[i]];
        }
        [result appendString:@"\n"];
    }
    
    return result;
}

//方案4: 通过逐行读取和处理来提高效率 (删除掉多余相同的行，只保留最后一个行进行替换,)
+ (NSString *)replaceStringInContent4:(NSString *)content matchingPattern:(NSString *)pattern withNewValue:(NSString *)newValue {
    NSMutableString *result = [NSMutableString string];
    NSString *regexPattern = [NSString stringWithFormat:@"\"%@\"\\s*=\\s*\"[^\"]*\"", pattern];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:0 error:&error];
    
    if (error) {
        NSLog(@"Error creating regex: %@", error.localizedDescription);
        return content;
    }
    
    // 使用 NSScanner 来逐行扫描字符串
    NSScanner *scanner = [NSScanner scannerWithString:content];
    NSString *line = nil;
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    NSCharacterSet *newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
    NSInteger lastMatchIndex = NSNotFound;
    
    while (![scanner isAtEnd]) {
        [scanner scanUpToCharactersFromSet:newlineCharacterSet intoString:&line];
        [scanner scanCharactersFromSet:newlineCharacterSet intoString:NULL];
        
        [lines addObject:line];
        NSTextCheckingResult *match = [regex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
        if (match) {
            lastMatchIndex = lines.count - 1;
        }
    }
    
    // 构建结果字符串，删除之前的匹配行，只保留最后一个匹配行
    for (NSInteger i = 0; i < lines.count; i++) {
        if (i == lastMatchIndex) {
            NSString *newLine = [regex stringByReplacingMatchesInString:lines[i] options:0 range:NSMakeRange(0, lines[i].length) withTemplate:[NSString stringWithFormat:@"\"%@\" = \"%@\"", pattern, newValue]];
            [result appendString:newLine];
            if (i != lines.count - 1) {
                [result appendString:@"\n"];
            }
        } else if (i < lastMatchIndex) {
            NSTextCheckingResult *match = [regex firstMatchInString:lines[i] options:0 range:NSMakeRange(0, lines[i].length)];
            if (!match) {
                [result appendString:lines[i]];
                if (i != lines.count - 1) {
                    [result appendString:@"\n"];
                }
            }
        } else {
            [result appendString:lines[i]];
            if (i != lines.count - 1) {
                [result appendString:@"\n"];
            }
        }
    }
    
    return result;
}


//方案444: 通过逐行读取和处理来提高效率 (删除掉多余相同的行，只保留第一个行进行替换)
+ (NSString *)replaceStringInContent44:(NSString *)content
                       matchingPattern:(NSString *)pattern
                          withNewValue:(NSString *)newValue {
    
    NSMutableString *result = [NSMutableString string];
    NSString *regexPattern = [NSString stringWithFormat:@"\"%@\"\\s*=\\s*\"[^\"]*\"", pattern];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:0 error:&error];
    
    if (error) {
        NSLog(@"Error creating regex: %@", error.localizedDescription);
        return content;
    }
    
    // 使用 NSScanner 来逐行扫描字符串
    NSScanner *scanner = [NSScanner scannerWithString:content];
    NSString *line = nil;
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    NSCharacterSet *newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
    NSInteger lastMatchIndex = NSNotFound;
    
    while (![scanner isAtEnd]) {
        [scanner scanUpToCharactersFromSet:newlineCharacterSet intoString:&line];
        [scanner scanCharactersFromSet:newlineCharacterSet intoString:NULL];
        [lines addObject:line];
        
        if (lastMatchIndex == NSNotFound) {
            NSTextCheckingResult *match = [regex firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
            if (match) {
                lastMatchIndex = lines.count - 1;
            }
        }
    }

    // 构建结果字符串，删除之前的匹配行，只保留最后一个匹配行
    for (NSInteger i = 0; i < lines.count; i++) {
        if (i == lastMatchIndex) {
            NSString *newLine = [regex stringByReplacingMatchesInString:lines[i] options:0 range:NSMakeRange(0, lines[i].length) withTemplate:[NSString stringWithFormat:@"\"%@\" = \"%@\"", pattern, newValue]];
            [result appendString:newLine];
            if (i != lines.count - 1) {
                [result appendString:@"\n"];
            }
        } else {
            NSTextCheckingResult *match = [regex firstMatchInString:lines[i] options:0 range:NSMakeRange(0, lines[i].length)];
            if (!match) {
                [result appendString:lines[i]];
                if (i != lines.count - 1) {
                    [result appendString:@"\n"];
                }
            }
        }
    }
    
    return result;
}

+ (void)testAction {
    
    NSString *content = @"\"Register_Button\" = \"Register\";\n"
    "\"Register_Button_left\" = \"Register\";\n"
    "\"Register_Email\" = \"Email Address\";\n"
    "\"Register_Password\" = \"Password\";\n"
    "\"Register_FB_Connect\" = \"   Facebook\";\n"
    "\"Register_GG_Connect\" = \"   We pay great attentis is an integral part of the app and will only ever be carried out with your consent\";\n"
    "\"Register_policy\" = \"I have read and agreed to the privacy policy\";\n"
    "\"Register_GG_Connect\" = \"   We prt of the\";\n"
    "\"Register_TermsOfUser\" = \"Register_GG_Connect999\";\n"
    "\"Register_zaful.com\" = \"To complete registration, you must agree to the Zaful website Terms and Conditions.\";\n"
    "\"Register_password_less\" = \"Sorry, your password can't be less than 8 characters.\";\n"
    "\"Register_password_include\" = \"Password must include letters and numbers.\";\n"
    "\"Register_GG_Connect\" = \" is is an integral part of thecarried out with your consent\";\n"
    "\"Register_Confirm_Tip_Password\" = \"At least 8 characters & 1 number.\";";
    
    NSString *pattern = @"Register_GG_Connect";
    NSString *newValue = @"To provide you with    websites and apps.";
    
    NSString *result = [self replaceStringInContent44:content matchingPattern:pattern withNewValue:newValue];
    NSLog(@"%@", result);
}

@end
