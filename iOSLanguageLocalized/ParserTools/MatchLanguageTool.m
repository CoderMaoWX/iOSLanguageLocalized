//
//  MatchLanguageString.m
//  TestDemo
//
//  Created by Luke on 2024/7/13.
//

#import "MatchLanguageTool.h"
#import "ReadCSVFileTool.h"

@implementation MatchLanguageTool

/// 开始导入多语言
+ (void)mappingLanguage:(NSString *)csvURL
         localizblePath:(NSString *)localizbleURL
            compeletion:(void (^)(BOOL checkSuccess, NSString *tipString, BOOL tipStatus))compeletion {
    
    NSFileManager *fileManger = [NSFileManager defaultManager];
    
    NSMutableArray *allLanguageDirArray = [NSMutableArray arrayWithArray:[fileManger contentsOfDirectoryAtPath:localizbleURL error:nil]];
    [allLanguageDirArray removeObject:@".DS_Store"];//排除异常文件
    
    // 获取多语言目录列表: Key（Android/iOS Key), en.lproj, de.lproj, es.lproj ...
    NSMutableDictionary *appLprojDict = [NSMutableDictionary dictionary];
    for (NSString *pathDicr in allLanguageDirArray) {
        //NSLog(@"多语言文件夹子目录===%@", pathDicr);
        
        NSString *localizablePath = [NSString stringWithFormat:@"%@/%@/Localizable.strings", localizbleURL, pathDicr];
        if ([fileManger fileExistsAtPath:localizablePath]) {
            appLprojDict[pathDicr] = localizablePath;
        }
    }
    
    if (appLprojDict.allKeys.count == 0) {
        if (compeletion) {
            compeletion(NO, @"目录文件夹不存在需要导入的多语言文件", NO);
        }
        return;
    }
    
    // 读取CSV文件内容
    NSDictionary *csvToArrayDataDict = [ReadCSVFileTool readCSVFileToArray:csvURL];
    NSDictionary *csvToDictDataDict = [ReadCSVFileTool readCSVFileToDict:csvURL];

    if (![csvToArrayDataDict isKindOfClass:[NSDictionary class]] || csvToArrayDataDict.count == 0) {
        if (compeletion) {
            compeletion(YES, @"多语言翻译失败, \n请检查CSV文件内容是否错误", NO);
        }
        return;
    } else {
        //NSLog(@"成功解析出的CSV文件内容===%@", readCSVToArrayDict);
    }
    NSInteger writeSuccessCount = 0;
    NSArray *englishLanguageArr = csvToArrayDataDict[@"en.lproj"];
    
    for (NSString *fileName in appLprojDict.allKeys) {
        NSString *localizablePath = appLprojDict[fileName];
        
        if (![localizablePath isKindOfClass:[NSString class]] || localizablePath.length == 0) {
            continue;
        }
        NSError *error = nil;
        //⚠️1. 先读取项目中匹配的旧的翻译文件
        NSMutableString *allFileString = [NSMutableString stringWithContentsOfFile:localizablePath
                                                                          encoding:NSUTF8StringEncoding
                                                                             error:&error];
        NSString *csvDataKey = [NSString stringWithString:fileName];
        
        //如果没匹配到, 就找映射关系看能否再次匹配
        if (![csvToArrayDataDict.allKeys containsObject:csvDataKey]) {
            csvDataKey = [self matchLanguageKey:fileName csvToArrayDataDict:csvToArrayDataDict];
        }
        
        //⚠️2. 再把CSV文件中的匹配到的翻译追加到 旧的翻译中去
        NSArray *addLanguageStrArr = csvToArrayDataDict[csvDataKey];
        if (![addLanguageStrArr isKindOfClass:[NSArray class]] || addLanguageStrArr.count == 0) {
            
            //如果在cvs文件中没有匹配到项目中的翻译文件, 则添加"英语"的翻译到项目中
            if ([englishLanguageArr isKindOfClass:[NSArray class]] && englishLanguageArr.count > 0) {
                NSString *englishString = [englishLanguageArr componentsJoinedByString:@"\n"];
                //追加拼接:大字符串 (英语)
                [allFileString appendString: englishString];
            }
        } else { //匹配到就直接添加
            NSString *languageString = [addLanguageStrArr componentsJoinedByString:@"\n"];
            //追加拼接:大字符串 (匹配到的)
            [allFileString appendString: languageString];
        }
        
        //⚠️3. 再把添加的key中 移除旧的中相同的key, 在相同位置保留最新的需要添加的
        NSDictionary *csvInfoDict = csvToDictDataDict[csvDataKey];
        if ([csvInfoDict isKindOfClass:[NSDictionary class]] && csvInfoDict.count > 0) {
            
            for (NSString *languageKey in csvInfoDict.allKeys) {
                NSString *languageValue = csvInfoDict[languageKey];
                //替换现有key中相同key的翻译
                NSString *replaceResultString = [MatchLanguageTool replaceStringInContent:allFileString
                                                                             matchingPattern:languageKey
                                                                                withNewValue:languageValue];
                // 替换相同key之后的
                allFileString = [NSMutableString stringWithString:replaceResultString];
            }
        }
        
        //⚠️4. 最后把处理好的大字符串写入指定文件
        BOOL writeLangSuccess = [allFileString writeToFile:localizablePath
                                                atomically:YES
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
        if (writeLangSuccess) {
            writeSuccessCount += 1;
        }
    }
    
    if (writeSuccessCount == appLprojDict.allKeys.count) {
        if (compeletion) {
            compeletion(YES, @"💐恭喜, 多语言文件翻译全部成功", YES);
        }
    } else {
        NSString *tipStr = writeSuccessCount > 0 ? @"😰多语言文件翻译 部分成功,部分失败, \n请检查CSV文件内容是否正确" : @"😰未知错误 翻译失败, \n请检查CSV文件内容是否正确";
        if (compeletion) {
            compeletion(YES, tipStr, NO);
        }
    }
}

+ (NSString *)matchLanguageKey:(NSString *)fileName
            csvToArrayDataDict:(NSDictionary *)csvToArrayDataDict {
    NSArray *allKeyArr = self.mappingLanguageDict[fileName];
    if ([allKeyArr isKindOfClass:[NSArray class]]) {
        
        for (NSString *key in allKeyArr) {
            NSArray *dataArr = csvToArrayDataDict[key];
            if ([dataArr isKindOfClass:[NSArray class]] && dataArr.count > 0) {
                return key;
            }
        }
    }
    return fileName;
}

/**
 * 此字典是用来映射CSV文件中的每列的翻译需要对应添加到项目的哪个翻译文件中去的
 * 列举映射了一些常规的国家, 后续如果有新需要映射的,可自行追加到后面
 */
+ (NSDictionary *)mappingLanguageDict {
    return @{
        @"de.lproj": @[
            @"German", @"german", @"德语",
        ],
        @"fr.lproj" : @[
            @"French", @"french", @"法语",
        ],
        @"th.lproj" : @[
            @"Thailand", @"thailand", @"泰语",
        ],
        @"en.lproj" : @[
            @"English", @"english", @"英文", @"英语",
        ],
        @"vi.lproj"  : @[
            @"Vietnam", @"vietnam", @"越南语", @"越语",
        ],
        @"ru.lproj"  : @[
            @"Russian", @"russian", @"俄罗斯语", @"俄语",
        ],
        @"tr.lproj" : @[
            @"Turkey", @"turkey", @"土耳其语",  @"土耳其",
        ],
        @"ar.lproj" : @[
            @"Arabic", @"arabic", @"阿语", @"阿拉伯语",
        ],
        @"es.lproj" : @[
            @"Spanish", @"spanish", @"西语",  @"西班牙语",
        ],
        @"id.lproj" : @[
            @"Indonesia", @"indonesia", @"印度尼西亚", @"印尼语",
        ],
        @"it.lproj" : @[
            @"Italian", @"italian", @"意大利语", @"意语",
        ],
        @"pt.lproj" : @[
            @"Portuguese", @"portuguese", @"葡语", @"葡萄牙语",
        ],
        @"bn.lproj" : @[
            @"Bengali", @"bengali", @"孟加拉语",
        ],
        @"he.lproj" : @[
            @"Hebrew", @"hebrew", @"希伯来语",
        ],
        @"ja.lproj" : @[
            @"Japanese", @"japanese", @"日语",
        ],
        @"zh-Hans.lproj" : @[
            @"Chinaese", @"chinaese", @"zh-Hans", @"中文", @"汉语", @"简体中文", @"繁体中文",
        ],
    };;
}

//方案: 通过逐行读取和处理来提高效率 (删除掉多余相同的行，只保留第一个行进行替换)
+ (NSString *)replaceStringInContent:(NSString *)content
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

///测试代码
+ (void)testMatchLanguage {
    NSString *content = @"\"Register_Button\" = \"Register\";\n"
    "\"Register_Button_left\" = \"Register\";\n"
    "\"Register_Email\" = \"Email Address\";\n"
    "\"Register_Password\" = \"Password\";\n"
    "\"Register_FB_Connect\" = \"   Facebook\";\n"
    "\"Register_GG_Connect\" = \"   We pay great attentis is an integral part of the app and will only ever be carried out with your consent\";\n"
    "\"Register_policy\" = \"I have read and agreed to the privacy policy\";\n"
    "\"Register_GG_Connect\" = \"   We prt of the\";\n"
    "\"Register_TermsOfUser\" = \"Register_GG_Connect999\";\n"
    "\"Register_iOSLanguageLocalized.com\" = \"To complete registration, you must agree to the iOSLanguageLocalized website Terms and Conditions.\";\n"
    "\"Register_password_less\" = \"Sorry, your password can't be less than 8 characters.\";\n"
    "\"Register_password_include\" = \"Password must include letters and numbers.\";\n"
    "\"Register_GG_Connect\" = \" is is an integral part of thecarried out with your consent\";\n"
    "\"Register_Confirm_Tip_Password\" = \"At least 8 characters & 1 number.\";";
    
    NSString *pattern = @"Register_GG_Connect";
    NSString *newValue = @"To provide you with    websites and apps.";
    
    NSString *result = [self replaceStringInContent:content matchingPattern:pattern withNewValue:newValue];
    NSLog(@"%@", result);
}

@end
