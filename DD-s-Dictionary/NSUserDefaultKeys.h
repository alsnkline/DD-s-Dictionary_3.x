//
//  NSUserDefaultKeys.h
//  DDPrototype
//
//  Created by Alison Kline on 8/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PLAY_WORDS_ON_SELECTION @"DDPrototype.PlayWordsOnSelection"
#define VOICE_HINT_AVAILABLE @"DDPrototype.VoiceHintsAvailable"  //appington uses changeable
#define NOT_USE_VOICE_HINTS @"DDPrototype.NotUseVoiceHints"
#define USE_DYSLEXIE_FONT @"DDPrototype.UseDyslexieFont"
#define BACKGROUND_COLOR_HUE @"DDPrototype.BackgroundColorHue"
#define BACKGROUND_COLOR_SATURATION @"DDPrototype.BackgroundColorSaturation"
#define APPLICATION_VERSION @"DDPrototype.ApplicationVersion"
#define PROCESSED_DOC_SCHEMA_VERSION_205 @"DDPrototype.MigratedToVersion205"

#define SPELLING_VARIANT @"DDPrototype.spellingVariant"
#define SELECTED_COLLECTIONS @"DDPrototype.selectedCollections"

@protocol NSUserDefaultKeys <NSObject>

@end
