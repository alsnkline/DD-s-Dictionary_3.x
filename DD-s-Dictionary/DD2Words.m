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
            
            //processing for each locale
            for (NSString *locale in locales) {
                NSLog(@"locale is %@", locale);
                NSMutableDictionary *processedWord = [[NSMutableDictionary alloc] initWithDictionary:rawWord];
                
                id wordElement = [rawWord objectForKey:@"word"];
                NSString *spelling;
                if ([wordElement isKindOfClass:[NSString class]]) {
                    spelling = wordElement;
                } else if ([wordElement isKindOfClass:[NSDictionary class]]){
                    spelling = [wordElement objectForKey:locale];
                    NSLog(@"spelling for %@ = %@", locale, spelling);
                } else {
                    NSLog(@"Badly formed wordElement");
                }
                [processedWord setObject:spelling forKey:@"spelling"];  //need for easy sorting
                
                //processing for homophones
                id homophonesElement = [rawWord objectForKey:@"homophones"];
                id locHomophones;
                if (homophonesElement) {        //only process if word has homophones
                    if ([homophonesElement isKindOfClass:[NSArray class]]) {
                        locHomophones = homophonesElement;
                        
                    } else if ([homophonesElement isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *homophonesElementDictionary = (NSDictionary *)homophonesElement;
                        
                        if ([[rawWord objectForKey:@"pronunciations"] count] >1) {
                            NSLog(@"word is a heteronym with homophones");
                            locHomophones = homophonesElementDictionary;
                        } else {
                            NSLog(@"word has localised homophones element = %@", homophonesElement);
                            locHomophones = [homophonesElementDictionary objectForKey:locale];
                        }
                    } else {
                        NSLog(@"Badly formed homophoneElement or no homophones");
                    }
                    if (locHomophones) {
                        [processedWord setObject:locHomophones forKey:@"locHomophones"];
                        NSLog(@"locHomophones for %@ %@ = %@", spelling, locale, locHomophones);
                    } else {
                        NSLog(@"no locHomophones for %@ %@", spelling, locale);
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
                    if (PROCESS_VERBOSELY) NSLog(@"spelling: %@ in section: %@", spelling, section);
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

+ (NSDictionary *)singleCollectionNamed:(NSString *)collectionName spellingVariant:(NSString *)variant
{
    NSString *collectionKey = [NSString stringWithFormat:@"%@-%@",[variant lowercaseString], collectionName ];
    DD2AppDelegate *appDelegate = (DD2AppDelegate *)[[UIApplication sharedApplication] delegate];
    return [appDelegate.words.collectionsOfWords objectForKey:collectionKey];
}

+ (NSArray *)allWordsWithSpellingVariant:(NSString *)variant
{
    DD2AppDelegate *appDelegate = (DD2AppDelegate *)[[UIApplication sharedApplication] delegate];
    return [appDelegate.words.allWords objectForKey:[variant lowercaseString]];
}

+ (NSArray *)tagNames
{
    DD2AppDelegate *appDelegate = (DD2AppDelegate *)[[UIApplication sharedApplication] delegate];
    return appDelegate.words.tagNames;
}


+ (NSString *) pronunciationFromSpelling:(NSString *)spelling
{
    //turn spaces into _
    NSString *cleanString = [spelling stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    
    // remove apostrophe and periods sign characters
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"'."];
    NSString *cleanerString = [[cleanString componentsSeparatedByCharactersInSet:charSet] componentsJoinedByString:@""];
    
    NSLog(@"clean string = %@",cleanerString);
    return [NSString stringWithString:cleanerString];
}

+ (NSSet *) pronunciationsForWord:(NSDictionary *)word     //no words pronunciations depend upon spelling variant yet
{
    NSSet *pronunciations = [word objectForKey:@"pronunciations"];
    if (!pronunciations) {
        pronunciations = [NSSet setWithObject:[DD2Words pronunciationFromSpelling:[word objectForKey:@"spelling"]]];
    }
    
    //TO DO need to check for file precense and if missing cicle through the words homophones until a file for the pronunciation is found
    
    return pronunciations;
}

+ (NSArray *) homophonesForPronunciation:(NSString *)pronunciation FromWord:(NSDictionary *)word
{
    NSArray *homophones;
    if ([[word objectForKey:@"pronunciations"] count] > 1) {
        homophones = [[word objectForKey:@"locHomophones"] objectForKey:pronunciation];
    } else {
        homophones = [word objectForKey:@"locHomophones"];
    }
    NSLog(@"homophones for pronunciation (%@) = %@",pronunciation, homophones);
    return homophones;
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
