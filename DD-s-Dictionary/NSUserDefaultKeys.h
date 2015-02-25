//
//  NSUserDefaultKeys.h
//  DDPrototype
//
//  Created by Alison Kline on 8/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PLAY_WORDS_ON_SELECTION @"DDPrototype.PlayWordsOnSelection"
#define VOICE_HINT_AVAILABLE @"DDPrototype.VoiceHintsAvailable"  //appington used this to provide control and voice groups (not used Jan 2015) changable
#define NOT_USE_VOICE_HINTS @"DDPrototype.NotUseVoiceHints"     //user control to turn off voice hints (not used Jan 2015)
#define USE_DYSLEXIE_FONT @"DDPrototype.UseDyslexieFont"
#define BACKGROUND_COLOR_HUE @"DDPrototype.BackgroundColorHue"
#define BACKGROUND_COLOR_SATURATION @"DDPrototype.BackgroundColorSaturation"
#define APPLICATION_VERSION @"DDPrototype.ApplicationVersion"
#define APPLICATION_BUILD @"DDPrototype.ApplicationBuild"
#define PROCESSED_DOC_SCHEMA_VERSION_205 @"DDPrototype.MigratedToVersion205"

#define SPELLING_VARIANT @"DDPrototype.spellingVariant"
#define SELECTED_COLLECTIONS @"DDPrototype.selectedCollections"
#define RECENTLY_VIEWED_WORDS_KEY @"DDPrototype.RecentlyViewedWords"

@protocol NSUserDefaultKeys <NSObject>

@end
