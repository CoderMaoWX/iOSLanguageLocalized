//
//  ViewController.m
//  iOSLanguageLocalized
//
//  Created by 610582 on 2019/4/17.
//  Copyright © 2019 610582. All rights reserved.
//

#import "ViewController.h"
#import "MatchLanguageTool.h"
#import "OuputCSVFileTool.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface ViewController ()<NSTextFieldDelegate>

//项目多语言目录
@property (weak) IBOutlet NSTextField *localizblePathCell;
@property (weak) IBOutlet NSTextField *localizbleTipLabel;
@property (weak) IBOutlet NSButton *chooseLocalizbleBtn;

//csv翻译文件
@property (weak) IBOutlet NSTextField *csvPathCell;
@property (weak) IBOutlet NSTextField *csvTipLabel;
@property (weak) IBOutlet NSButton *chooseCSVBtn;

//执行提示
@property (weak) IBOutlet NSImageView *statusImageView;
@property (weak) IBOutlet NSTextField *statusTipLabel;
@property (weak) IBOutlet NSProgressIndicator *loadingView;
//导出按钮
@property (weak) IBOutlet NSButton *exportButton;
//导入按钮
@property (weak) IBOutlet NSButton *importButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
    [self refreshUIIsLoading:NO];
    
    BOOL enabled = (self.csvPathCell.stringValue.length > 0 &&
                   self.localizblePathCell.stringValue.length > 0);
    
    self.importButton.enabled = enabled;
    
    self.exportButton.enabled = enabled;
    
    self.statusImageView.hidden = YES;
    self.statusTipLabel.hidden = YES;
}

/// 屏蔽其他点击事件，显示转圈
- (void)refreshUIIsLoading:(BOOL)isLoading {
    
    self.localizblePathCell.enabled = !isLoading;
    self.chooseLocalizbleBtn.enabled = !isLoading;
    self.localizbleTipLabel.textColor = !isLoading ? NSColor.grayColor : NSColor.redColor;
    if (!isLoading) {
        self.localizbleTipLabel.stringValue = @"*请选择项目中的国际化文件（en.lpro）的父文件夹,   注意:仅会读写每个子文件夹中文件名字为Localizable.strings的进行翻译;";
    }
    
    self.csvPathCell.enabled = !isLoading;
    self.chooseCSVBtn.enabled = !isLoading;
    self.csvTipLabel.textColor = !isLoading ? NSColor.grayColor : NSColor.redColor;
    if (!isLoading) {
        self.csvTipLabel.stringValue = @"*如果需要导出翻译，请选择一个的文件夹作为导出存放目录; *如果需要导入翻译，请选择需要导入的（.csv）翻译文件;";
    }

    self.importButton.enabled = !isLoading;
    self.exportButton.enabled = !isLoading;
    
    self.loadingView.hidden = isLoading ? NO : YES;
    [self.loadingView startAnimation:nil];
    
    self.statusImageView.hidden = isLoading ? YES : NO;
    self.statusTipLabel.hidden = isLoading ? YES : NO;
}

- (void)showCheckTip:(NSString *)tipText tipLabel:(NSTextField *)tipLabel {
    tipLabel.hidden = NO;
    tipLabel.stringValue = tipText;
    tipLabel.textColor = NSColor.redColor;
    self.loadingView.hidden = YES;
    self.chooseCSVBtn.enabled = YES;
    self.chooseLocalizbleBtn.enabled = YES;
}

- (void)showResultTip:(NSString *)tipText status:(BOOL)status {
    [self refreshUIIsLoading:NO];
    
    self.statusImageView.image = [NSImage imageNamed:(status ? @"success" : @"fail")];
    self.statusImageView.hidden = NO;
    
    self.statusTipLabel.stringValue = tipText;
    self.statusTipLabel.hidden = NO;

    self.importButton.enabled = !status;
    self.exportButton.enabled = !status;
}

- (BOOL)checkTipInputPath:(NSString *)filePath
                 tipLabel:(NSTextField *)tipLabel {
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    
    BOOL isCSV = (tipLabel == self.csvTipLabel);
    BOOL isLocalizble = (tipLabel == self.localizbleTipLabel);
    NSString *tipStr = nil;
    
    if (isCSV) {
        if (self.csvPathCell.stringValue.length > 0) {
            if (!isExists) {
                tipStr = @"导入翻译时: 请选择正确的.csv文件!";
            } else if (isDirectory) {
                tipStr = @"导入翻译时: 仅支持选择.csv文件!";
            }
        }
    } else if (isLocalizble) {
        if (!isExists) {
            tipStr = @"选择的多语言目录文件夹不存在!";
        } else if (!isDirectory) {
            tipStr = @"多语言目录只能选择文件夹!";
        }
    }
    if (tipStr != nil) {
        [self showCheckTip:tipStr tipLabel:tipLabel];
    }
    return tipStr == nil;
}

#pragma mark - 处理添加多语言

/// 选择项目国际化文件夹路径: 每个翻译文件（en.lpro）的父文件夹
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

/// 选择导入的CSV文件路径， 或者导出的文件夹路径
- (IBAction)csvPathButtonAction:(NSButton *)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO; //是否允许多选file
    panel.canChooseDirectories = YES;   //是否允许选择文件夹
    //panel.allowedFileTypes = @[@"csv"]; //方法过期了
    // 设置只允许选择csv文件
    panel.allowedContentTypes = @[
        [UTType typeWithFilenameExtension:@"csv"],
    ];
    
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseCancel)return;
        NSString *filePath = panel.URL.path;
        
//        if ([self checkTipInputPath:filePath tipLabel:self.csvTipLabel]) {
            self.csvPathCell.stringValue = filePath;
            [self refreshUI];
//        }
    }];
}

/// 开始导出翻译
- (IBAction)exportBtnAction:(NSButton *)sender {
    if (![self checkTipInputPath:self.localizblePathCell.stringValue tipLabel:self.localizbleTipLabel]) return;
    
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:self.csvPathCell.stringValue isDirectory:&isDirectory];
    if (!isExists || !isDirectory) {
        self.csvTipLabel.stringValue = @"导出翻译时: 选择的路径不能为文件，请选择一个正确的文件夹即可!";
        self.csvTipLabel.textColor = NSColor.redColor;
        return;
    }
    
    // 屏蔽其他点击事件，显示转圈
    [self refreshUIIsLoading:YES];
    
    // 需要导出的翻译文件
    NSString *localizbleURL = self.localizblePathCell.stringValue;
    // 导出文件路径
    NSString *outputFilePath = self.csvPathCell.stringValue;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 调用解析和生成CSV的函数
        [OuputCSVFileTool generateCSV:localizbleURL
                           outputPath:outputFilePath
                          compeletion:^(BOOL status, NSString *tipStr) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showResultTip:tipStr status:status];
                
                [[NSUserDefaults standardUserDefaults] setObject:localizbleURL forKey:kLanguageLocalized];
                [[NSUserDefaults standardUserDefaults] synchronize];
            });
        }];
    });
}


/// 开始导入翻译
- (IBAction)importBtnAction:(NSButton *)sender {
    if (![self checkTipInputPath:self.localizblePathCell.stringValue tipLabel:self.localizbleTipLabel]) return;
    if (![self checkTipInputPath:self.csvPathCell.stringValue tipLabel:self.csvTipLabel]) return;
    
    // 屏蔽其他点击事件，显示转圈
    [self refreshUIIsLoading:YES];
    self.localizbleTipLabel.textColor = NSColor.grayColor;
    self.csvTipLabel.textColor = NSColor.grayColor;
    
    // 开始添加CSV表格中的多语言翻译
    NSString *csvFileURL = self.csvPathCell.stringValue;
    NSString *localizbleURL = self.localizblePathCell.stringValue;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        [MatchLanguageTool mappingLanguage:csvFileURL
                            localizblePath:localizbleURL
                               compeletion:^(BOOL checkSuccess, NSString * _Nonnull tipString, BOOL tipStatus) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (checkSuccess) {
                    [self showResultTip:tipString status:tipStatus];
                } else {
                    [self showCheckTip:tipString tipLabel:self.localizbleTipLabel];
                }
                [[NSUserDefaults standardUserDefaults] setObject:localizbleURL forKey:kLanguageLocalized];
                [[NSUserDefaults standardUserDefaults] synchronize];
            });
        }];
    });
}

@end
