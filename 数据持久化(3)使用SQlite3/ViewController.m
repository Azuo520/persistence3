//
//  ViewController.m
//  数据持久化(3)使用SQlite3
//
//  Created by Azuo on 16/1/6.
//  Copyright © 2016年 Azuo. All rights reserved.
//

#import "ViewController.h"
#import <sqlite3.h>         //导入SQLite3，注意是扩折号

//SQLite 是不区分大小写的

@implementation ViewController
{
    sqlite3 *sqlite; //数据库
}

//懒加载
-(NSString *)datafilePath
{
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [array objectAtIndex:0];
    return [path stringByAppendingPathComponent:@"data.sqlite"];
}
//警告提示框,，为后面的操作向用户提示信息
-(void)alert:(NSString *)mes
{
    /*知识点：ios 9.0 后，简单的UIAlertView已经不能用了。
     UIAlertController代替了UIAlertView弹框 和 UIActionSheet下弹框
     */
    //UIAlertControllerStyleAlert：中间；  UIAlertControllerStyleActionSheet：显示在屏幕底部；
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"警告" message:mes preferredStyle:(UIAlertControllerStyleAlert)];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:nil];
    UIAlertAction *defult = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:nil];
    [alert addAction:cancel];
    [alert addAction:defult];
    [self presentViewController:alert animated:YES completion:nil]; //呈现
}


- (void)viewDidLoad {
    [super viewDidLoad];
    int result = sqlite3_open([[self datafilePath]UTF8String], &sqlite);
    //不等于SQLITE_OK，则打开数据库的时候遇到问题
    if(result != SQLITE_OK)
    {
        sqlite3_close(sqlite);
        [self alert:@"数据库打开失败"];
    }
    
    //如果不存在数据表，则新建一个。 若存在，则此命令自动退出. 所以这个语句可以在每次启动时调用
    NSString *createSql = @"CREATE TABLE IF NOT EXISTS 'wenbenkuang'(id INTEGER PRIMARY KEY,datatext TEXT NOT NULL)";
    char * error;
    int ret = sqlite3_exec(sqlite,[createSql UTF8String], NULL, NULL, &error);
    if(ret != SQLITE_OK)
    {
        [self alert:[NSString stringWithFormat:@"数据表创建失败%s",error]];
    }
    
    //使用select语句加载数据，并要求数据库按行号准备排序，以便我们以相同的顺序获取，否则将使用sqlite3内部存储顺序
    NSString *preSql = @"SELECT id,datatext FROM 'wenbenkuang'ORDER BY id";
    sqlite3_stmt *statmt;
    if(sqlite3_prepare_v2(sqlite,[preSql UTF8String], -1, &statmt, nil) == SQLITE_OK)
    {
        while (sqlite3_step(statmt) == SQLITE_ROW)
        {
            int row = sqlite3_column_int(statmt, 0);                //获取行号
            char *rowData = (char *)sqlite3_column_text(statmt, 1); //获取该行数据
            NSString *dataString = [[NSString alloc]initWithUTF8String:rowData];
            UITextField *textfield = self.lineFields[row];
            textfield.text = dataString;
        }
        //完成陈述
        sqlite3_finalize(statmt);
    }
    //关闭数据库
    sqlite3_close(sqlite);
    
    //注册一个观测者，进入后台时发送通知;
    UIApplication *app = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:app];
}
-(void)applicationWillResignActiveNotification:(NSNotification *)notification
{
    int result = sqlite3_open([[self datafilePath] UTF8String], &sqlite);
    if (result != SQLITE_OK) {
        [self alert:@"数据库打开失败"];
        sqlite3_close(sqlite);
    }
    for(int i=0;i<4;i++)
    {
        UITextField *tetxField  = self.lineFields[i];
        char *updataSql = "INSERT OR REPLACE INTO 'wenbenkuang'(id,datatext) VALUES(?,?);";
        sqlite3_stmt *stmt;
        if(sqlite3_prepare_v2(sqlite, updataSql, -1, &stmt, nil) == SQLITE_OK)
        {
            sqlite3_bind_int(stmt, 1, i);
            sqlite3_bind_text(stmt, 2, [tetxField.text UTF8String], -1, NULL);
        }
        if(sqlite3_step(stmt) != SQLITE_DONE)
        {
            [self alert:@"数据更新失败"];
        }
        sqlite3_finalize(stmt);
    }
    sqlite3_close(sqlite);
}

@end