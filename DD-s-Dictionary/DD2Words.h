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
@property (nonatomic, strong) NSArray *allProcessedWords;
@property (nonatomic, strong) NSArray *collectionNames;
@property (nonatomic, strong) NSArray *tagNames;
@property (nonatomic, strong) NSString *spellingVariant;


+ (DD2Words *)sharedWords;
- (NSArray *)allWordsForCurrentSpellingVariant;
- (NSArray *)wordsForCurrentSpellingVariantInCollectionNamed:(NSString *)collectionName;

+ (void)logDD2WordProperty:(NSString *)property;

+ (NSDictionary *)wordsBySectionFromWordList:(NSArray *)wordList;
+ (void) compareSectionsDictionaryFirstAnswer:(NSDictionary *)firstAnswer withSecondAnswer:(NSDictionary *)secondAnswer;

+ (NSString *)exchangeSpacesForUnderscoresin:(NSString *)string;
+ (NSString *) exchangeUnderscoresForSpacesin:(NSString *)string;
+ (NSString *) displayNameForCollection:(NSString *)collectionName;
+ (NSString *) pronunciationFromSpelling:(NSString *)spelling;
+ (NSSet *) pronunciationsForWord:(NSDictionary *)word;

+ (NSDictionary *) wordForPronunciation:(NSString *)pronunciation fromWordList:(NSArray *)wordList;
+ (NSDictionary *) homophonesForWord:(NSDictionary *)word andWordList:(NSArray *)wordList;

@end
