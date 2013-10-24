//
//  DD2Words.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/6/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2Words.h"
#import "DD2AppDelegate.h"

#define COLLECTION_NAMES @"collectionNames"
#define TAG_NAMES @"tagNames"
#define ALL @"allWords"

@interface DD2Words ()

@end

@implementation DD2Words

static DD2Words *sharedWords = nil;     //The shared instance of this class not a true Singleton as not enforced to avoice hiding bugs! http://boredzo.org/blog/archives/2009-06-17/doing-it-wrong

@synthesize rawWords = _rawWords;
@synthesize processedWords = _processedWords;
@synthesize allWords = _allWords;
@synthesize collectionNames = _collectionNames;
@synthesize tagNames = _tagNames;
@synthesize spellingVariant = _spellingVariant;
@synthesize recentlyViewedWords = _recentlyViewedWords;


+ (DD2Words *)sharedWords
{
    if (sharedWords == nil) sharedWords = [[DD2Words alloc] init];
    return sharedWords;
}

- recentlyViewedWords {
    if (_recentlyViewedWords == nil) _recentlyViewedWords = [[NSArray alloc] init];
    return _recentlyViewedWords;
}


- (NSDictionary *)rawWords
{
    if (_rawWords ==nil) {
        NSURL *fileURL = [NSURL URLWithString:[NSString stringWithFormat:@"wordlist.json"] relativeToURL:[DD2GlobalHelper wordlistJSONFileDirectory]];
        NSLog (@"fileURL = %@", fileURL);
        NSError *error;
        if (![[[NSFileManager alloc] init] fileExistsAtPath:[fileURL path]]) {
            NSLog(@"No file found: %@", fileURL);
            _rawWords = nil;
        } else {
            NSData *fileData = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingUncached error:&error];
            
            NSError *error2;
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:fileData options:kNilOptions error:&error2];
            if (error2) {
                NSLog(@"error = %@", error2);
            }
            //if (PROCESS_VERBOSELY) NSLog(@"contents from file json = %@",json);
            
            NSLog(@"word count = %lu",(unsigned long)[[json objectForKey:@"words"] count]);
            
            id firstWord = [[json objectForKey:@"words"] objectAtIndex:0];
            if (PROCESS_VERBOSELY) NSLog(@"first word = %@",firstWord);
            if (PROCESS_VERBOSELY) NSLog(@"first word spelling = %@",[[[json objectForKey:@"words"] objectAtIndex:0] objectForKey:@"word"] );
            
            _rawWords = json;
        }
    }
    return _rawWords;
}

-(NSArray *)allWords
{
    if (_allWords == nil) {
        _allWords = [self.processedWords objectForKey:ALL];
        if (PROCESS_VERBOSELY) NSLog(@"%@ has = %d words", ALL ,[_allWords count]);
    }
    return _allWords;
}

-(NSArray *)collectionNames
{
    if(_collectionNames == nil) {
        _collectionNames = [self.processedWords objectForKey:COLLECTION_NAMES];
        if (PROCESS_VERBOSELY) NSLog(@"%@ has = %@",COLLECTION_NAMES, _collectionNames);
    }
    return _collectionNames;
}

-(NSArray *)tagNames
{
    if(_tagNames == nil) {
        _tagNames = [self.processedWords objectForKey:TAG_NAMES];
        if (PROCESS_VERBOSELY) NSLog(@"%@ has = %@", TAG_NAMES, _tagNames);
    }
    return _tagNames;
}

-(NSDictionary *)processedWords
{
    if (_processedWords ==nil) {
        NSMutableDictionary *workingProcessedWords = [[NSMutableDictionary alloc] init];
        
        NSMutableArray *workingCollectionNames = [[NSMutableArray alloc] init];
        NSMutableArray *workingTagNames = [[NSMutableArray alloc] init];
        NSMutableArray *workingAllWords = [[NSMutableArray alloc] init];
        
        NSSet *locales = [NSSet setWithObjects:[NSString stringWithFormat:@"uk"], [NSString stringWithFormat:@"us"], nil];
    
        for (NSDictionary *rawWord in [self.rawWords objectForKey:@"words"]) {
            if (PROCESS_VERBOSELY) NSLog(@"** start processing word **");
            
            //processing for each locale
            for (NSString *locale in locales) {

                NSMutableDictionary *processedWord = [[NSMutableDictionary alloc] initWithDictionary:rawWord];
                [processedWord setObject:locale forKey:@"wordVariant"];
                
                id wordElement = [rawWord objectForKey:@"word"];
                NSString *spelling;
                if ([wordElement isKindOfClass:[NSString class]]) {
                    spelling = wordElement;
                } else if ([wordElement isKindOfClass:[NSDictionary class]]){
                    spelling = [wordElement objectForKey:locale];
                } else {
                    NSLog(@"Badly formed wordElement: %@", wordElement);
                }
                if (PROCESS_VERBOSELY) NSLog(@"%@ (%@)", spelling, locale);
                if (!spelling) continue;       // some words only have a uk variant eg cheque
                
                NSString *cleanSpelling = [DD2Words exchangeUnderscoresForSpacesin:spelling];
                [processedWord setObject:cleanSpelling forKey:@"spelling"];  //need for easy sorting
                
                //adding section for easy table creation
                NSString *section = [[cleanSpelling substringToIndex:1] uppercaseString];
                [processedWord setObject:section forKey:@"section"];
                
                //processing for homophones
                id homophonesElement = [rawWord objectForKey:@"homophones"];
                if (homophonesElement) {        //only process if word has homophones
                    id locHomophones;
                    if ([homophonesElement isKindOfClass:[NSArray class]]) {
                        locHomophones = homophonesElement;
                        
                    } else if ([homophonesElement isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *homophonesElementDictionary = (NSDictionary *)homophonesElement;
                        
                        if ([[rawWord objectForKey:@"pronunciations"] count] >1) {
                            if (PROCESS_VERBOSELY) NSLog(@"%@ is a heteronym with homophones", spelling);
                            locHomophones = homophonesElementDictionary;
                        } else {
                            locHomophones = [homophonesElementDictionary objectForKey:locale];
                        }
                    } else {
                        NSLog(@"Badly formed homophoneElement or no homophones");
                    }
                    if (locHomophones) {
                        [processedWord setObject:locHomophones forKey:@"locHomophones"];
                        if (PROCESS_VERBOSELY) NSLog(@"locHomophones (%@) = %@", locale, locHomophones);
                    } else {
                        if (PROCESS_VERBOSELY) NSLog(@"no locHomophones for %@ %@", spelling, locale);
                    }
                }
                
                //processing for all words
                [workingAllWords addObject:processedWord];
                
                //processing collections on each word
                NSMutableArray *collections = [NSMutableArray arrayWithArray:[rawWord objectForKey:@"collections"]];
                for (NSString *collection in collections) {
                    if (![workingCollectionNames containsObject:collection]) [workingCollectionNames addObject:collection];
                }
                
                //processing Tags on each word (ignoring locale as no tagged words have a spelling variations will endup with all UK words)
                NSArray *tags = [rawWord objectForKey:@"tags"];
                for (NSString *tag in tags) {
                    if (![workingTagNames containsObject:tag]) [workingTagNames addObject:tag];
                }
                
                //check that pronunciation file exists if in that mode
                if (FIND_MISSING_PRONUNCIATIONS) [DD2Words pronunciationsForWord:processedWord];
            }
        }
        
        [workingProcessedWords setObject:workingCollectionNames forKey:COLLECTION_NAMES];
        [workingProcessedWords setObject:workingTagNames forKey:TAG_NAMES];
        [workingProcessedWords setObject:workingAllWords forKey:ALL];
        
        //check for duplicate words
        if (FIND_DUPLICATE_WORDS) [self logAnyDuplicateWordsIn:workingAllWords];
        
        _processedWords = [workingProcessedWords copy];
    }
    
    return _processedWords;
}

- (void) logAnyDuplicateWordsIn:(NSArray *)wordList{
    NSCountedSet *countedSet = [NSCountedSet setWithArray:wordList];
    for (NSDictionary *word in wordList) {
        if([countedSet countForObject:word] > 1) NSLog(@"duplicate %@", word);
    }
}

- (NSArray *)allWordsForCurrentSpellingVariant {
    NSPredicate *selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.wordVariant LIKE[c] %@",[self.spellingVariant lowercaseString]];
    if (LOG_PREDICATE_RESULTS) NSLog(@"predicate = %@", selectionPredicate);
    if (LOG_PREDICATE_RESULTS) [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:self.allWords];
    NSArray *matches = [NSArray arrayWithArray:[self.allWords filteredArrayUsingPredicate:selectionPredicate]];
    return matches;
}

- (NSArray *)wordsForCurrentSpellingVariantInCollectionNamed:(NSString *)collectionName {
    NSArray *wordListForCurrentSV = [self allWordsForCurrentSpellingVariant];
    
    NSPredicate *selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.collections contains[c] %@", collectionName];
    if (LOG_PREDICATE_RESULTS) NSLog(@"predicate = %@", selectionPredicate);
    if (LOG_PREDICATE_RESULTS) [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:wordListForCurrentSV];
    NSArray *matches = [NSArray arrayWithArray:[wordListForCurrentSV filteredArrayUsingPredicate:selectionPredicate]];
    return matches;
}

+ (NSDictionary *)wordsBySectionFromWordList:(NSArray *)wordList
{
    NSArray *possibleSectionNames = [DD2GlobalHelper alphabet];
    NSMutableDictionary *wordsBySections = [[NSMutableDictionary alloc] init];
    NSLog(@"# words in = %lu", (unsigned long)[wordList count]);
    
    for (NSString *sectionName in possibleSectionNames) {
        NSPredicate *selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.section LIKE[c] %@",[sectionName uppercaseString]];
        if (LOG_PREDICATE_RESULTS) NSLog(@"predicate = %@", selectionPredicate);
        if (LOG_PREDICATE_RESULTS) [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:wordList];
        NSArray *matches = [NSArray arrayWithArray:[wordList filteredArrayUsingPredicate:selectionPredicate]];
        
        if ([matches count] > 0) {
            [wordsBySections setObject:matches forKey:[sectionName uppercaseString]];
        }
    }
    return [wordsBySections copy];
}

+ (void) compareSectionsDictionaryFirstAnswer:(NSDictionary *)firstAnswer withSecondAnswer:(NSDictionary *)secondAnswer {
    
    for (int n = 0; n<[firstAnswer count]; n++) {
        NSArray *sortedSectionForFirstAnswer = [[firstAnswer allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        NSString *firstAnswerSection = [sortedSectionForFirstAnswer objectAtIndex:n];
        NSArray *sortedSectionForsecondAnswer = [[secondAnswer allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        NSString *secondAnswerSection;
        if (n < [secondAnswer count]) {
            secondAnswerSection = [sortedSectionForsecondAnswer objectAtIndex:n];
        }
        NSLog(@"%@,%lu : %@,%lu",firstAnswerSection, (unsigned long)[[firstAnswer objectForKey:firstAnswerSection] count], secondAnswerSection, (unsigned long)[[secondAnswer objectForKey:secondAnswerSection] count]);
    }
}

+ (NSString *)exchangeSpacesForUnderscoresin:(NSString *)string {
    NSString *cleanString = [string stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    return cleanString;
}

+ (NSString *)exchangeUnderscoresForSpacesin:(NSString *)string {
    NSString *cleanString = [string stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    return cleanString;
}

+ (NSString *) displayNameForCollection:(NSString *)collectionName {
    
    NSString *cleanString =[DD2Words exchangeUnderscoresForSpacesin:collectionName];
    NSString *cleanerString = [NSString stringWithString:[cleanString capitalizedString]];
    return cleanerString;
}

+ (NSString *) pronunciationFromSpelling:(NSString *)spelling
{
    //turn spaces into _
    NSString *cleanString = [spelling stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    
    // remove 'apostrophe', 'dash' and 'period' characters
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"'.-"];
    NSString *cleanerString = [[cleanString componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    
    return [NSString stringWithString:cleanerString];
}

+ (NSSet *) pronunciationsForWord:(NSDictionary *)word
{
    NSMutableSet *pronunciations = [NSMutableSet setWithArray:[word objectForKey:@"pronunciations"]];
    NSString *pronunciationFromSpelling = [DD2Words pronunciationFromSpelling:[word objectForKey:@"spelling"]];
    
    if ([pronunciations count] < 1) {   //does pronunciation from Spelling have a fileName
        NSString *possiblePronunciation = pronunciationFromSpelling;
        if ([DD2GlobalHelper fileURLForPronunciation:possiblePronunciation]) {
            [pronunciations addObject:possiblePronunciation];
        }
    }
    
    if ([pronunciations count] < 1) {   //do any of its homophones have pronunciation files
        NSArray *locHomophones = [word objectForKey:@"locHomophones"];
        for (NSString *homophone in locHomophones) {
            if ([DD2GlobalHelper fileURLForPronunciation:homophone]) {
                [pronunciations addObject:homophone];
            }
        }
    }
    
    if ([pronunciations count] < 1) {   //do its local variant pronunciation files exsist
        NSString *basePronunciation = [DD2Words pronunciationFromSpelling:[word objectForKey:@"spelling"]];
        NSString *possiblePronunciation = [NSString stringWithFormat:@"%@-%@", [word objectForKey:@"wordVariant"], basePronunciation];
       if ([DD2GlobalHelper fileURLForPronunciation:possiblePronunciation]) {
           [pronunciations addObject:possiblePronunciation];
       }
    }
    
    if ([pronunciations count] <1) {    //does it have local variant alt spellings with files
        if ([[word objectForKey:@"word"] isKindOfClass:[NSDictionary class]] ) {
            NSSet *locales = [NSSet setWithObjects:[NSString stringWithFormat:@"uk"], [NSString stringWithFormat:@"us"], nil];
            for (NSString *locale in locales) {
                NSString *wordVariant = [word objectForKey:@"wordVariant"];
                if (![locale isEqualToString:wordVariant]) {
                    NSString *alternativeSpelling = [[word objectForKey:@"word"] objectForKey:locale];
                    if ([DD2GlobalHelper fileURLForPronunciation:alternativeSpelling]) {
                        [pronunciations addObject:alternativeSpelling];
                    }
                }
            }
        }
    }
    
    if ([pronunciations count] < 1) {   //all has failed set pronunciation to the root spelling and warn that its missing
        [pronunciations addObject:pronunciationFromSpelling];
        NSLog(@"***** file needed: %@ *****", [word objectForKey:@"spelling"]);
    }
    
    NSString *pronunciationsStringForLog;
    for (NSString *pronunciation in pronunciations) {
        if (pronunciationsStringForLog) {
            pronunciationsStringForLog = [NSString stringWithFormat:@"%@, %@",pronunciationsStringForLog, pronunciation];
        } else {
            pronunciationsStringForLog = [NSString stringWithFormat:@"%@", pronunciation];
        }
    }
    // don't log this if looking for missing pronunciations
    if (!FIND_MISSING_PRONUNCIATIONS) NSLog(@"Pronunciations for %@ = %@", [word objectForKey:@"spelling"], pronunciationsStringForLog);
    return [pronunciations copy];
}

+ (NSDictionary *) homophonesForWord:(NSDictionary *)word andWordList:(NSArray *)wordList { //returns a dictionary of word dictionaries (for each homophone).
    
    NSMutableDictionary *workingResults = [[NSMutableDictionary alloc] init];
    NSSet *pronunciationsForWord = [DD2Words pronunciationsForWord:word];
    if ([pronunciationsForWord count] > 1) {
        for (NSString * pronunciation in pronunciationsForWord) {
            NSArray *homophoneListForPronunciation = [[word objectForKey:@"locHomophones"] objectForKey:pronunciation];
            [workingResults setObject:[DD2Words wordsForPronunciationList:homophoneListForPronunciation andWordList:wordList] forKey:pronunciation];
        }
    } else {
        NSArray *homophones = [word objectForKey:@"locHomophones"];
        if (homophones) {
            [workingResults setObject:[DD2Words wordsForPronunciationList:homophones andWordList:wordList] forKey:[pronunciationsForWord anyObject]];
        } else {
            NSLog(@"No homophones on %@", [word objectForKey:@"spelling"]);
        }
    }
    return [workingResults copy];
}

+ (NSMutableArray *) wordsForPronunciationList:(NSArray *)list andWordList:(NSArray *)wordList {
    NSMutableArray *workingHomophoneList = [NSMutableArray array];
    for (NSString *pronunciation in list) {
        if ([DD2Words wordForPronunciation:pronunciation fromWordList:wordList]) {
            [workingHomophoneList addObject:[DD2Words wordForPronunciation:pronunciation fromWordList:wordList]];   //protect against homophones that don't have a pronununciation eg in pour
        }
    }
    return [workingHomophoneList copy];
}

+ (NSDictionary *) wordForPronunciation:(NSString *)pronunciation fromWordList:(NSArray *)wordList {
    
    // get word if pronunciation is listed directly in pronunciation field
    NSPredicate *selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.pronunciations contains[c] %@",pronunciation];
    if (LOG_PREDICATE_RESULTS) NSLog(@"predicate = %@", selectionPredicate);
    if (LOG_PREDICATE_RESULTS) [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:wordList];
    NSMutableArray *matches = [NSMutableArray arrayWithArray:[wordList filteredArrayUsingPredicate:selectionPredicate]];
    
    if ([matches count] == 1) {
        return [matches lastObject];
    } else {
        // check if pronunciation is a localized version of a spelling and clean out the local part if so.
        if (([pronunciation rangeOfString:@"uk-"].location != NSNotFound) || ([pronunciation rangeOfString:@"us-"].location != NSNotFound)) {
            pronunciation = [pronunciation substringFromIndex:3];
        }
        // get the word that matches if the pronunciation is the spelling
        selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.spelling LIKE[c] %@",pronunciation];
        if (LOG_PREDICATE_RESULTS) NSLog(@"predicate = %@", selectionPredicate);
        if (LOG_PREDICATE_RESULTS) [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:wordList];
        matches = [NSMutableArray arrayWithArray:[wordList filteredArrayUsingPredicate:selectionPredicate]];
    
        if ([matches count] != 1) NSLog(@"more of less than one matches ** PROBLEM **");
        return [matches lastObject];
    }
}


+ (void)logDD2WordProperty:(NSString *)property
{
    if ([property isEqualToString:COLLECTION_NAMES]) NSLog(@"DD2Word.%@ = %@", COLLECTION_NAMES, [DD2Words sharedWords].collectionNames);
    if ([property isEqualToString:TAG_NAMES]) NSLog(@"DD2Word.%@ = %@", TAG_NAMES, [DD2Words sharedWords].tagNames);
    if ([property isEqualToString:ALL]) NSLog(@"DD2Word.%@ = %@", ALL, [DD2Words sharedWords].allWords);
    NSLog(@"-------- above or property missing ---------");
}


#pragma mark - Recently Viewed Words methods

+ (void) viewingWordNow:(NSDictionary *)word{
    if (!word) return;      // resetting display word view to empty
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *recentWords = [[defaults objectForKey:RECENTLY_VIEWED_WORDS_KEY] mutableCopy];
    if (!recentWords) recentWords = [NSMutableArray array];
    //NSLog(@"word passed in: %@", word);
    
    if ([recentWords containsObject:word]) {
        NSLog(@"already a recent word");
        [recentWords removeObject:word];
    }
    [recentWords insertObject:word atIndex:0];
    if ([recentWords count] > 50) [recentWords removeLastObject];
    
    [defaults setObject:recentWords forKey:RECENTLY_VIEWED_WORDS_KEY];
    [defaults synchronize];
    NSLog(@"recent word count: %d", [recentWords count]);
    
}


+ (NSArray *) currentRecentlyViewedWordList {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *recentlyViewedWords = [defaults objectForKey:RECENTLY_VIEWED_WORDS_KEY];
    return recentlyViewedWords;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"collection: %@, tags: %@ word count: %lu recents: %@", self.collectionNames, self.tagNames, (unsigned long)[self.allWords count], self.recentlyViewedWords];
}

@end
