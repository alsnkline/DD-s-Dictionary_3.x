//
//  DD2Words.h
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/6/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DD2Words : NSObject

@property (nonatomic, strong) NSDictionary *rawWords;
@property (nonatomic, strong) NSDictionary *processedWords;
@property (nonatomic, strong) NSDictionary *collectionsOfWords;
@property (nonatomic, strong) NSDictionary *taggedGroupsOfWords;
@property (nonatomic, strong) NSDictionary *allWords;
@property (nonatomic, strong) NSArray *collectionNames;
@property (nonatomic, strong) NSDictionary *homophones;

+ (DD2Words *)sharedWords;
+ (void)logDD2WordProperty:(NSString *)property;

+ (NSDictionary *)singleCollectionNamed:(NSString *)collectionName spellingVariant:(NSString *)variant;
+ (NSArray *)allWordsWithSpellingVariant:(NSString *)variant;
+ (NSDictionary *)taggedGroupsOfWords;

- (NSInteger)numberOfWordsInCollection:(NSString *)collection spellingVariant:(NSString *)variant;

@end
