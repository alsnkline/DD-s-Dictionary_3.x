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
@property (nonatomic, strong) NSArray *allWords;
@property (nonatomic, strong) NSArray *collectionNames;
@property (nonatomic, strong) NSArray *smallCollectionNames;
@property (nonatomic, strong) NSArray *tagNames;
@property (nonatomic, strong) NSString *spellingVariant;
@property (nonatomic, strong) NSArray *recentlyViewedWords; //repository for recents


+ (DD2Words *)sharedWords;
- (NSArray *)allWordsForCurrentSpellingVariant;
- (NSArray *)wordsForCurrentSpellingVariantInCollectionNamed:(NSString *)collectionName;

+ (void) logDD2WordProperty:(NSString *)property;

+ (NSDictionary *) wordsBySectionFromWordList:(NSArray *)wordList;
+ (void) compareSectionsDictionaryFirstAnswer:(NSDictionary *)firstAnswer withSecondAnswer:(NSDictionary *)secondAnswer;
+ (NSDictionary *) wordWithOtherSpellingVariantFrom:(NSDictionary *)word andListOfAllWords:(NSArray *)allWords;

+ (NSString *) exchangeSpacesForUnderscoresin:(NSString *)string;
+ (NSString *) exchangeUnderscoresForSpacesin:(NSString *)string;
+ (NSString *) displayNameForCollection:(NSString *)collectionName;
+ (NSString *) pronunciationFromSpelling:(NSString *)spelling;
+ (NSSet *) pronunciationsForWord:(NSDictionary *)word;

+ (NSDictionary *) wordForPronunciation:(NSString *)pronunciation fromWordList:(NSArray *)wordList;
+ (NSDictionary *) homophonesForWord:(NSDictionary *)word andWordList:(NSArray *)wordList;

//methods for recents words
+ (void) viewingWordNow:(NSDictionary *)word;
+ (NSArray *) currentRecentlyViewedWordList;

@end
