//
//  MatchLanguageString.m
//  TestDemo
//
//  Created by Luke on 2024/7/13.
//

#import "MatchLanguageTool.h"
#import "ReadCSVFileTool.h"
#import "ParserManager.h"

///从表格导入多语言到项目
@implementation MatchLanguageTool

/// 开始导入多语言
+ (void)mappingLanguage:(NSString *)csvURL
         localizblePath:(NSString *)localizbleURL
            compeletion:(void (^)(BOOL checkSuccess, NSString *tipString, BOOL tipStatus))compeletion {
    
    NSFileManager *fileManger = [NSFileManager defaultManager];
    NSArray *allLanguageNames = [fileManger contentsOfDirectoryAtPath:localizbleURL error:nil];
    
    NSMutableArray *allLanguageDirArray = [NSMutableArray array];
    //排除异常文件
    for (NSString *fileName in allLanguageNames) {
        if ([fileName.lowercaseString hasSuffix:@".lproj"]) {
            [allLanguageDirArray addObject:fileName];
        }
    }
    
    if (allLanguageDirArray.count == 0) {
        if (compeletion) {
            compeletion(NO, @"项目路径文件夹中不存在国际化多语言翻译文件", NO);
        }
        return;
    }
    
    // 获取多语言目录列表: Key（Android/iOS Key), en.lproj, de.lproj, es.lproj ...
    NSMutableDictionary<NSString *, NSMutableArray *> *appLprojDict = [NSMutableDictionary dictionary];
    
    for (NSString *pathDicr in allLanguageDirArray) {
        //NSLog(@"多语言文件夹子目录===%@", pathDicr);
        
        NSString *tmpPath = [NSString stringWithFormat:@"%@/%@", localizbleURL, pathDicr];
        NSArray *lprojSubDirectoryArr = [fileManger contentsOfDirectoryAtPath:tmpPath error:nil];
        
        for (NSString *subPath in lprojSubDirectoryArr) {
            if ([subPath.lowercaseString hasSuffix:@".strings"] &&
                ![subPath.lowercaseString hasSuffix:@"plist.strings"]) {
                
                NSMutableArray *tmpPathArr = appLprojDict[pathDicr];
                if (![tmpPathArr isKindOfClass:[NSMutableArray class]]) {
                    tmpPathArr = [NSMutableArray array];
                }
                [tmpPathArr addObject:[NSString stringWithFormat:@"%@/%@", tmpPath, subPath]];
                appLprojDict[pathDicr] = tmpPathArr;
            }
        }
    }
    
    if (appLprojDict.allKeys.count == 0) {
        if (compeletion) {
            compeletion(NO, @"目录文件夹不存在需要导入的多语言文件", NO);
        }
        return;
    }
    
    // 读取CSV文件内容
    NSDictionary *csvToArrayDataDict = [ReadCSVFileTool readCSVFileToKeyAndArray:csvURL];
    NSDictionary *csvToDictDataDict = [ReadCSVFileTool readCSVFileToKeyAndDict:csvURL];
    
    //如果专业的CSV表格解析异常了, 再尝试采用手动解析备选方案
    if (csvToArrayDataDict.count == 0 || csvToDictDataDict.count == 0) {
        csvToArrayDataDict = [ReadCSVFileTool backup_readCSVFileToKeyAndArray:csvURL];
        csvToDictDataDict = [ReadCSVFileTool backup_readCSVFileToKeyAndDict:csvURL];
    }
    //NSLog(@"成功解析出的CSV文件内容===%@", csvToArrayDataDict);
    
    if (![csvToArrayDataDict isKindOfClass:[NSDictionary class]] || csvToArrayDataDict.count == 0) {
        if (compeletion) {
            compeletion(YES, @"多语言翻译失败, \n请检查CSV文件内容是否错误", NO);
        }
        return;
        
    } else if (![csvToDictDataDict isKindOfClass:[NSDictionary class]] || csvToDictDataDict.count == 0) {
        if (compeletion) {
            compeletion(YES, @"多语言翻译失败, \n请检查CSV文件内容是否错误", NO);
        }
        return;
        
    } else if (csvToArrayDataDict.count != csvToDictDataDict.count) {
        if (compeletion) {
            compeletion(YES, @"多语言翻译失败, \n请检查CSV文件内容是否错误", NO);
        }
        return;
    }
    
    NSString *englishKey = [MatchLanguageTool englishCSVKey];
    NSArray *englishLanguageArr = csvToArrayDataDict[englishKey];
    
    //如果没匹配到英语的key, 就找映射英语看能否再次匹配
    if (![englishLanguageArr isKindOfClass:[NSArray class]] ||
        ![csvToArrayDataDict.allKeys containsObject:englishKey]) {
        NSString *englishMapKey = [self matchLanguageKey:englishKey csvToArrayDataDict:csvToArrayDataDict];
        englishLanguageArr = csvToArrayDataDict[englishMapKey];
    }
    NSInteger writeFailCount = 0;
    NSInteger allCount = 0;

    // 开始写入翻译内容到项目
    for (NSString *fileName in appLprojDict.allKeys) {
        
        NSArray *localizablePathArr = appLprojDict[fileName];
        if (![localizablePathArr isKindOfClass:[NSArray class]]) { continue; }
        
        for (NSString *localizablePath in localizablePathArr) {
            if (![localizablePath isKindOfClass:[NSString class]] || localizablePath.length == 0) { continue; }
            
            writeFailCount += 1;
            allCount += 1;

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
            BOOL useNewValue = YES;
            
            //如果没匹配到, 就用英语替换
            if (![csvInfoDict isKindOfClass:[NSDictionary class]] || csvInfoDict.count == 0) {
                NSString *tmpEnglishKey = [self matchLanguageKey:englishKey csvToArrayDataDict:csvToDictDataDict];
                csvInfoDict = csvToDictDataDict[tmpEnglishKey];
                useNewValue = NO;
            }
            
            if ([csvInfoDict isKindOfClass:[NSDictionary class]] && csvInfoDict.count > 0) {
                
                for (NSString *languageKey in csvInfoDict.allKeys) {
                    NSString *languageValue = csvInfoDict[languageKey];
                    //替换现有key中相同key的翻译
                    NSString *replaceResultString = [MatchLanguageTool replaceStringInContent:allFileString
                                                                              matchingPattern:languageKey
                                                                                 withNewValue:languageValue
                                                                                  useNewValue:useNewValue];
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
                writeFailCount -= 1;
            }
        }
    }
    
    if (!compeletion) { return; }
    
    if (writeFailCount == 0) {
        compeletion(YES, @"💐恭喜, 多语翻译言文件全部导入成功", YES);
    } else {
        if (writeFailCount > 0 && writeFailCount < allCount) {
            NSString *tipStr = @"😰多语言文件翻译 部分成功,部分失败, \n请检查CSV文件内容是否正确";
            compeletion(YES, tipStr, NO);
        } else {
            NSString *tipStr = @"😰未知错误 翻译失败, \n请检查CSV文件内容是否正确";
            compeletion(YES, tipStr, NO);
        }
    }
}

/// 过滤字符串的各种空格和换行符等
+ (NSString *)fileFieldValue:(NSString *)fieldValue {
    if (![fieldValue isKindOfClass:[NSString class]] || fieldValue.length == 0) { return @""; }
    NSString *fieldString = [NSString stringWithString:fieldValue];
    //去除两头的空格
    fieldString = [fieldString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //去除所有换行符
    fieldString = [fieldString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    fieldString = [fieldString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    fieldString = [fieldString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    return fieldString;
}

/// 映射关键字
+ (NSString *)matchLanguageKey:(NSString *)fileName
            csvToArrayDataDict:(NSDictionary *)csvToArrayDataDict {
    
    NSArray *dictAllKeyArr = csvToArrayDataDict.allKeys;
    if (dictAllKeyArr.count == 0) {
        return fileName;
    }
    NSArray *mappingValues = self.mappingLanguageDict[fileName];
    if ([mappingValues isKindOfClass:[NSArray class]]) {
        for (NSString *mappingLang in mappingValues) {
            
            for (NSString *dictKey in dictAllKeyArr) {
                NSString *dictKeyString = [MatchLanguageTool fileFieldValue:dictKey.lowercaseString];
                NSString *mappingLangString = [MatchLanguageTool fileFieldValue:mappingLang.lowercaseString];

                if ([dictKeyString isEqualToString:mappingLangString]) {
                    return dictKey;
                }
            }
        }
    }
    return fileName;
}

//方案: 替换现有key中相同key的翻译 (删除掉多余相同的行，只保留第一个行进行替换)
+ (NSString *)replaceStringInContent:(NSString *)content
                     matchingPattern:(NSString *)languageKey
                        withNewValue:(NSString *)languageValue
                         useNewValue:(BOOL)useNewValue {
    
    NSString *regexPattern = [NSString stringWithFormat:@"\"%@\"\\s*=\\s*\"[^\"]*\"", languageKey];
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
    
    NSMutableString *result = [NSMutableString string];
    // 构建结果字符串，删除之前的匹配行，只保留最后一个匹配行
    for (NSInteger i = 0; i < lines.count; i++) {
        if (i == lastMatchIndex) {
            if (useNewValue) {
                NSString *replaceTemplate = [NSString stringWithFormat:@"\"%@\" = \"%@\"", languageKey, languageValue];
                NSString *newLine = [regex stringByReplacingMatchesInString:lines[i]
                                                                    options:0
                                                                      range:NSMakeRange(0, lines[i].length)
                                                               withTemplate:replaceTemplate];
                [result appendString:newLine];
            } else {
                NSString *oldValue = lines[i];
                [result appendString:oldValue];
            }
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

+ (NSString *)englishCSVKey {
    return @"en.lproj";
}

+ (NSString *)chineseCSVKey {
    return @"zh-Hans.lproj";
}

/**
 * 此字典是全球前40种主流语言：用来映射CSV文件中的每列的翻译需要对应添加到项目的哪个翻译文件中去的
 * 列举映射了一些常规的国家，后续如果有新需要映射的，可自行追加到后面
 *  https://chatgpt.com/share/9cd0a788-bf8e-4237-9db9-8becdce6332d
 */
+ (NSDictionary *)mappingLanguageDict {
    return @{
        @"en.lproj" : @[@"en.lproj", @"English", @"英语"],
        @"zh-Hans.lproj" : @[@"zh-Hans.lproj", @"Mandarin Chinese",
                             @"Chinaese", @"Chinese", @"中文", @"简体中文", @"普通话"],
        @"zh-Hant.lproj" : @[@"zh-Hant.lproj", @"Traditional Chinese", @"繁体中文"],
        @"hi.lproj" : @[@"hi.lproj", @"Hindi", @"印地语", @"印语"],
        @"es.lproj" : @[@"es.lproj", @"Spanish", @"西班牙语", @"西语"],
        @"ar.lproj" : @[@"ar.lproj", @"Arabic", @"阿拉伯语", @"阿语"],
        @"bn.lproj" : @[@"bn.lproj", @"Bengali", @"孟加拉语", @"孟语"],
        @"pt.lproj" : @[@"pt.lproj", @"Portuguese", @"葡萄牙语", @"葡语"],
        @"fr.lproj" : @[@"fr.lproj", @"French", @"法语"],
        @"ru.lproj" : @[@"ru.lproj", @"Russian", @"俄语"],
        @"ur.lproj" : @[@"ur.lproj", @"Urdu", @"乌尔都语"],
        @"id.lproj" : @[@"id.lproj", @"Indonesian", @"印尼语"],
        @"de.lproj" : @[@"de.lproj", @"German", @"德语"],
        @"ja.lproj" : @[@"ja.lproj", @"Japanese", @"日语"],
        @"mr.lproj" : @[@"mr.lproj", @"Marathi", @"马拉地语"],
        @"te.lproj" : @[@"te.lproj", @"Telugu", @"泰卢固语"],
        @"pa.lproj" : @[@"pa.lproj", @"Punjabi", @"旁遮普语"],
        @"vi.lproj" : @[@"vi.lproj", @"Vietnamese", @"越南语"],
        @"ta.lproj" : @[@"ta.lproj", @"Tamil", @"泰米尔语"],
        @"tr.lproj" : @[@"tr.lproj", @"Turkish", @"土耳其语"],
        @"fa.lproj" : @[@"fa.lproj", @"Persian", @"波斯语"],
        @"it.lproj" : @[@"it.lproj", @"Italian", @"意大利语"],
        @"jv.lproj" : @[@"jv.lproj", @"Javanese", @"爪哇语"],
        @"gu.lproj" : @[@"gu.lproj", @"Gujarati", @"古吉拉特语"],
        @"pl.lproj" : @[@"pl.lproj", @"Polish", @"波兰语"],
        @"uk.lproj" : @[@"uk.lproj", @"Ukrainian", @"乌克兰语"],
        @"fil.lproj": @[@"fil.lproj", @"Filipino", @"菲律宾语"],
        @"kn.lproj" : @[@"kn.lproj", @"Kannada", @"卡纳达语"],
        @"ml.lproj" : @[@"ml.lproj", @"Malayalam", @"马拉雅拉姆语"],
        @"ha.lproj" : @[@"ha.lproj", @"Hausa", @"豪萨语"],
        @"my.lproj" : @[@"my.lproj", @"Burmese", @"缅甸语"],
        @"th.lproj" : @[@"th.lproj", @"Thai", @"泰语"],
        @"az.lproj" : @[@"az.lproj", @"Azerbaijani", @"阿塞拜疆语"],
        @"ht.lproj" : @[@"ht.lproj", @"Haitian Creole", @"海地克里奥尔语"],
        @"xh.lproj" : @[@"xh.lproj", @"Xhosa", @"科萨语"],
        @"am.lproj" : @[@"am.lproj", @"Amharic", @"阿姆哈拉语"],
        @"ne.lproj" : @[@"ne.lproj", @"Nepali", @"尼泊尔语"],
        @"sq.lproj" : @[@"sq.lproj", @"Albanian", @"阿尔巴尼亚语"],
        @"sr.lproj" : @[@"sr.lproj", @"Serbian", @"塞尔维亚语"]
    };
}

@end
