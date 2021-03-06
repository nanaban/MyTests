//
//  BTSotryEncryAndDec.m
//  BabyTing
//
//  Created by Neo on 11-12-26.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BTStoryEncryAndDec.h"

@interface BTStoryEncryAndDec(Private)

+ (BOOL)isNewDesAlgorithm:(NSData *)data;
+ (int)algorithmChoose:(NSData *)data;
+ (NSData *)removeHeaderInfo:(NSData *)data;
+ (NSData *)algorithmZero:(NSData *)data;
+ (NSData *)algorithmTwo:(NSData *)data;
+ (NSData *)algorithmThree:(NSData *)data;
@end
@implementation BTStoryEncryAndDec

+(void)encryptionWithSourcePath:(NSString *)SourcePath targetPath:(NSString *)targetPath
{
	NSData *sourceData= [NSData dataWithContentsOfFile:SourcePath];
	Byte *sourceDataByte = (Byte *)[sourceData bytes];
	for(int i=0;i<[sourceData length];i++)
	{
		sourceDataByte[i] = 255 - sourceDataByte[i];
	}
	NSData *targetData = [NSData dataWithBytes:sourceDataByte length:[sourceData length]];
	[targetData writeToFile:targetPath atomically:YES];
	
}

+(void)decryptWithSourcePath:(NSString *)SourcePath targetPath:(NSString *)targetPath
{
	NSData *sourceData= [NSData dataWithContentsOfFile:SourcePath];
	Byte *sourceDataByte = (Byte *)[sourceData bytes];
	for(int i=0;i<[sourceData length];i++)
	{
		sourceDataByte[i] = 255 - sourceDataByte[i];
	}
	NSData *targetData = [NSData dataWithBytes:sourceDataByte length:[sourceData length]];
	[targetData writeToFile:targetPath atomically:YES];
}

//加密数据
+(NSData *)encryptData:(NSData *)originalData {
	Byte *sourceDataByte = (Byte *)[originalData bytes];
	for(int i=0;i<[originalData length];i++)
	{
		sourceDataByte[i] = 255 - sourceDataByte[i];
	}
	return [NSData dataWithBytes:sourceDataByte length:[originalData length]];
    
}

//解密数据
+(NSData *)decryptData:(NSData *)encryptedData type:(NSDictionary *)algorithmFac{
	return encryptedData;
	
    NSNumber *algorithmNum = [algorithmFac objectForKey:@"algorithm"];
    NSNumber *aNum = [algorithmFac objectForKey:@"a"];
    NSNumber *bNum = [algorithmFac objectForKey:@"b"];
    NSNumber *cNum = [algorithmFac objectForKey:@"c"];
    NSNumber *dataLenNum = [algorithmFac objectForKey:@"length"];
    int a = [aNum intValue];
    int b = [bNum intValue];
    int c = [cNum intValue];
    int algorithmType = [algorithmNum intValue];
    int dataLen = [dataLenNum intValue];
    

    NSData *tmpData;
    if([BTStoryEncryAndDec isNewDesAlgorithm:encryptedData]){
        int tmpLength = [encryptedData length];
        NSRange ra = NSMakeRange(20, tmpLength-20);
        tmpData = [encryptedData subdataWithRange:ra];

    }else{
        tmpData = [NSData dataWithData:encryptedData];
        dataLen -= 20;
    }
    Byte *tmpDataByte = (Byte *)[tmpData bytes];
    int length = [tmpData length];
    Byte *resultDataByte= malloc(length);

    if(algorithmType == 0){

        for(int i=0;i<length;i++)
        {
            resultDataByte[i] = 255 - tmpDataByte[i];
        }
    }else if(algorithmType ==2 ){
        for(int i=0;i<length;i++){
            switch ((i+dataLen)%3) {
                case 0:
                    resultDataByte[i] = tmpDataByte[i] - b - a%c;
                    break;
                case 1:
                    resultDataByte[i] = b+a%c+255 - tmpDataByte[i];
                    break;
                case 2:
                    resultDataByte[i] = 255-tmpDataByte[i]-b- a%c;
                    break;
                default:
                    break;
            }

        }
        
    }else if(algorithmType ==  3){
        for(int i=0;i<length;i++){
            switch ((i+dataLen)%3) {
                case 0:
                    resultDataByte[i] = tmpDataByte[i] ^a^(a-b);
                    break;
                case 1:
                    resultDataByte[i] = tmpDataByte[i] ^b^(b-c);
                    break;
                case 2:
                    resultDataByte[i] = tmpDataByte[i] ^c^(c-a);
                    break;
                    
                default:
                    break;
            }

           
        }
        
    }
    NSData *resultData = [NSData dataWithBytes:resultDataByte length:length];
    free(resultDataByte);

	return resultData;
}

//将原始数据加密后写入目标文件
+(void)writeDataToFile:(NSData*)originalData path:(NSString *)targetPath {
    [[BTStoryEncryAndDec encryptData:originalData] writeToFile:targetPath atomically:YES];
}

//从文件读取加密数据并解密
+(NSData *)readDateFromFile:(NSString *)targetPath {
    NSData *data = [NSData dataWithContentsOfFile:targetPath];
    return [BTStoryEncryAndDec decryptData:data];
}

//是否是新的加密算法
+ (BOOL)isNewDesAlgorithm:(NSData *)data{
    
    if (!data || [data length] == 0) {
        return NO;
    }
    
    Byte desTag[16] = {157,22,50,175,80,191,115,27,174,84,189,102,25,153,36,216};
    BOOL isNew = YES;
    Byte *dataByte = (Byte *)[data bytes];
    for(int i = 0;i<16; i++){
        if(dataByte[i]!=desTag[i]){
            isNew = NO;
        }
    }
    return isNew;
}

//通过加密文件判断文件加密算法类型
+ (int)algorithmChoose:(NSData *)data{
    Byte *dataByte = (Byte *)[data bytes];
    int algorithmType = 0;
    if([self isNewDesAlgorithm:data]){
        algorithmType = dataByte[16];
    }
    return algorithmType;
}

+ (NSData *)removeHeaderInfo:(NSData *)data{
    NSData *newData;
    NSRange ra = NSMakeRange(20, [data length]-20);
    newData = [NSData dataWithData:[data subdataWithRange:ra]];
    return  newData;
}

@end
