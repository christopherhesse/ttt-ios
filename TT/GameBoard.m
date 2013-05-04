#import "GameBoard.h"

typedef struct {
    int index, value;
} Move;

// List of winning groups of indicies
// 0 1 2
// 3 4 5
// 6 7 8
// Terminate with -1
int kGroups[] = {0,1,2,3,4,5,6,7,8,0,3,6,1,4,7,2,5,8,0,4,8,2,4,6, -1};

@implementation GameBoard

- (id)initWithDimensions:(int)dimensions {
    _dimensions = dimensions;
    self.state = [NSMutableDictionary dictionary];
    self.cells = [NSMutableArray array];
    
    // initialize game state and list of cells
    for (int row = 0; row < _dimensions; row++) {
        for (int column = 0; column < _dimensions; column++) {
            NSArray* cell = @[[NSNumber numberWithInt:row], [NSNumber numberWithInt:column]];
            [self.cells addObject:cell];
            self.state[cell] = kNoPlayer;
        }
    }
    
    return self;
}

- (NSArray*)cellFromIndex:(int)index {
    int row = index / _dimensions;
    int column = index % _dimensions;
    return @[[NSNumber numberWithInt:row], [NSNumber numberWithInt:column]];
}


- (int)indexFromRow:(int)row column:(int)column {
    return row * _dimensions + column;
}

- (Outcome)evaluateOutcome {
    return [self evaluateOutcome:[self convertBoard]];
}

- (NSMutableArray*)convertBoard {
    int index = 0;
    NSMutableArray* board = [NSMutableArray array];
    for (NSArray* cell in self.cells) {
        board[index] = self.state[cell];
        index++;
    }
    return board;
}

- (Outcome)evaluateOutcome:(NSArray*)board {
    for (int index = 0; kGroups[index] != -1; index += _dimensions) {
        // if all cells in a groups have the same player, that player wins
        NSString* player = board[kGroups[index]];
        for (int offset = 1; offset < _dimensions; offset++) {
            if (player != board[kGroups[index + offset]]) {
                player = kNoPlayer;
                break;
            }
        }
        
        if (player == kComputerPlayer) {
            return kComputerWinsOutcome;
        } else if (player == kHumanPlayer) {
            return kHumanWinsOutcome;
        }
    }
    
    // check to see if the game is a tie, it's a tie if all spaces have been used
    for (int index = 0; index < _dimensions * _dimensions; index++) {
        if (board[index] == kNoPlayer) {
            return kUnresolvedOutcome;
        }
    }
    
    return kDrawOutcome;
}

- (NSArray*)decideComputerMove {
    Move move = [self negamaxForPlayer:kComputerPlayer withBoard:[self convertBoard]];
    return [self cellFromIndex:move.index];
}

- (Move)negamaxForPlayer:(NSString*)player withBoard:(NSMutableArray*)board {
    Outcome outcome = [self evaluateOutcome:board];
    
    if (outcome == kDrawOutcome) {
        return (Move){-1, 0};
    }
    
    if (outcome == kHumanWinsOutcome || outcome == kComputerWinsOutcome) {
        // since the other player just made a move, this means they won
        return (Move){-1, -1};
    }
    
    NSString* otherPlayer;
    if (player == kComputerPlayer) {
        otherPlayer = kHumanPlayer;
    } else {
        otherPlayer = kComputerPlayer;
    }
    
    Move bestMove = (Move){-1, -1};
    for (int index = 0; index < _dimensions * _dimensions; index++) {
        if (board[index] == kNoPlayer) {
            board[index] = player;
            Move move = [self negamaxForPlayer:otherPlayer withBoard:board];
            // this is the nega part
            move.value = -move.value;
            board[index] = kNoPlayer;
            
            if (move.value > bestMove.value) {
                bestMove = move;
                bestMove.index = index;
                
                if (bestMove.value == 1) {
                    return bestMove;
                }
            }
        }
    }
    return bestMove;
}

@end