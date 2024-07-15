//
//  ViewController.m
//  ZFLanguageLocalized
//
//  Created by 610582 on 2019/4/17.
//  Copyright © 2019 610582. All rights reserved.
//

#import "ViewController.h"
#import "ZafulParser.h"
#import "MatchLanguageManager.h"
#import "ReadCSVFileManager.h"

static NSString *kLanguageLocalized = @"ZFLanguageLocalized";

@interface ViewController ()<NSTextFieldDelegate>
//csv翻译文件
@property (weak) IBOutlet NSTextField *csvPathCell;
@property (weak) IBOutlet NSTextField *csvTipLabel;
//项目多语言目录
@property (weak) IBOutlet NSTextField *localizblePathCell;
@property (weak) IBOutlet NSTextField *localizbleTipLabel;
//执行提示
@property (weak) IBOutlet NSImageView *statusImageView;
@property (weak) IBOutlet NSTextField *statusTipLabel;
@property (weak) IBOutlet NSProgressIndicator *loadingView;
//操作按钮
@property (weak) IBOutlet NSButton *executeButton;
//多语言文件映射
@property (nonatomic, strong) NSDictionary *mappingLanguageDict;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSImage *image = [NSImage imageNamed:@"background"];
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    layer.contents = (__bridge id _Nullable)[self imageToCGImageRef:image];
    layer.opacity = 1.0;
    [self.view.layer addSublayer:layer];
}

//NSImage 转为 CGImageRef
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

- (void)viewDidAppear {
    [super viewDidAppear];
    NSString *filePath = [[NSUserDefaults standardUserDefaults] objectForKey:kLanguageLocalized];
    if ([filePath isKindOfClass:[NSString class]] && filePath.length > 0) {
        self.localizblePathCell.stringValue = filePath;
        [self refreshUI];
    }
}

#pragma mark - refreshUI

- (void)controlTextDidChange:(NSNotification *)obj {
    [self refreshUI];
}

- (void)refreshUI {
    self.csvTipLabel.hidden = YES;
    self.localizbleTipLabel.hidden = YES;
    self.statusImageView.hidden = YES;
    self.statusTipLabel.hidden = YES;
    
    self.executeButton.enabled = (self.csvPathCell.stringValue.length > 0 &&
                                  self.localizblePathCell.stringValue.length > 0);
}

- (void)showCheckTip:(NSString *)tipText tipLabel:(NSTextField *)tipLabel {
    dispatch_async(dispatch_get_main_queue(), ^{
        tipLabel.hidden = NO;
        tipLabel.stringValue = tipText;
        self.loadingView.hidden = YES;
    });
}

- (void)showResultTip:(NSString *)tipText status:(BOOL)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.csvPathCell.enabled = YES;
        self.localizblePathCell.enabled = YES;
        
        self.loadingView.hidden = YES;
        
        self.statusImageView.image = [NSImage imageNamed:(status ? @"success" : @"fail")];
        self.statusImageView.hidden = NO;
        
        self.statusTipLabel.hidden = NO;
        self.statusTipLabel.stringValue = tipText;

        self.executeButton.enabled = !status;
    });
}

- (BOOL)checkTipInputPath:(NSString *)filePath
                 tipLabel:(NSTextField *)tipLabel {
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    
    BOOL isCSV = (tipLabel == self.csvTipLabel);
    BOOL isLocalizble = (tipLabel == self.localizbleTipLabel);
    NSString *tipStr = nil;
    if (!isExists) {
        if (isCSV) {
            tipStr = @"选择的csv文件不存在!";
        } else if (isLocalizble) {
            tipStr = @"localizble文件夹目录不存在！";
        }
    }
    if (tipStr == nil && !isDirectory) {
        if (isCSV && ![filePath hasSuffix:@"csv"]) {
            tipStr = @"仅支持csv文件!";
        } else if (isLocalizble) {
            tipStr = @"localizble目录只能选择文件夹!";
        }
    }
    if (tipStr != nil) {
        [self showCheckTip:tipStr tipLabel:tipLabel];
    }
    return tipStr == nil;
}

#pragma mark - 处理添加多语言

/// 选择需要追加翻译的CSV文件路径
- (IBAction)excelPathButtonAction:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO; //是否允许多选file
    panel.canChooseDirectories = NO;   //是否允许选择文件夹
    panel.allowedFileTypes = @[@"csv"]; //只能选择csv文件
    
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseCancel)return;
        NSString *filePath = panel.URL.path;
        
        if ([self checkTipInputPath:filePath tipLabel:self.csvTipLabel]) {
            self.csvPathCell.stringValue = panel.URL.path;
            [self refreshUI];
        }
    }];
}

/// 选择项目国际化文件夹路径: 每个翻译文件的父文件夹
- (IBAction)localizblePathButtonAction:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = YES; //只允许选择文件夹
    
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseCancel)return;
        NSString *filePath = panel.URL.path;
        
        if ([self checkTipInputPath:filePath tipLabel:self.localizbleTipLabel]) {
            self.localizblePathCell.stringValue = panel.URL.path;
            [self refreshUI];
        }
    }];
}

/// 开始转换翻译
- (IBAction)startConvertAction:(NSButton *)sender {
    if (![self checkTipInputPath:self.csvPathCell.stringValue tipLabel:self.csvTipLabel]) return;
    if (![self checkTipInputPath:self.localizblePathCell.stringValue tipLabel:self.localizbleTipLabel]) return;
    
    self.csvPathCell.enabled = NO;
    self.localizblePathCell.enabled = NO;
    self.loadingView.hidden = NO;
    [self.loadingView startAnimation:nil];
    self.executeButton.enabled = NO;
    
    // 开始添加CSV表格中的多语言翻译
    NSString *csvFileURL = self.csvPathCell.stringValue;
    NSString *localizbleURL = self.localizblePathCell.stringValue;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self dealwithMappingLanguage: csvFileURL 
                       localizblePath: localizbleURL];
    });
}

/// 开始处理添加/替换多语言
- (void)dealwithMappingLanguage:(NSString *)csvURL
                 localizblePath:(NSString *)localizbleURL {
    
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showCheckTip:@"目录文件夹不存在需要翻译的多语言文件" tipLabel:self.localizbleTipLabel];
        });
        return;
    }
    
    // 读取CSV文件内容
    NSDictionary *csvToArrayDataDict = [ReadCSVFileManager readCSVFileToArray:csvURL];
    NSDictionary *csvToDictDataDict = [ReadCSVFileManager readCSVFileToDict:csvURL];

    if (![csvToArrayDataDict isKindOfClass:[NSDictionary class]] || csvToArrayDataDict.count == 0) {
        [self showResultTip:@"多语言翻译失败, \n请检查CSV文件内容是否错误" status:NO];
        return;
    } else {
        //NSLog(@"成功解析出的CSV文件内容===%@", readCSVToArrayDict);
    }
    NSInteger writeSuccessCount = 0;
    NSString *englishKey = self.mappingLanguageDict[@"英语"];
    NSArray *englishLanguageArr = csvToArrayDataDict[englishKey];
    
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
        
        //⚠️2. 再把CSV文件中的匹配到的翻译追加到 旧的翻译中去
        NSArray *addLanguageStrArr = csvToArrayDataDict[fileName];
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
        NSDictionary *csvInfoDict = csvToDictDataDict[fileName];
        if ([csvInfoDict isKindOfClass:[NSDictionary class]] && csvInfoDict.count > 0) {
            
            for (NSString *languageKey in csvInfoDict.allKeys) {
                NSString *languageValue = csvInfoDict[languageKey];
                //替换现有key中相同key的翻译
                NSString *replaceResultString = [MatchLanguageManager replaceStringInContent44:allFileString
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
        [[NSUserDefaults standardUserDefaults] setObject:localizbleURL forKey:kLanguageLocalized];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self showResultTip:@"💐恭喜, 多语言文件翻译全部成功" status:YES];
    } else {
        NSString *tipStr = writeSuccessCount > 0 ? @"😰多语言文件翻译 部分成功,部分失败, \n请检查CSV文件内容是否正确" : @"😰未知错误 翻译失败, \n请检查CSV文件内容是否正确";
        [self showResultTip:tipStr status:NO];
    }
}

/**
 * 此字典是用来映射CSV文件中的每列的翻译需要对应添加到项目的哪个翻译文件中去的
 * 英文 / 法语 / 西班牙语 / 阿拉伯语 / 德语 / 印尼语 / 泰语 / 葡语 / 意大利语 / 俄语 / 孟加拉语 / 繁体中文
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
            @"葡萄牙语" : @"pt.lproj",
            
            @"孟加拉语" : @"bn.lproj",
            
            @"zh-Hans.lproj"  : @"zh-Hans.lproj",
            @"zh-Hans" : @"zh-Hans.lproj",
            @"汉语"    : @"zh-Hans.lproj",
            @"中文"    : @"zh-Hans.lproj",
            @"简体中文" : @"zh-Hans.lproj",
            @"繁体中文" : @"zh-Hant-TW.lproj",};
    }
    return _mappingLanguageDict;
}

@end
