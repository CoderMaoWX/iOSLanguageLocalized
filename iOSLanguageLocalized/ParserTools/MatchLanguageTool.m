//
//  MatchLanguageString.m
//  TestDemo
//
//  Created by Luke on 2024/7/13.
//

#import "MatchLanguageTool.h"
#import "ReadCSVFileTool.h"
#import "ParserManager.h"

@implementation MatchLanguageTool

/**
 * 专业的解析方案, (有可能为空)
 */
+ (NSArray *)professionalParserCsvFileWithPath:(NSString *)filePath {
    ParserManager *parser = [[ParserManager alloc] init];
    BOOL open = [parser openFileWithPath:filePath];
    if (open) {
        [parser autodetectDelimiter];
        NSArray *infoArray = [parser parseFile];
        [parser closeFile];
        //NSLog(@"readCSVData111===%@", infoArray);
        return infoArray;
    } else {
        //NSLog(@"解析文件失败111");
        return nil;
    }
}

+ (NSDictionary *)readCSVFileToArray:(NSString *)filePath {
    NSMutableDictionary *bigDict = [NSMutableDictionary dictionary];
    
    //解析成一行一行的数据
    NSMutableArray *paraDataArr = [NSMutableArray arrayWithArray:[MatchLanguageTool professionalParserCsvFileWithPath:filePath]];
    
    NSArray *headerFieldArr = paraDataArr.firstObject;
    [paraDataArr removeObjectAtIndex:0];
    
    for (NSArray *fieldValueArr in paraDataArr) {
        
        NSString *firstKey = nil;
        for (NSInteger j=0; j < fieldValueArr.count; j++) {
            NSString *fieldString = [MatchLanguageTool fileFieldValue: fieldValueArr[j] ];
            
            if (j == 0) {
                firstKey = fieldString;
            } else {
                NSString *keyValue = [NSString stringWithFormat:@"\"%@\" = \"%@\";", firstKey, fieldString];
                
                if (fieldValueArr.count == headerFieldArr.count && headerFieldArr.count > j) {
                    NSString *language = [MatchLanguageTool fileFieldValue: headerFieldArr[j] ];
                    
                    NSMutableArray *bigDictArr = bigDict[ language ];
                    if (![bigDictArr isKindOfClass:[NSMutableArray class]]) {
                        bigDictArr = [NSMutableArray array];
                    }
                    
                    if (fieldString.length == 0) { // 如果没有相应的翻译, 则使用英语
                        
                        NSString *chineseKey = [MatchLanguageTool chineseCSVKey];
                        NSArray *chineseAllKeyArr = self.mappingLanguageDict[chineseKey];
                        //如果是中文的value不存在
                        if ([chineseAllKeyArr containsObject:language]) {
                            //如果是中文: 特殊设置把key和value设置成一样的, 因为项目中是直接把中文当做key的
                            keyValue = [NSString stringWithFormat:@"\"%@\" = \"%@\";", firstKey, firstKey];
                            
                        } else {
                            NSString *englishKey = [MatchLanguageTool englishCSVKey];
                            //如果没匹配到英语的key, 就找映射字典看能否再次匹配
                            if (![bigDict.allKeys containsObject:englishKey]) {
                                englishKey = [self matchLanguageKey:englishKey csvToArrayDataDict:bigDict];
                            }
                            
                            NSArray *englishKeyValueArr = bigDict[englishKey];
                            if ([englishKeyValueArr isKindOfClass:[NSArray class]]) {
                                NSString *tmpEnglishKey = [NSString stringWithFormat:@"\"%@\" =", firstKey];
                                for (NSString *englishKeyValue in englishKeyValueArr) {
                                    if ([englishKeyValue containsString:tmpEnglishKey]) {
                                        keyValue = englishKeyValue;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    
                    [bigDictArr addObject:keyValue];
                    bigDict[ language ] = bigDictArr;
                }
            }
        }
    }
    return bigDict;
}

+ (NSDictionary *)readCSVFileToDict:(NSString *)filePath {
    NSMutableDictionary *bigDict = [NSMutableDictionary dictionary];
    
    //解析成一行一行的数据
    NSMutableArray *paraDataArr = [NSMutableArray arrayWithArray:[MatchLanguageTool professionalParserCsvFileWithPath:filePath]];
    
    NSArray *headerFieldArr = paraDataArr.firstObject;
    [paraDataArr removeObjectAtIndex:0];
    
    for (NSArray *fieldValueArr in paraDataArr) {
        
        NSString *firstKey = nil;
        for (NSInteger j=0; j < fieldValueArr.count; j++) {
            NSString *fieldString = [MatchLanguageTool fileFieldValue: fieldValueArr[j] ];
            
            if (j == 0) {
                firstKey = fieldString;
            } else {
                //NSString *keyValue = [NSString stringWithFormat:@"\"%@\" = \"%@\";", firstKey, fieldString];
                
                if (fieldValueArr.count == headerFieldArr.count && headerFieldArr.count > j) {
                    NSString *language = [MatchLanguageTool fileFieldValue: headerFieldArr[j] ];
                    
                    NSMutableDictionary *bigDictArrDict = bigDict[ language ];
                    if (![bigDictArrDict isKindOfClass:[NSMutableDictionary class]]) {
                        bigDictArrDict = [NSMutableDictionary dictionary];
                    }
                    
                    if (fieldString.length == 0) { // 如果没有相应的翻译, 则使用英语
                        
                        NSString *chineseKey = [MatchLanguageTool chineseCSVKey];
                        NSArray *chineseAllKeyArr = self.mappingLanguageDict[chineseKey];
                        //如果是中文的value不存在
                        if ([chineseAllKeyArr containsObject:language]) {
                            //如果是中文: 特殊设置把key和value设置成一样的, 因为项目中是直接把中文当做key的
                            fieldString = firstKey;
                            
                        } else {
                            NSString *englishKey = [MatchLanguageTool englishCSVKey];
                            //如果没匹配到英语的key, 就找映射英语看能否再次匹配
                            if (![bigDict.allKeys containsObject:englishKey]) {
                                englishKey = [self matchLanguageKey:englishKey csvToArrayDataDict:bigDict];
                            }
                            
                            NSDictionary *englishDict = bigDict[englishKey];
                            if ([englishDict isKindOfClass:[NSDictionary class]]) {
                                fieldString = englishDict[firstKey];
                            }
                        }
                    }
                    
                    bigDictArrDict[firstKey] = fieldString;
                    bigDict[ language ] = bigDictArrDict;
                }
            }
        }
    }
    return bigDict;
}

/// 过滤字符串的各种空格和换行符等
+ (NSString *)fileFieldValue:(NSString *)fieldValue {
    if (![fieldValue isKindOfClass:[NSString class]] || fieldValue.length == 0) {
        return @"";
    }
    NSString *fieldString = [NSString stringWithString:fieldValue];
    //去除两头的空格
    fieldString = [fieldString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    //去除所有换行符
    fieldString = [fieldString stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    fieldString = [fieldString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    fieldString = [fieldString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    return fieldString;
}

+ (NSString *)englishCSVKey {
    return @"en.lproj";
}

+ (NSString *)chineseCSVKey {
    return @"zh-Hans.lproj";
}

/// 开始导入多语言
+ (void)mappingLanguage:(NSString *)csvURL
         localizblePath:(NSString *)localizbleURL
            compeletion:(void (^)(BOOL checkSuccess, NSString *tipString, BOOL tipStatus))compeletion {
    
    NSFileManager *fileManger = [NSFileManager defaultManager];
    
    NSMutableArray *allLanguageDirArray = [NSMutableArray arrayWithArray:[fileManger contentsOfDirectoryAtPath:localizbleURL error:nil]];
    [allLanguageDirArray removeObject:@".DS_Store"];//排除异常文件
    
    if (allLanguageDirArray.count == 0) {
        if (compeletion) {
            compeletion(NO, @"项目路径文件夹中不存在文件名字为Localizable.strings的翻译文件", NO);
        }
        return;
    }
    
    // 获取多语言目录列表: Key（Android/iOS Key), en.lproj, de.lproj, es.lproj ...
    NSMutableDictionary *appLprojDict = [NSMutableDictionary dictionary];
    for (NSString *pathDicr in allLanguageDirArray) {
        //NSLog(@"多语言文件夹子目录===%@", pathDicr);
        
        NSString *localizablePath = [NSString stringWithFormat:@"%@/%@/Localizable.strings", localizbleURL, pathDicr];
        if ([fileManger fileExistsAtPath:localizablePath]) {
            appLprojDict[pathDicr] = localizablePath;
        } else {
            if (compeletion) {
                compeletion(NO, @"项目路径文件夹中不存在文件名字为Localizable.strings的翻译文件", NO);
            }
            return;
        }
    }
    
    if (appLprojDict.allKeys.count == 0) {
        if (compeletion) {
            compeletion(NO, @"目录文件夹不存在需要导入的多语言文件", NO);
        }
        return;
    }
    
    // 读取CSV文件内容
    NSDictionary *csvToArrayDataDict = [MatchLanguageTool readCSVFileToArray:csvURL];
    NSDictionary *csvToDictDataDict = [MatchLanguageTool readCSVFileToDict:csvURL];
    
    //如果解析异常了, 在尝试采用自主解析方案
    if (csvToArrayDataDict.count == 0 || csvToDictDataDict.count == 0) {
        csvToArrayDataDict = [ReadCSVFileTool readCSVFileToArray:csvURL];
        csvToDictDataDict = [ReadCSVFileTool readCSVFileToDict:csvURL];
    }
    //    NSLog(@"成功解析出的CSV文件内容===%@", csvToArrayDataDict);
    
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
    //NSLog(@"成功解析出的CSV文件内容===%@", readCSVToArrayDict);
    
    NSString *englishKey = [MatchLanguageTool englishCSVKey];
    NSInteger writeSuccessCount = 0;
    NSArray *englishLanguageArr = csvToArrayDataDict[englishKey];
    
    //如果没匹配到英语的key, 就找映射英语看能否再次匹配
    if (![englishLanguageArr isKindOfClass:[NSArray class]] ||
        ![csvToArrayDataDict.allKeys containsObject:englishKey]) {
        NSString *englishMapKey = [self matchLanguageKey:englishKey csvToArrayDataDict:csvToArrayDataDict];
        englishLanguageArr = csvToArrayDataDict[englishMapKey];
    }
    
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
            writeSuccessCount += 1;
        }
    }
    
    if (writeSuccessCount == appLprojDict.allKeys.count) {
        if (compeletion) {
            compeletion(YES, @"💐恭喜, 多语翻译言文件全部导入成功", YES);
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
        @"fil.lproj" : @[@"fil.lproj", @"Filipino", @"菲律宾语"],
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

//方案: 通过逐行读取和处理来提高效率 (删除掉多余相同的行，只保留第一个行进行替换)
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

@end
