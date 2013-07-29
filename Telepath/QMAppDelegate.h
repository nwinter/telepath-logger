//
//  QMAppDelegate.h
//  Telepath
//
//  Created by Nick Winter on 8/2/12.
//

#import <Cocoa/Cocoa.h>

float WINDOW_SAMPLE_RATE = 0.025;  /// We'll sample changes to the foremost window this often, and write out events to the log file. This should be often enough to, for example, not miss any tabs when holding down Ctrl+Tab to cycle through Chrome tabs. (My testing showed hitting only 1/2 tabs at 100ms sampling.)
float ACCELEROMETER_SAMPLE_RATE = 0.01;  /// We'll sample changes to the accelerometer this often, plus whenever we do something interesting.
double FILE_SWITCH_INTERVAL = 1 * 24 * 60 * 60;  /// We'll switch log files this often.
double QUANTIFIED_MIND_PROMPT_INTERVAL = 3 * 60 * 60;  /// We'll prompt them to do a QM battery about this often.
double QUANTIFIED_MIND_RANDOMIZATION = 0.3333;  /// QM prompting will occur +/- this fraction of the interval.
double WEBCAM_INTERVAL = 2 * 60;  /// We'll take a webcam screenshot at this interval (seconds).

@interface QMAppDelegate : NSObject <NSApplicationDelegate>

@end

NSString *JSONRepresentation(id object);