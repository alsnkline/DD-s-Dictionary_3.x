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
@property (nonatomic, strong) NSArray *collectionNames;
@property (nonatomic, strong) NSDictionary *collectionsOfWords;
@property (nonatomic, strong) NSArray *tagNames;
@property (nonatomic, strong) NSDictionary *allWords;


+ (DD2Words *)sharedWords;
+ (void)logDD2WordProperty:(NSString *)property;

+ (NSDictionary *)singleCollectionNamed:(NSString *)collectionName spellingVariant:(NSString *)variant;
+ (NSArray *)allWordsWithSpellingVariant:(NSString *)variant;
+ (NSArray *)tagNames;

+ (NSString *) pronunciationFromSpelling:(NSString *)spelling;
+ (NSSet *) pronunciationsForWord:(NSDictionary *)word;

+ (NSDictionary *) wordForPronunciation:(NSString *)pronunciation fromWordList:(NSArray *)wordList;
+ (NSDictionary *) homophonesForWord:(NSDictionary *)word andWordList:(NSArray *)wordList;


+ (NSArray *) homophonesForPronunciation:(NSString *)pronunciation FromWord:(NSDictionary *)word;

- (NSInteger)numberOfWordsInCollection:(NSString *)collection spellingVariant:(NSString *)variant;

@end
