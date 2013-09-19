//
//  DD2Words.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/6/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2Words.h"
#import "DD2AppDelegate.h"

#define COLLECTIONS @"collectionsOfWords"
#define COLLECTION_NAMES @"collectionNames"
#define TAG_NAMES @"tagNames"
#define ALL @"allWords"

@interface DD2Words ()

@end

@implementation DD2Words

static DD2Words *sharedWords = nil;     //The shared instance of this class not a true Singleton as not enforced to avoice hiding bugs! http://boredzo.org/blog/archives/2009-06-17/doing-it-wrong

@synthesize rawWords = _rawWords;
@synthesize processedWords = _processedWords;
@synthesize collectionNames = _collectionNames;
@synthesize collectionsOfWords = _collectionsOfWords;
@synthesize tagNames = _tagNames;
@synthesize allWords = _allWords;


+ (DD2Words *)sharedWords
{
    if (sharedWords == nil) sharedWords = [[DD2Words alloc] init];
    return sharedWords;
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

-(NSDictionary *)allWords
{
    if (_allWords == nil) {
        _allWords = [self.processedWords objectForKey:ALL];
        if (PROCESS_VERBOSELY) NSLog(@"%@ has = %@", ALL ,[_allWords allKeys]);
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

-(NSDictionary *)collectionsOfWords
{
    if (_collectionsOfWords == nil) {
        _collectionsOfWords = [self.processedWords objectForKey:COLLECTIONS];
        if (PROCESS_VERBOSELY) NSLog(@"%@ has = %@",COLLECTIONS ,[_collectionsOfWords allKeys]);
    }
    return _collectionsOfWords;
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
        NSMutableDictionary *workingCollectionsOfWords = [[NSMutableDictionary alloc] init];
        NSMutableArray *workingTagNames = [[NSMutableArray alloc] init];
        NSMutableDictionary *workingAllWords = [[NSMutableDictionary alloc] init];
        
        NSSet *locales = [NSSet setWithObjects:[NSString stringWithFormat:@"uk"], [NSString stringWithFormat:@"us"], nil];
    
        for (NSDictionary *rawWord in [self.rawWords objectForKey:@"words"]) {
            if (PROCESS_VERBOSELY) NSLog(@"** start processing word **");
            
            //processing for each locale
            for (NSString *locale in locales) {

                NSMutableDictionary *processedWord = [[NSMutableDictionary alloc] initWithDictionary:rawWord];
                [processedWord setObject:locale forKey:@"spellingVariant"];
                
                id wordElement = [rawWord objectForKey:@"word"];
                NSString *spelling;
                if ([wordElement isKindOfClass:[NSString class]]) {
                    spelling = wordElement;
                } else if ([wordElement isKindOfClass:[NSDictionary class]]){
                    spelling = [wordElement objectForKey:locale];
                } else {
                    NSLog(@"Badly formed wordElement");
                }
                if (PROCESS_VERBOSELY) NSLog(@"%@ (%@)", spelling, locale);
                [processedWord setObject:spelling forKey:@"spelling"];  //need for easy sorting
                
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
                NSMutableArray *allWordLocale = [workingAllWords objectForKey:locale];
                if (!allWordLocale) {
                    allWordLocale = [[NSMutableArray alloc] init];
                    [workingAllWords setObject:allWordLocale forKey:locale];
                }
                [allWordLocale addObject:processedWord];
                
                //processing collections on each word
                NSMutableArray *collections = [NSMutableArray arrayWithArray:[rawWord objectForKey:@"collections"]];
                [collections insertObject:[NSString stringWithFormat:@"allWords"] atIndex:0];
                for (NSString *collection in collections) {
                    
                    if (![workingCollectionNames containsObject:collection]) [workingCollectionNames addObject:collection];
                    
                    NSString *localizedCollection = [NSString stringWithFormat:@"%@-%@", locale, collection];
                    if (PROCESS_VERBOSELY) NSLog(@"collection %@", localizedCollection);
                    NSMutableDictionary *workingCollection = [workingCollectionsOfWords objectForKey:localizedCollection];
                    if (!workingCollection) {
                        workingCollection = [[NSMutableDictionary alloc] init];
                        [workingCollectionsOfWords setObject:workingCollection forKey:localizedCollection];
                    }
                    
                    NSString *section = [[spelling substringToIndex:1] uppercaseString];
                    [processedWord setObject:section forKey:@"section"];    //need for easy section calculation from word
                    NSMutableArray *wordsInThisSection = [workingCollection objectForKey:section];
                    if (!wordsInThisSection) {
                        wordsInThisSection = [[NSMutableArray alloc] init];
                        [workingCollection setObject:wordsInThisSection forKey:section];
                    }
                    [wordsInThisSection addObject:[processedWord copy]];
                }
                
                //processing Tags on each word (ignoring locale as no tagged words have a spelling variations will endup with all UK words)
                NSArray *tags = [rawWord objectForKey:@"tags"];
                for (NSString *tag in tags) {
                    if (![workingTagNames containsObject:tag]) [workingTagNames addObject:tag];
                }
                //NSSet *wordsToLog = [NSSet setWithObjects:@"bin",@"bean",@"been", nil];
                //if ([wordsToLog containsObject:[processedWord objectForKey:@"spelling"]]) NSLog(@"processedWord = %@", processedWord);
            }
        }
        
        [workingProcessedWords setObject:workingAllWords forKey:ALL];
        [workingProcessedWords setObject:workingCollectionNames forKey:COLLECTION_NAMES];
        [workingProcessedWords setObject:workingCollectionsOfWords forKey:COLLECTIONS];
        [workingProcessedWords setObject:workingTagNames forKey:TAG_NAMES];

        
        _processedWords = [workingProcessedWords copy];
    }
    return _processedWords;
}

+ (NSDictionary *)fromWordBrain:(DD2Words *)brain getSingleCollectionNamed:(NSString *)collectionName withSpellingVariant:(NSString *)variant
{
    NSString *collectionKey = [NSString stringWithFormat:@"%@-%@",[variant lowercaseString], collectionName ];
    return [brain.collectionsOfWords objectForKey:collectionKey];
}

+ (NSString *) pronunciationFromSpelling:(NSString *)spelling
{
    //turn spaces into _
    NSString *cleanString = [spelling stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    
    // remove apostrophe and periods sign characters
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"'."];
    NSString *cleanerString = [[cleanString componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    
    return [NSString stringWithString:cleanerString];
}

+ (NSSet *) pronunciationsForWord:(NSDictionary *)word
{
    NSMutableSet *pronunciations = [NSMutableSet setWithArray:[word objectForKey:@"pronunciations"]];
    NSString *pronunciationFromSpelling = [DD2Words pronunciationFromSpelling:[word objectForKey:@"spelling"]];
    
    if ([pronunciations count] < 1) {   //does pronunciation from Spelling has a file
        NSString *possiblePronunciation = pronunciationFromSpelling;
        if ([DD2GlobalHelper fileURLForPronunciation:possiblePronunciation]) {
            [pronunciations addObject:possiblePronunciation];
        }
    }
    
    if ([pronunciations count] < 1) {   //does any of its homophones have pronunciation files
        NSArray *locHomophones = [word objectForKey:@"locHomophones"];
        for (NSString *homophone in locHomophones) {
            if ([DD2GlobalHelper fileURLForPronunciation:homophone]) {
                [pronunciations addObject:homophone];
            }
        }
    }
    
    if ([pronunciations count] < 1) {   //does its local varient pronunciation files exsist
        NSString *basePronunciation = [DD2Words pronunciationFromSpelling:[word objectForKey:@"spelling"]];
        NSString *possiblePronunciation = [NSString stringWithFormat:@"%@-%@", [word objectForKey:@"spellingVariant"], basePronunciation];
       if ([DD2GlobalHelper fileURLForPronunciation:possiblePronunciation]) {
           [pronunciations addObject:possiblePronunciation];
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
    NSLog(@"Pronunciations for %@ = %@", [word objectForKey:@"spelling"], pronunciationsStringForLog);
    return [pronunciations copy];
}

+ (void) SpellingForPronunciation {
    
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
        [workingHomophoneList addObject:[DD2Words wordForPronunciation:pronunciation fromWordList:wordList]];
    }
    return [workingHomophoneList copy];
}

+ (NSDictionary *) wordForPronunciation:(NSString *)pronunciation fromWordList:(NSArray *)wordList {
    
    NSPredicate *selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.pronunciations contains[c] %@",pronunciation];
    NSLog(@"predicate = %@", selectionPredicate);
    if (LOG_PREDICATE_RESULTS) [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:wordList];
    NSMutableArray *matches = [NSMutableArray arrayWithArray:[wordList filteredArrayUsingPredicate:selectionPredicate]];
    
    if ([matches count] == 1) {
        return [matches lastObject];
    } else {
        selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.spelling LIKE[c] %@",[DD2Words pronunciationFromSpelling:pronunciation]];
        NSLog(@"predicate = %@", selectionPredicate);
        if (LOG_PREDICATE_RESULTS) [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:wordList];
        NSMutableArray *matches = [NSMutableArray arrayWithArray:[wordList filteredArrayUsingPredicate:selectionPredicate]];
        if ([matches count] != 1) NSLog(@"more of less than one matches ** PROBLEM **");
        return [matches lastObject];
    }
}


+ (void)logDD2WordProperty:(NSString *)property
{
    if ([property isEqualToString:COLLECTION_NAMES]) NSLog(@"DD2Word.%@ = %@", COLLECTION_NAMES, [DD2Words sharedWords].collectionNames);
    if ([property isEqualToString:COLLECTIONS]) NSLog(@"DD2Word.%@ = %@", COLLECTIONS, [DD2Words sharedWords].collectionsOfWords);
    if ([property isEqualToString:TAG_NAMES]) NSLog(@"DD2Word.%@ = %@", TAG_NAMES, [DD2Words sharedWords].tagNames);
    if ([property isEqualToString:ALL]) NSLog(@"DD2Word.%@ = %@", ALL, [DD2Words sharedWords].allWords);
    NSLog(@"-------- above or property missing ---------");
}


- (NSInteger)numberOfWordsInCollection:(NSString *)collection spellingVariant:(NSString *)variant
{
    NSLog(@"testing # of Collections = %lu", (unsigned long)[self.collectionsOfWords count]);
    NSLog(@"testing collection names = %@", [self.collectionsOfWords allKeys]);
    
    //returning all words in workingwords for now
    NSString *collectionKey = [NSString stringWithFormat:@"%@-%@",variant,collection];
    NSInteger count = [[self.collectionsOfWords objectForKey:collectionKey] count];
   // NSInteger count =  [[self.rawWords objectForKey:@"words"] count];
    NSLog(@"workingWord list count: %d", count);
    return count;
}

@end
