//
//  DD2Words.m
//  DD-s-Dictionary
//
//  Created by Alison KLINE on 9/6/13.
//  Copyright (c) 2013 Alison KLINE. All rights reserved.
//

#import "DD2Words.h"
#import "DD2AppDelegate.h"

#define kDataFile @"Data.plist"

#define COLLECTION_NAMES @"collectionNames"
#define SMALL_COLLECTION_NAMES @"smallCollectionNames"
#define TAG_NAMES @"tagNames"
#define ALL_UK_WORDS @"allUKWords"
#define ALL_US_WORDS @"allUSWords"
#define ALL @"allWords"

@interface DD2Words ()
@property (nonatomic) BOOL wordProcessingNeeded;
@property (nonatomic, strong) NSMutableSet *unusedPronunciations;
@end

@implementation DD2Words

static DD2Words *sharedWords = nil;     //The shared instance of this class not a true Singleton as not enforced to avoice hiding bugs! http://boredzo.org/blog/archives/2009-06-17/doing-it-wrong

@synthesize rawWords = _rawWords;
@synthesize processedWords = _processedWords;
@synthesize allWords = _allWords;
@synthesize collectionNames = _collectionNames;
@synthesize smallCollectionNames = _smallCollectionNames;
@synthesize tagNames = _tagNames;
@synthesize allUKWords = _allUKWords;
@synthesize allUSWords = _allUSWords;
@synthesize spellingVariant = _spellingVariant;
@synthesize recentlyViewedWords = _recentlyViewedWords;
@synthesize wordProcessingNeeded = _wordProcessingNeeded;
@synthesize unusedPronunciations = _unusedPronunciations;


+ (DD2Words *)sharedWords
{
    if (sharedWords == nil) sharedWords = [[DD2Words alloc] init];
    return sharedWords;
}

- (NSArray *)recentlyViewedWords {
    if (!_recentlyViewedWords) _recentlyViewedWords = [[NSArray alloc] init];
    return _recentlyViewedWords;
}

- (NSMutableSet *)unusedPronunciations {
    if (!_unusedPronunciations) _unusedPronunciations = [[NSMutableSet alloc] init];
    return _unusedPronunciations;
}


- (BOOL) wordProcessingNeeded {
    if (!_wordProcessingNeeded) {
        NSString * lastBuildProcessed = [[NSUserDefaults standardUserDefaults] stringForKey:APPLICATION_BUILD];
        NSString * thisBuild = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        NSLog(@" lastBuildProcessed = %@ , This build = %@", lastBuildProcessed, thisBuild);
        if ([lastBuildProcessed intValue] < [thisBuild intValue] || PROCESS_ON_BUILD) {
            //new build words need processing
            self.wordProcessingNeeded = true;
        } else {
            self.wordProcessingNeeded = false;
        }
    }
    return _wordProcessingNeeded;
}

- (NSDictionary *)rawWords
{
    if (!_rawWords) {
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
            
            NSLog(@"word count = %lu",(unsigned long)[[json objectForKey:@"words"] count]);
            
            if (PROCESS_VERBOSELY) NSLog(@"first word = %@",[[json objectForKey:@"words"] objectAtIndex:0]);
            if (PROCESS_VERBOSELY) NSLog(@"first word spelling = %@",[[[json objectForKey:@"words"] objectAtIndex:0] objectForKey:@"word"] );
            
            _rawWords = json;
        }
    }
    return _rawWords;
}

-(NSArray *)allWords
{
    if (!_allWords) {
        _allWords = [self.processedWords objectForKey:ALL];
        if (PROCESS_VERBOSELY) NSLog(@"%@ has = %lu words", ALL ,(unsigned long)[_allWords count]);
    }
    return _allWords;
}

-(NSArray *)collectionNames
{
    if(!_collectionNames) {
        _collectionNames = [self.processedWords objectForKey:COLLECTION_NAMES];
        if (PROCESS_VERBOSELY) NSLog(@"%@ has = %@",COLLECTION_NAMES, _collectionNames);
    }
    return _collectionNames;
}

-(NSArray *)smallCollectionNames
{
    if(!_smallCollectionNames) {
        _smallCollectionNames = [self.processedWords objectForKey:SMALL_COLLECTION_NAMES];
        if (PROCESS_VERBOSELY) NSLog(@"%@ has = %@",SMALL_COLLECTION_NAMES, _smallCollectionNames);
    }
    return _smallCollectionNames;
}

-(NSArray *)tagNames
{
    if(!_tagNames) {
        _tagNames = [self.processedWords objectForKey:TAG_NAMES];
        if (PROCESS_VERBOSELY) NSLog(@"%@ has = %@", TAG_NAMES, _tagNames);
    }
    return _tagNames;
}

-(NSArray *)allUKWords
{
    if (!_allUKWords) {
        _allUKWords = [self.processedWords objectForKey:ALL_UK_WORDS];
        if (PROCESS_VERBOSELY) NSLog(@"%@ has = %lu words", ALL_UK_WORDS, (unsigned long)[_allUKWords count]);
    }
    return _allUKWords;
}

-(NSArray *)allUSWords
{
    if (!_allUSWords) {
        _allUSWords = [self.processedWords objectForKey:ALL_US_WORDS];
        if (PROCESS_VERBOSELY) NSLog(@"%@ has = %lu words", ALL_US_WORDS, (unsigned long)[_allUSWords count]);
    }
    return _allUSWords;
}

-(NSDictionary *)processedWords
{
    if (!_processedWords) {
        NSURL * archiveFullUrl = [[DD2GlobalHelper archiveFileDirectory] URLByAppendingPathComponent:kDataFile];
        NSDictionary *pWords = [[NSDictionary alloc] init];
        NSDate *start = [NSDate date];
        
        if (!self.wordProcessingNeeded) {
            @try {
                NSLog(@"**** attempting to get Archived Words ****");
                pWords = [NSKeyedUnarchiver unarchiveObjectWithFile:archiveFullUrl.path];
                _processedWords = pWords;
            }
            @catch (NSException *exception) {
                NSLog(@"**** NSKeyedUnarchiver threw exception ****");
                NSLog(@"%@", exception);
            }
        }
        if (!_processedWords) {
            NSLog(@"**** Processing Words ****");
            pWords = [self processWords];
            
            //save file in cache/archive
            BOOL success = [NSKeyedArchiver archiveRootObject:pWords toFile:archiveFullUrl.path];
            NSLog(@"Archived processed words = %@", success ? @"successfully" : @"archive failed");
            if (success) {
                self.wordProcessingNeeded = false;
                // save version of app with sucessfully processed words to NSUserDefaults
                NSString * build = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
                [[NSUserDefaults standardUserDefaults] setObject:build forKey:APPLICATION_BUILD];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            NSTimeInterval ti = [start timeIntervalSinceNow];
            NSLog( @"processed words in %.4lf seconds", -ti);
            //track processing time with GA
            [DD2GlobalHelper sendEventToGAWithCategory:@"uiStartup" action:@"words" label:@"processed" value:[NSNumber numberWithFloat:-ti ]];
            NSLog(@"**** Processing Ended ****");
        } else {
            NSTimeInterval ti = [start timeIntervalSinceNow];
            NSLog( @"archive retrieved in %.4lf seconds", -ti);
            //track processing time with GA
            [DD2GlobalHelper sendEventToGAWithCategory:@"uiStartup" action:@"words" label:@"archiveUsed" value:[NSNumber numberWithFloat:-ti]];
            NSLog(@"**** Using Archived Words ****");
        }
        _processedWords = pWords;
    }
    return _processedWords;
}


-(NSDictionary *)processWords
{
    NSMutableDictionary *workingProcessedWords = [[NSMutableDictionary alloc] init];
    NSMutableArray *workingCollectionNames = [[NSMutableArray alloc] init];
    NSMutableArray *workingSmallCollectionNames = [[NSMutableArray alloc] init];
    NSMutableArray *workingUKWords = [[NSMutableArray alloc] init];
    NSMutableArray *workingUSWords = [[NSMutableArray alloc] init];
    NSMutableArray *workingTagNames = [[NSMutableArray alloc] init];
    NSMutableArray *workingAllWords = [[NSMutableArray alloc] init];
    
    if (FIND_UNUSED_PRONUNCIATIONS) {
        for (NSURL *fileURL in [DD2GlobalHelper allPronunciationFiles]) {
            [self.unusedPronunciations addObject:[[fileURL lastPathComponent] stringByDeletingPathExtension]];
        }
        NSLog(@"unused pronunciations initial count: %lu", (unsigned long)[self.unusedPronunciations count]);
    }
    
    for (NSDictionary *rawWord in [self.rawWords objectForKey:@"words"]) {
        if (PROCESS_VERBOSELY) NSLog(@"\n                                                  ** start processing word **");
        
        //processing for each locale
        NSMutableDictionary *ukProcessedWord = [[self processRawWord:rawWord forLocale:@"uk"] mutableCopy];
        NSSet *pronunciationsUK = [DD2Words pronunciationsForWord:ukProcessedWord];
        
        NSMutableDictionary *usProcessedWord = [[self processRawWord:rawWord forLocale:@"us"] mutableCopy];
        NSSet *pronunciationsUS = [DD2Words pronunciationsForWord:usProcessedWord];
        
        NSSet *pronunciations = [NSSet setWithSet:pronunciationsUS];
        pronunciations = [pronunciations setByAddingObjectsFromSet: pronunciationsUK];
        if (PROCESS_VERBOSELY) {
            if ([pronunciationsUS isEqualToSet:pronunciationsUK]) {
                NSLog(@"Pronunciations, %@", pronunciationsUS);
            } else {
                if (PROCESS_VERBOSELY) NSLog(@"Pronunciations (us), %@", pronunciationsUS);
                if (PROCESS_VERBOSELY) NSLog(@"Pronunciations (uk), %@", pronunciationsUK);
            }
        }
        if (FIND_UNUSED_PRONUNCIATIONS){
            [self.unusedPronunciations minusSet:pronunciations];
            //NSLog(@"unusedPronunciations count: %lu", (unsigned long)[unusedPronunciations count]);
        }
        
        if (usProcessedWord && ukProcessedWord) {   // can only be a us/uk variation if both exist
            NSString *usukVariantType;
            if ([ukProcessedWord objectForKey:@"locHomophones"] != [usProcessedWord objectForKey:@"locHomophones"]) {
                usukVariantType = [DD2Words appendText:@"locHomophones" toType:usukVariantType];
            }
            if (![[ukProcessedWord objectForKey:@"spelling"] isEqualToString:[usProcessedWord objectForKey:@"spelling"]]) {
                usukVariantType = [DD2Words appendText:@"spelling" toType:usukVariantType];
            }
            if ([ukProcessedWord objectForKey:@"pronunciations"] != [usProcessedWord objectForKey:@"pronunciations"]) {
                usukVariantType = [DD2Words appendText:@"locHeteronyms" toType:usukVariantType];
            }
            
            for (NSString *pronunciation in pronunciations) {
                if ([pronunciation length] > 3) {
                    NSString *prefix = [pronunciation substringWithRange:NSMakeRange(0, 3)];
                    if ([prefix isEqualToString:@"uk-"] || [prefix isEqualToString:@"us-"]) {
                        usukVariantType = [DD2Words appendText:@"pronunciation" toType:usukVariantType];
                    }
                }
            }
            
            // only add if there is a variant type
            if (usukVariantType) {
                [usProcessedWord setObject:usukVariantType forKey:@"usukVariant"];
                [ukProcessedWord setObject:usukVariantType forKey:@"usukVariant"];
                if (PROCESS_VERBOSELY) NSLog(@"Added UK US VariantType %@ to %@ (%@) and %@ (%@)", usukVariantType, [ukProcessedWord objectForKey:@"spelling"], [ukProcessedWord objectForKey:@"wordVariant"], [usProcessedWord objectForKey:@"spelling"], [usProcessedWord objectForKey:@"wordVariant"]);
            }
        }
        
        if (usProcessedWord) {
            [workingAllWords addObject:usProcessedWord];
            [workingUSWords addObject:usProcessedWord];
        }
        if (ukProcessedWord) {
            [workingAllWords addObject:ukProcessedWord];
            [workingUKWords addObject:ukProcessedWord];
        }
        
        //processing collections on raw word
        NSMutableArray *collections = [NSMutableArray arrayWithArray:[rawWord objectForKey:@"collections"]];
        for (NSString *collection in collections) {
            if (![workingCollectionNames containsObject:collection]) [workingCollectionNames addObject:collection];
        }
        
        //processing Small Collections on raw word
        NSArray *rawSmallCollection = [rawWord objectForKey:@"small_collection"];
        for (NSString *smallCollection in rawSmallCollection) {
            if (![workingSmallCollectionNames containsObject:smallCollection]) {
                [workingSmallCollectionNames addObject:smallCollection];
            }
        }
                                      
        //processing Tags on raw word (ignoring locale as no tagged words have a spelling variations will endup with all UK words)
        NSArray *tags = [rawWord objectForKey:@"tags"];
        for (NSString *tag in tags) {
            if (![workingTagNames containsObject:tag]) [workingTagNames addObject:tag];
        }
    }
    
    [workingProcessedWords setObject:workingCollectionNames forKey:COLLECTION_NAMES];
    [workingProcessedWords setObject:workingSmallCollectionNames forKey:SMALL_COLLECTION_NAMES];
    [workingProcessedWords setObject:workingTagNames forKey:TAG_NAMES];
    [workingProcessedWords setObject:workingUKWords forKey:ALL_UK_WORDS];
    [workingProcessedWords setObject:workingUSWords forKey:ALL_US_WORDS];
    [workingProcessedWords setObject:workingAllWords forKey:ALL];
    
    //check for duplicate words
    if (FIND_DUPLICATE_WORDS) [self logAnyDuplicateWordsIn:workingAllWords];
    // check for unused pronunciations
    if (FIND_UNUSED_PRONUNCIATIONS) {
        if ([self.unusedPronunciations count] > 0) {
            for (NSURL *fileURL in self.unusedPronunciations) {
                NSLog(@"unused file:%@", [fileURL lastPathComponent]);
            };
        } else {
            NSLog(@"***** No unused pronunciation files *****");
        }
        
    }

    return [workingProcessedWords copy];
    
}

- (NSDictionary *) processRawWord:(NSDictionary *)rawWord forLocale:(NSString *)locale
{
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
    if (!spelling) processedWord = nil;       // some words only have a uk variant eg cheque, tyre
    if (PROCESS_VERBOSELY) NSLog(@"%@ (%@)", spelling, locale);
    
    if (processedWord) {            // only continue processing if a variant exsists for this locale
        
        NSString *cleanSpelling = [DD2Words exchangeUnderscoresForSpacesin:spelling];
        [processedWord setObject:cleanSpelling forKey:@"spelling"];  //need for easy sorting
        
        //add doubleMetaphone codes
        NSArray *doubleMetaphoneCodes = [DD2GlobalHelper doubleMetaphoneCodesFor:spelling];
        [processedWord setObject:[doubleMetaphoneCodes objectAtIndex:0] forKey:@"doubleMphonePrimary"];
        if ([doubleMetaphoneCodes count]>1) [processedWord setObject:[doubleMetaphoneCodes objectAtIndex:1] forKey:@"doubleMphoneAlt"];
        
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
                    if (PROCESS_VERBOSELY) NSLog(@"%@ is a heteronym with homophones", spelling);       //eg read
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
                if (PROCESS_VERBOSELY) NSLog(@"no locHomophones for %@ %@", spelling, locale);      // needed where locHomophones only exsit in one locale eg buoy (uk:boy)
            }
        }
        
        //processing for homophones - primer (homophones only for US local)
        id pronunciationsElement = [rawWord objectForKey:@"pronunciations"];
        if ([pronunciationsElement isKindOfClass:[NSDictionary class]]) {
            NSDictionary *pronunciationsElementDictionary = (NSDictionary *)pronunciationsElement;
            if (PROCESS_VERBOSELY) NSLog(@"Pronunciations is a Dictionary, %@", pronunciationsElement);
            [processedWord setObject:[pronunciationsElementDictionary objectForKey:locale] forKey:@"pronunciations"];
        }
        
    }
    
    //if (PROCESS_VERBOSELY) NSLog(@"processed word %@", processedWord);
    //processing for all words
    
    return processedWord;
}

- (void) logAnyDuplicateWordsIn:(NSArray *)wordList{
    NSCountedSet *countedSet = [NSCountedSet setWithArray:[wordList valueForKey:@"spelling"]];
    int n=0;
    for (NSDictionary *word in wordList)
        if([countedSet countForObject:[word valueForKey:@"spelling"]] > 2) {
            NSLog(@"***** duplicate %@ *****", [word valueForKey:@"spelling"]);
            n+=1;
        }
    if (n==0) NSLog(@"***** No duplicate words *****");
}

- (NSArray *)allWordsForCurrentSpellingVariant {
    /* inefficient
    NSPredicate *selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.wordVariant LIKE[c] %@",[self.spellingVariant lowercaseString]];
    if (LOG_PREDICATE_RESULTS) {
        NSLog(@"Searching in allWordsForCurrentSpellingVariant");
        NSLog(@"predicate = %@", selectionPredicate);
//        if (LOG_PREDICATE_RESULTS) [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:self.allWords];
    }
    NSArray *matches = [NSArray arrayWithArray:[self.allWords filteredArrayUsingPredicate:selectionPredicate]];
    return matches;
     */
    if(LOG_MORE) NSLog(@"spelling variant for allWordsForCurrentSpellingVariant = %@", self.spellingVariant);
    if ([self.spellingVariant isEqualToString:@"UK"]) {
        return self.allUKWords;
    } else {
        return self.allUSWords;
    }
    
}

- (NSArray *)wordsForCurrentSpellingVariantInCollectionNamed:(NSString *)collectionName {
    NSArray *wordListForCurrentSV = [self allWordsForCurrentSpellingVariant];
    
    NSPredicate *selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.collections contains[c] %@", collectionName];
    if (LOG_PREDICATE_RESULTS) {
        NSLog(@"Searching in wordsForCurrentSpellingVariantInCollectionNamed:");
        NSLog(@"predicate = %@", selectionPredicate);
//        [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:wordListForCurrentSV];
    }
    NSArray *matches = [NSArray arrayWithArray:[wordListForCurrentSV filteredArrayUsingPredicate:selectionPredicate]];
    return matches;
}

+ (NSDictionary *)wordsBySectionFromWordList:(NSArray *)wordList
{
    NSMutableDictionary *wordsBySections = [[NSMutableDictionary alloc] init];
    NSLog(@"# words = %lu", (unsigned long)[wordList count]);
    
    for (NSDictionary *word in wordList) {
        NSString *sectionForWord = word[@"section"];
        if([wordsBySections objectForKey:sectionForWord]) {
            NSArray *currentWordsForSection = [wordsBySections objectForKey:sectionForWord];
            currentWordsForSection = [currentWordsForSection arrayByAddingObject:word];
            [wordsBySections setObject:currentWordsForSection forKey:sectionForWord];
        } else {        // first word in section
            [wordsBySections setObject:[NSArray arrayWithObject:word] forKey:sectionForWord];
        }
    }
    
    if (LOG_MORE) {
        for (NSString* section in [[wordsBySections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
            NSLog(@"count of words in section %@ = %lu", section, (unsigned long)[wordsBySections[section] count]);
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

+ (NSDictionary *) wordWithOtherSpellingVariantFrom:(NSDictionary *)word andListOfAllWords:(NSArray *)allWords {
    id wordElement = [word objectForKey:@"word"];
    NSLog(@"usuk wordWithOtherSpellingVariantFrom wordElement= %@", wordElement);
    
    NSPredicate *selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.word = %@", wordElement];
    if (LOG_PREDICATE_RESULTS) {
        NSLog(@"Searching in wordWithOtherSpellingVariantFrom:andListOfAllWords:");
        NSLog(@"predicate = %@", selectionPredicate);
        [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:allWords];
    }
    
    
    NSArray *matches = [NSArray arrayWithArray:[allWords filteredArrayUsingPredicate:selectionPredicate]];
    if ([matches count] > 2) NSLog(@"*** too many matches (when looking for other spelling variants) ***");
    NSDictionary *foundWord = nil;
    for (NSDictionary *candidateWord in matches) {
        
        if ([candidateWord isEqualToDictionary:word]) {
            if (LOG_MORE) NSLog(@"Removed current word from other spelling variant matches");
            continue;   //to avoid setting foundWord to self.
        } else if ([[candidateWord objectForKey:@"usukVariant"] isEqualToString:[word objectForKey:@"usukVariant"]]) {
            foundWord = candidateWord;
            if (LOG_MORE) NSLog(@"US/UK spelling variant found %@", foundWord);
        } else {
            if (LOG_MORE) NSLog(@"US/UK spelling variant not found");
        }
    }
    
    return foundWord;
}

+ (NSString *) appendText:(NSString *)text toType:(NSString *)type {
    NSString *result;
    if (!type) {
        result = text;
    } else {
        result = [NSString stringWithFormat:@"%@ %@", type, text];
    }
    return result;
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
    
    //convert accented characters to ascii for the filename
    NSData *temp = [cleanerString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *result = [[NSString alloc] initWithData:temp encoding:NSASCIIStringEncoding];
    
    return [NSString stringWithString:result];
}

+ (NSSet *) pronunciationsForWord:(NSDictionary *)word
{
    if (!word) {
        return Nil;
    }
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
    
    if ([pronunciations count] < 1) {    //does it have local variant alt spellings with files
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
        if (FIND_MISSING_PRONUNCIATIONS) NSLog(@"***** file needed: %@ *****", [word objectForKey:@"spelling"]);
    }
    
    // don't log this if looking for missing pronunciations
    if (!FIND_MISSING_PRONUNCIATIONS && PROCESS_VERBOSELY) {
        NSString *pronunciationsStringForLog;
        for (NSString *pronunciation in pronunciations) {
            if (pronunciationsStringForLog) {
                pronunciationsStringForLog = [NSString stringWithFormat:@"%@, %@",pronunciationsStringForLog, pronunciation];
            } else {
                pronunciationsStringForLog = [NSString stringWithFormat:@"%@", pronunciation];
            }
        }
        NSLog(@"%@ pronounced %@", [word objectForKey:@"spelling"], pronunciationsStringForLog);
    }
    return [pronunciations copy];
}

+ (NSDictionary *) homophonesForWord:(NSDictionary *)word andWordList:(NSArray *)wordList { //returns a dictionary of word dictionaries (for each homophone).
    
    //filtering word list to only contain words of the same wordVariant as the subject word.
    NSString *subjectWordVariant = [word objectForKey:@"wordVariant"];
    NSPredicate *selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.wordVariant LIKE[c] %@",subjectWordVariant];
    if (LOG_PREDICATE_RESULTS) {
        NSLog(@"Searching in homophonesForWord:andWordList:");
        NSLog(@"predicate = %@", selectionPredicate);
//        if (LOG_PREDICATE_RESULTS) [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:wordList];
    }
    NSArray *filteredWordList = [NSMutableArray arrayWithArray:[wordList filteredArrayUsingPredicate:selectionPredicate]];
    
    
    NSMutableDictionary *workingResults = [[NSMutableDictionary alloc] init];
    NSSet *pronunciationsForWord = [DD2Words pronunciationsForWord:word];
    if ([pronunciationsForWord count] > 1) {
        for (NSString * pronunciation in pronunciationsForWord) {
            NSArray *homophoneListForPronunciation = [[word objectForKey:@"locHomophones"] objectForKey:pronunciation];
            [workingResults setObject:[DD2Words wordsForHomophones:homophoneListForPronunciation andWordList:filteredWordList] forKey:pronunciation];
        }
    } else {
        NSArray *homophones = [word objectForKey:@"locHomophones"];
        if (homophones) {
            [workingResults setObject:[DD2Words wordsForHomophones:homophones andWordList:filteredWordList] forKey:[pronunciationsForWord anyObject]];
        } else {
            NSLog(@"No homophones on %@", [word objectForKey:@"spelling"]);
        }
    }
    return [workingResults copy];
}

+ (NSMutableArray *) wordsForHomophones:(NSArray *)list andWordList:(NSArray *)wordList {
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
    if (LOG_PREDICATE_RESULTS) {
        NSLog(@"Searching in wordForPronunciation:fromWordList:");
        NSLog(@"predicate = %@", selectionPredicate);
        [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:wordList];
    }
    NSMutableArray *matches = [NSMutableArray arrayWithArray:[wordList filteredArrayUsingPredicate:selectionPredicate]];
    
    if ([matches count] == 1) {
        return [matches lastObject];
    } else {
        // check if pronunciation is a localized version of a spelling and clean out the local part if so.
        if (([pronunciation rangeOfString:@"uk-"].location != NSNotFound) || ([pronunciation rangeOfString:@"us-"].location != NSNotFound)) {
            pronunciation = [pronunciation substringFromIndex:3];
        }
        // get the word that matches if the pronunciation is the spelling
        selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.spelling LIKE %@",pronunciation];      //case sensitive to pick up Miss and miss
        if (LOG_PREDICATE_RESULTS) {
            NSLog(@"Searching in wordForPronunciation:fromWordList: getting word that matches pronunciation is the spelling");
            NSLog(@"predicate = %@", selectionPredicate);
            [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:wordList];
        }
        matches = [NSMutableArray arrayWithArray:[wordList filteredArrayUsingPredicate:selectionPredicate]];
    
        if ([matches count] > 1) NSLog(@"DD2Words more than one matches ** PROBLEM **");
        if ([matches count] == 0) NSLog(@"DD2Words pronunciation not in list");
        return [matches lastObject];
    }
}


+ (void)logDD2WordProperty:(NSString *)property
{
    if ([property isEqualToString:COLLECTION_NAMES]) NSLog(@"DD2Word.%@ = %@", COLLECTION_NAMES, [DD2Words sharedWords].collectionNames);
    if ([property isEqualToString:SMALL_COLLECTION_NAMES]) NSLog(@"DD2Word.%@ = %@", SMALL_COLLECTION_NAMES, [DD2Words sharedWords].smallCollectionNames);
    if ([property isEqualToString:TAG_NAMES]) NSLog(@"DD2Word.%@ = %@", TAG_NAMES, [DD2Words sharedWords].tagNames);
    if ([property isEqualToString:ALL_US_WORDS]) NSLog(@"DD2Word.%@ = %@", ALL_US_WORDS, [DD2Words sharedWords].allUSWords);
    if ([property isEqualToString:ALL_UK_WORDS]) NSLog(@"DD2Word.%@ = %@", ALL_UK_WORDS, [DD2Words sharedWords].allUKWords);
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
    
    //checking to see if usukOtherWordVariant is in the list (if wordVariant was the same it would already have been removed).
    id wordElement = [word objectForKey:@"word"];
    NSPredicate *selectionPredicate = [NSPredicate predicateWithFormat:@"SELF.word = %@", wordElement];
    if (LOG_PREDICATE_RESULTS) {
        NSLog(@"Searching in viewingWordNow recentWord list management");
        NSLog(@"predicate = %@", selectionPredicate);
        [DD2GlobalHelper testWordPredicate:selectionPredicate onWords:recentWords];
    }
    NSArray *matches = [NSArray arrayWithArray:[recentWords filteredArrayUsingPredicate:selectionPredicate]];
    
    if ([matches count] > 0) {
        NSLog(@"other usuk word variant already in recents not adding again");
    } else {
        [recentWords insertObject:word atIndex:0];
        if ([recentWords count] > 50) [recentWords removeLastObject];
        
        [defaults setObject:recentWords forKey:RECENTLY_VIEWED_WORDS_KEY];
        [defaults synchronize];
        NSLog(@"recent word count: %lu", (unsigned long)[recentWords count]);
    }
    
}


+ (NSArray *) currentRecentlyViewedWordList {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *recentlyViewedWords = [defaults objectForKey:RECENTLY_VIEWED_WORDS_KEY];
    return recentlyViewedWords;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"collection: %@, tags: %@ word count: %lu recents: %@",
            self.collectionNames,
            self.tagNames,
            (unsigned long)[self.allWords count],
            self.recentlyViewedWords];
}

@end
