//
//  ViewController.m
//  ZFLanguageLocalized
//
//  Created by 610582 on 2019/4/17.
//  Copyright © 2019 610582. All rights reserved.
//

#import "ViewController.h"
#import "ZafulParser.h"

@interface ViewController ()<NSTextFieldDelegate>

@property (weak) IBOutlet NSTextField *excelPathCell;
@property (weak) IBOutlet NSTextField *excelLabel;
@property (nonatomic, copy) NSString *excelPath;

@property (weak) IBOutlet NSTextField *localizblePathCell;
@property (weak) IBOutlet NSTextField *localizbleLabel;
@property (nonatomic, copy) NSString *localizblePath;

@property (weak) IBOutlet NSTextField *versionFlagCell;
@property (weak) IBOutlet NSTextField *versionLabel;
@property (nonatomic, copy) NSString *versionFlag;

@property (weak) IBOutlet NSImageView *errorImageView;
@property (weak) IBOutlet NSProgressIndicator *indictorView;
@property (weak) IBOutlet NSTextField *errorLabel;
@property (weak) IBOutlet NSButton *executeButton;
@property (nonatomic, assign) BOOL writeLangSuccess;
@property (nonatomic, strong) NSMutableArray *littleLangFailPathArray;// 部分失败
@property (nonatomic, strong) NSDictionary *mappingLanguageDict;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSImage *image = [NSImage imageNamed:@"background"];
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    layer.contents = (__bridge id _Nullable)[self imageToCGImageRef:image];
    layer.opacity = 0.05;
    [self.view.layer addSublayer:layer];
}

#pragma mark - NSNotification
- (void)refreshUI {
    [self controlTextDidChange:nil];
}

- (void)controlTextDidChange:(NSNotification *)obj {
    self.errorImageView.hidden = YES;
    self.errorLabel.hidden = YES;
    
    self.excelLabel.hidden = YES;
    self.excelPath = self.excelPathCell.stringValue;
    
    self.localizbleLabel.hidden = YES;
    self.localizblePath = self.localizblePathCell.stringValue;
    
    self.versionLabel.hidden = YES;
    self.versionFlag = self.versionLabel.stringValue;
    
    self.executeButton.enabled = (self.excelPathCell.stringValue.length >0 && self.localizblePathCell.stringValue.length >0 && self.versionFlagCell.stringValue.length >0);
    self.versionFlag = self.versionFlagCell.stringValue;
}

#pragma mark - ButtonAction

- (IBAction)excelPathButtonAction:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO; //是否允许多选file
    panel.canChooseDirectories = NO;   //是否允许选择文件夹
    panel.allowedFileTypes = @[@"csv"]; //只能选择csv文件
    
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseCancel)return;
        NSString *filePath = panel.URL.path;
        
        if ([self judgeExcelPathIsSuccess:filePath]) {
            self.excelPathCell.stringValue = panel.URL.path;
            self.excelPath = panel.URL.path;
            [self refreshUI];
        }
    }];
}

- (IBAction)localizblePathButtonAction:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = YES; //只允许选择文件夹
    
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseCancel)return;
        NSString *filePath = panel.URL.path;
        
        if ([self judgeLocalizblePathIsSuccess:filePath]) {
            self.localizblePathCell.stringValue = panel.URL.path;
            self.localizblePath = panel.URL.path;
            [self refreshUI];
        }
    }];
}

- (IBAction)startConvertAction:(NSButton *)sender {
    if (![self judgeExcelPathIsSuccess:self.excelPath]) return;
    if (![self judgeLocalizblePathIsSuccess:self.localizblePath]) return;
    
    if (!self.versionFlag || self.versionFlag.length < 10) {
        self.versionLabel.stringValue = @"版本号标识过短, 请重新输入";
        self.versionLabel.hidden = NO;
        return;
    }
    if (!([self.versionFlag hasPrefix:@"//========"] || [self.versionFlag hasPrefix:@"// ======="])
        || (![self.versionFlag containsString:@"V"] || ![self.versionFlag containsString:@"."])) {
        self.versionLabel.stringValue = @"版本号标识不符合规范, 请输入类似\"//====V4.x.x====\"标识";
        self.versionLabel.hidden = NO;
        return;
    }
    
    sender.enabled = NO;
    self.indictorView.hidden = NO;
    [self.indictorView startAnimation:nil];
    [self.littleLangFailPathArray removeAllObjects];
    self.versionLabel.hidden = YES;
    
    // 开始翻译多语言
    NSString *csvFilePath = self.excelPathCell.stringValue;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self startParseReplaceManyLanguage:csvFilePath];
    });
}

// 开始翻译多语言
- (void)startParseReplaceManyLanguage:(NSString *)csvFilePath {
    NSFileManager *fileManger = [NSFileManager defaultManager];
    
    NSMutableArray *allLanguageDirArray = [NSMutableArray arrayWithArray:[fileManger contentsOfDirectoryAtPath:self.localizblePath error:nil]];
    [allLanguageDirArray removeObject:@".DS_Store"];//排除异常文件
    
    // 获取多语言目录列表: Key（Android/iOS Key), en.lproj, de.lproj, es.lproj ...
    NSMutableDictionary *langLprojDict = [NSMutableDictionary dictionary];
    for (NSString *pathDicr in allLanguageDirArray) {
        //NSLog(@"多语言文件夹子目录===%@", pathDicr);
        
        NSString *localizablePath = [NSString stringWithFormat:@"%@/%@/Localizable.strings", self.localizblePath, pathDicr];
        if ([fileManger fileExistsAtPath:localizablePath]) {
            langLprojDict[pathDicr] = localizablePath;
        }
    }
    
    if (langLprojDict.allKeys.count == 0) {
        [self showErrorText:@"目录文件夹不存在需要翻译的多语言文件" excelLabel:self.localizbleLabel];
        return;
    }
    
    NSArray *parseStringArray = [ZafulParser professionalParserCsvFileWithPath:csvFilePath];
    if (![parseStringArray isKindOfClass:[NSArray class]] || parseStringArray.count == 0) {
        parseStringArray = [ZafulParser backupParserCsvFileWithPath:csvFilePath];
    }

    if (![parseStringArray isKindOfClass:[NSArray class]] || parseStringArray.count == 0) {
        [self showStatusTip:@"多语言翻译失败, 请检查CSV文件内容是否错误" status:NO];
        return;
    } else {
        //NSLog(@"成功解析出的CSV文件内容===%@", parseStringArray);
    }
    
    // 根据目前已对接的翻译映射成多语言标识 (英文 -> en.lproj)
    NSMutableArray *languageFlagArr = [NSMutableArray array];
    if ([parseStringArray.firstObject isKindOfClass:[NSArray class]]) {
        
        languageFlagArr = [NSMutableArray arrayWithArray:parseStringArray.firstObject];
        for (NSInteger i=0; i<((NSArray *)parseStringArray.firstObject).count; i++) {
            if (i == 0) continue;//翻译key
            NSString *replaceKey = languageFlagArr[i];
            if (![replaceKey isKindOfClass:[NSString class]]) continue;
            
            NSString *mappingKey = self.mappingLanguageDict[replaceKey];
            if (![mappingKey isKindOfClass:[NSString class]]) continue;
            languageFlagArr[i] = mappingKey;
        }
    }
    
    // 异常判断
    for (NSArray *temColumnArray in parseStringArray) {
        if (![temColumnArray isKindOfClass:[NSArray class]] ||
            temColumnArray.count != languageFlagArr.count) {
            [self showStatusTip:@"多语言翻译失败, 请检查CSV文件内容是否错误" status:NO];
            return;
        }
    }
    
    NSMutableDictionary *allAppdingDict = [NSMutableDictionary dictionary];
    NSArray *firstInfoArray = parseStringArray.firstObject;
    
    // 找出英语在每行第几列
    NSInteger englishColumnIndex = -1;
    if ([firstInfoArray containsObject:@"英语"]) {
        englishColumnIndex = [firstInfoArray indexOfObject:@"英语"];
    }
    if (englishColumnIndex == -1 && [firstInfoArray containsObject:@"英文"]) {
        englishColumnIndex = [firstInfoArray indexOfObject:@"英文"];
    }
    if (englishColumnIndex == -1 && [firstInfoArray containsObject:@"en.lproj"]) {
        englishColumnIndex = [firstInfoArray indexOfObject:@"en.lproj"];
    }
    
    if (englishColumnIndex == -1) {
        englishColumnIndex = 1;
    }
    
    // 剔除csv文件的第一行数组 -> (key,  英文, 意大利语, 葡萄牙语, 繁体中文...)
    NSArray *allColumnArray = [parseStringArray subarrayWithRange:NSMakeRange(1, parseStringArray.count-1)];
    
    for (NSInteger j=0; j<allColumnArray.count; j++) {
        NSArray *tempRowStringArray = allColumnArray[j];
        
        NSString *languageKey = tempRowStringArray.firstObject; // 每个数组的第一个是:key
        for (NSInteger i=0; i<tempRowStringArray.count; i++) {
            if (i == 0) continue;
            
            NSString *languageValue = tempRowStringArray[i];
            
            if (![languageValue isKindOfClass:[NSString class]] || languageValue.length == 0) {
                if (tempRowStringArray.count > englishColumnIndex) {
                    languageValue = tempRowStringArray[englishColumnIndex];
                }
            }
            
            // 转义替换翻译中存在的换行符
            languageValue = [languageValue stringByReplacingOccurrencesOfString:@"\n" withString:@"\\\n"];
            
            // 转义替换翻译中存在的引号
            languageValue = [languageValue stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            
            NSMutableString *appdingString = [NSMutableString stringWithString:@"\n"];
            [appdingString appendFormat:@"\"%@\" = \"%@\";", languageKey, languageValue];
            
            NSString *language = languageFlagArr[i];
            NSString *lastValue = allAppdingDict[language];
            if (lastValue) {
                allAppdingDict[language] = [NSString stringWithFormat:@"%@%@", lastValue, appdingString];
            } else {
                allAppdingDict[language] = appdingString;
            }
        }
    }
    //NSLog(@"多语言===%@", allAppdingDict);
    
    // 保存一份英语的翻译, 发现在没有给出翻译时用到英语替换
    NSString *appdingEnglishString = @"";
    
    // 备份多语言替换操作路径
    NSMutableDictionary *backupLangLprojDict = [NSMutableDictionary dictionaryWithDictionary:langLprojDict];
    
    // 语言替换
    for (NSString *langKey in langLprojDict.allKeys) {
        if (![langKey hasSuffix:@".lproj"]) continue;
        
        for (NSString *appdingLangKey in allAppdingDict.allKeys) {
            
            if (![langKey isEqualToString:appdingLangKey]) continue;
            
            NSString *localizablePath = langLprojDict[langKey];
            
            NSError *error = nil;
            NSString *allFileString = [NSString stringWithContentsOfFile:localizablePath encoding:NSUTF8StringEncoding error:&error];
            if (error || !allFileString || allFileString.length == 0) {
                [self showStatusTip:[NSString stringWithFormat:@"部分多语言翻译失败, 请检查%@ 文件内容是否错误", localizablePath] status:NO];
                [self.littleLangFailPathArray addObject:[NSString stringWithFormat:@"%@", localizablePath]];
                continue;
            }
            
            //保存一份英语
            NSString *appdingString = allAppdingDict[appdingLangKey];
            if ([appdingLangKey isEqualToString:@"en.lproj"]) {
                appdingEnglishString = appdingString;
            }
            
            // 没有给出相应语言的翻译就用英语替换
            if (![appdingString isKindOfClass:[NSString class]] ||
                appdingString.length == 0) {
                appdingString = appdingEnglishString;
            }
            
            // 执行多语言替换操作
            NSString *finalAppdingString = [NSString stringWithFormat:@"%@\n", appdingString];
            [self executeManyLaguageReplace:localizablePath
                              allFileString:allFileString
                              appdingString:finalAppdingString];
            
            // 删除已经替换成功的文件路径
            [backupLangLprojDict removeObjectForKey:langKey];
        }
    }
    
    // 替换其他没有给出多语言文件
    for (NSString *langKey in backupLangLprojDict.allKeys) {
        NSString *localizablePath = backupLangLprojDict[langKey];
        
        NSError *error = nil;
        NSString *allFileString = [NSString stringWithContentsOfFile:localizablePath encoding:NSUTF8StringEncoding error:&error];
        if (error || !allFileString || allFileString.length == 0) {
            [self showStatusTip:[NSString stringWithFormat:@"部分多语言翻译失败, 请检查%@ 文件内容是否错误", localizablePath] status:NO];
            [self.littleLangFailPathArray addObject:[NSString stringWithFormat:@"%@", localizablePath]];
            continue;
        }
        
        // 用英语替换所有 为给出翻译的多语言文件
        NSString *finalAppdingString = [NSString stringWithFormat:@"%@\n", appdingEnglishString];
        [self executeManyLaguageReplace:localizablePath
                          allFileString:allFileString
                          appdingString:finalAppdingString];
    }
    
    if (self.writeLangSuccess) {
        NSString *successTipText = @"💐恭喜, 多语言文件翻译成功";
        if (self.littleLangFailPathArray.count > 0) {
            successTipText = [successTipText stringByAppendingString:@", 部分文件失败请检查"];
            //[fileManger open]//打开翻译失败的文件
        }
        [self showStatusTip:successTipText status:YES];
        
    } else {
        [self showStatusTip:@"😰未知错误 翻译失败, 请检查CSV文件内容是否正确" status:YES];
    }
}

/**
 * 执行多语言替换操作
 */
- (void)executeManyLaguageReplace:(NSString *)localizablePath
                    allFileString:(NSString *)allFileString
                    appdingString:(NSString *)appdingString
{
    NSError *error = nil;
    if (self.versionFlag && self.versionFlag.length>0) {
        NSRange range = [allFileString rangeOfString:self.versionFlag];
        
        //不存在版本号标识就末尾追加写入多语言
        if (range.location == NSNotFound) {
            // 没找到就拼接到文件最后面
            appdingString = [NSString stringWithFormat:@"%@%@\n",self.versionFlag, appdingString];
            
            NSString *replaceAllString = [allFileString stringByAppendingString:appdingString];
            self.writeLangSuccess = [replaceAllString writeToFile:localizablePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
            
        } else {
            //存在版本号标识就替换相应版本号的多语言
            NSString *replaceAllString = @"";
            NSString *tempAppdingString = [allFileString substringToIndex:(range.location + range.length)];
            
            NSString *allFileLastString = [allFileString componentsSeparatedByString:tempAppdingString].lastObject;
            if (allFileLastString) {
                NSString *needReplaceString =  [allFileLastString componentsSeparatedByString:@"\n//"].firstObject;
                
                if (needReplaceString) {
                    replaceAllString = [allFileString stringByReplacingOccurrencesOfString:needReplaceString withString:appdingString];
                }
            } else {
                replaceAllString = [tempAppdingString stringByAppendingString:appdingString];
            }
            
            // 替换相应版本号的多语言
            if (replaceAllString && replaceAllString.length > 0) {
                self.writeLangSuccess = [replaceAllString writeToFile:localizablePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
            }
        }
    } else {
        // 没找到就拼接到文件最后面
        appdingString = [NSString stringWithFormat:@"%@%@\n",self.versionFlag, appdingString];
        
        NSString *replaceAllString = [allFileString stringByAppendingString:appdingString];
        self.writeLangSuccess = [replaceAllString writeToFile:localizablePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    }
}

-(NSMutableArray *)littleLangFailPathArray {
    if (!_littleLangFailPathArray) {
        _littleLangFailPathArray = [NSMutableArray array];
    }
    return _littleLangFailPathArray;
}

#pragma mark - <Other deal with>

- (void)showStatusTip:(NSString *)statusText status:(BOOL)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.errorImageView.image = [NSImage imageNamed:(status ? @"success" : @"fail")];
        self.errorLabel.hidden = NO;
        self.errorImageView.hidden = NO;
        self.indictorView.hidden = YES;
        self.errorLabel.stringValue = statusText;
        self.executeButton.enabled = YES;
        if (status) {
            self.localizblePathCell.stringValue = @"";
            self.executeButton.enabled = NO;
        }
    });
}

- (void)showErrorText:(NSString *)errorText excelLabel:(NSTextField *)excelLabel {
    dispatch_async(dispatch_get_main_queue(), ^{
        excelLabel.hidden = NO;
        excelLabel.stringValue = errorText;
        self.indictorView.hidden = YES;
    });
}

- (BOOL)judgeExcelPathIsSuccess:(NSString *)filePath {
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (!isExists) {
        [self showErrorText:@"选择的csv文件不存在" excelLabel:self.excelLabel];
        return NO;
    }
    if (!isDirectory && ![filePath hasSuffix:@"csv"]) {
        [self showErrorText:@"仅支持csv文件!" excelLabel:self.excelLabel];
        return NO;
    }
    return YES;
}

- (BOOL)judgeLocalizblePathIsSuccess:(NSString *)filePath {
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    if (!isExists) {
        [self showErrorText:@"localizble文件夹目录不存在！" excelLabel:self.localizbleLabel];
        return NO;
    }
    if (!isDirectory) {
        [self showErrorText:@"localizble目录只能选择文件夹!" excelLabel:self.localizbleLabel];
        return NO;
    }
    return YES;
}

//NSImage 翻译为 CGImageRef
- (CGImageRef)imageToCGImageRef:(NSImage*)image {
    NSData * imageData = [image TIFFRepresentation];
    CGImageRef imageRef = nil;
    if(imageData){
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
        imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    }
    return imageRef;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

/**
 * 到V4.5.6为止目前项目中存在的多言
 * 英文 / 法语 / 西班牙语 / 阿拉伯语 / 德语 / 印尼语 / 泰语 / 葡语 / 意大利语 / 俄语 / 繁体中文
 */
- (NSDictionary *)mappingLanguageDict {
    if (!_mappingLanguageDict) {
        _mappingLanguageDict = @{
                                 @"德语" : @"de.lproj",
                                 @"法语" : @"fr.lproj",
                                 @"泰语" : @"th.lproj",
                                 
                                 @"英文"  : @"en.lproj",
                                 @"英语"  : @"en.lproj",
                                 
                                 @"越南语"  : @"vi.lproj",
                                 @"越语"    : @"vi.lproj",
                                 
                                 @"俄罗斯语" : @"ru.lproj",
                                 @"俄语"    : @"ru.lproj",
                                 
                                 @"土耳其语" : @"tr.lproj",
                                 @"土耳其"   : @"tr.lproj",
                                 
                                 @"阿语"     : @"ar.lproj",
                                 @"阿拉伯语"  : @"ar.lproj",
                                 
                                 @"西语"     : @"es.lproj",
                                 @"西班牙语"  : @"es.lproj",
                                 
                                 @"印度尼西亚" : @"id.lproj",
                                 @"印尼语"    : @"id.lproj",
                                 
                                 @"意大利语" : @"it.lproj",
                                 @"意语"    : @"it.lproj",
                                 
                                 @"葡语"    : @"pt.lproj",
                                 @"葡萄牙"   : @"pt.lproj",
                                 
                                 @"zh-Hans.lproj"  : @"zh-Hans.lproj",
                                 @"zh-Hans"        : @"zh-Hans.lproj",
                                 @"繁体中文" : @"zh-Hant-TW.lproj",};
    }
    return _mappingLanguageDict;
}

@end
