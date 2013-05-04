#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, Outcome) {
    kDrawOutcome,
    kComputerWinsOutcome,
    kHumanWinsOutcome,
    kUnresolvedOutcome,
};

extern NSString* const kNoPlayer;
extern NSString* const kComputerPlayer;
extern NSString* const kHumanPlayer;