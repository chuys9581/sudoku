#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

#include <algorithm>
#include <array>
#include <chrono>
#include <functional>
#include <numeric>
#include <random>
#include <string>
#include <vector>

namespace {

using Grid = std::array<std::array<int, 9>, 9>;

enum class Difficulty {
  Easy,
  Medium,
  Hard,
};

class SudokuEngine {
public:
  SudokuEngine()
      : rng_(static_cast<unsigned>(std::chrono::high_resolution_clock::now()
                                       .time_since_epoch()
                                       .count())) {
    newGame(Difficulty::Medium);
  }

  void newGame(Difficulty difficulty) {
    solution_ = generateSolution();
    board_ = solution_;

    int cellsToRemove = 42;
    switch (difficulty) {
    case Difficulty::Easy:
      cellsToRemove = 35;
      break;
    case Difficulty::Medium:
      cellsToRemove = 42;
      break;
    case Difficulty::Hard:
      cellsToRemove = 50;
      break;
    }

    removeCells(cellsToRemove);

    for (int r = 0; r < 9; ++r) {
      for (int c = 0; c < 9; ++c) {
        fixed_[r][c] = (board_[r][c] != 0);
      }
    }
  }

  int valueAt(int row, int col) const { return board_[row][col]; }

  int solutionValueAt(int row, int col) const { return solution_[row][col]; }

  bool isFixed(int row, int col) const { return fixed_[row][col]; }

  bool setValue(int row, int col, int value) {
    if (fixed_[row][col]) {
      return false;
    }

    if (value == 0) {
      board_[row][col] = 0;
      return true;
    }

    if (value < 1 || value > 9) {
      return false;
    }

    board_[row][col] = value;
    return true;
  }

  int wrongCellCount() const {
    int wrong = 0;
    for (int r = 0; r < 9; ++r) {
      for (int c = 0; c < 9; ++c) {
        if (board_[r][c] != 0 && board_[r][c] != solution_[r][c]) {
          ++wrong;
        }
      }
    }
    return wrong;
  }

  int emptyCellCount() const {
    int empty = 0;
    for (int r = 0; r < 9; ++r) {
      for (int c = 0; c < 9; ++c) {
        if (board_[r][c] == 0) {
          ++empty;
        }
      }
    }
    return empty;
  }

  bool isComplete() const { return board_ == solution_; }

  void revealSolution() { board_ = solution_; }

private:
  Grid solution_{};
  Grid board_{};
  std::array<std::array<bool, 9>, 9> fixed_{};
  std::mt19937 rng_;

  Grid generateSolution() {
    Grid base{};

    std::array<int, 9> numbers{};
    std::iota(numbers.begin(), numbers.end(), 1);
    std::shuffle(numbers.begin(), numbers.end(), rng_);

    for (int r = 0; r < 9; ++r) {
      for (int c = 0; c < 9; ++c) {
        int pattern = (r * 3 + r / 3 + c) % 9;
        base[r][c] = numbers[pattern];
      }
    }

    shuffleBands(base);
    shuffleRowsInBands(base);
    shuffleStacks(base);
    shuffleColsInStacks(base);

    return base;
  }

  void shuffleBands(Grid &grid) {
    std::array<int, 3> bands{0, 1, 2};
    std::shuffle(bands.begin(), bands.end(), rng_);

    Grid copy = grid;
    for (int b = 0; b < 3; ++b) {
      for (int i = 0; i < 3; ++i) {
        grid[b * 3 + i] = copy[bands[b] * 3 + i];
      }
    }
  }

  void shuffleRowsInBands(Grid &grid) {
    Grid copy = grid;
    for (int b = 0; b < 3; ++b) {
      std::array<int, 3> order{0, 1, 2};
      std::shuffle(order.begin(), order.end(), rng_);
      for (int i = 0; i < 3; ++i) {
        grid[b * 3 + i] = copy[b * 3 + order[i]];
      }
    }
  }

  void shuffleStacks(Grid &grid) {
    std::array<int, 3> stacks{0, 1, 2};
    std::shuffle(stacks.begin(), stacks.end(), rng_);

    Grid copy = grid;
    for (int r = 0; r < 9; ++r) {
      for (int s = 0; s < 3; ++s) {
        for (int i = 0; i < 3; ++i) {
          grid[r][s * 3 + i] = copy[r][stacks[s] * 3 + i];
        }
      }
    }
  }

  void shuffleColsInStacks(Grid &grid) {
    Grid copy = grid;
    for (int s = 0; s < 3; ++s) {
      std::array<int, 3> order{0, 1, 2};
      std::shuffle(order.begin(), order.end(), rng_);
      for (int r = 0; r < 9; ++r) {
        for (int i = 0; i < 3; ++i) {
          grid[r][s * 3 + i] = copy[r][s * 3 + order[i]];
        }
      }
    }
  }

  void removeCells(int count) {
    std::vector<int> indexes(81);
    std::iota(indexes.begin(), indexes.end(), 0);
    std::shuffle(indexes.begin(), indexes.end(), rng_);

    int removed = 0;
    for (int idx : indexes) {
      if (removed >= count) {
        break;
      }

      int r = idx / 9;
      int c = idx % 9;
      board_[r][c] = 0;
      ++removed;
    }
  }
};

NSString *difficultyLabel(Difficulty difficulty) {
  switch (difficulty) {
  case Difficulty::Easy:
    return @"Facil";
  case Difficulty::Medium:
    return @"Media";
  case Difficulty::Hard:
    return @"Dificil";
  }

  return @"Media";
}

NSString *trimmed(NSString *raw) {
  return [raw
      stringByTrimmingCharactersInSet:[NSCharacterSet
                                          whitespaceAndNewlineCharacterSet]];
}

NSString *passwordHash(NSString *password) {
  const char *utf8 = [password UTF8String];
  std::string value = utf8 ? utf8 : "";
  std::hash<std::string> hasher;
  return [NSString stringWithFormat:@"%zu", hasher(value)];
}

BOOL isValidUserCharacter(unichar ch) {
  return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') ||
         (ch >= '0' && ch <= '9') || ch == '_' || ch == '-';
}

} // namespace

@interface CyberBackgroundView : NSView
@end

@implementation CyberBackgroundView

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];

  NSColor *top = [NSColor colorWithRed:0.02 green:0.04 blue:0.1 alpha:1.0];
  NSColor *bottom = [NSColor colorWithRed:0.0 green:0.01 blue:0.03 alpha:1.0];
  NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:top
                                                       endingColor:bottom];
  [gradient drawInRect:self.bounds angle:-90.0];

  [[NSColor colorWithRed:0.1 green:0.84 blue:0.96 alpha:0.12] setStroke];
  for (CGFloat y = 0; y < self.bounds.size.height; y += 36.0) {
    NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(0, y)];
    [line lineToPoint:NSMakePoint(self.bounds.size.width, y)];
    line.lineWidth = 0.5;
    [line stroke];
  }

  [[NSColor colorWithRed:0.22 green:0.96 blue:0.72 alpha:0.09] setStroke];
  for (CGFloat x = 0; x < self.bounds.size.width; x += 48.0) {
    NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(x, 0)];
    [line lineToPoint:NSMakePoint(x, self.bounds.size.height)];
    line.lineWidth = 0.5;
    [line stroke];
  }

  NSBezierPath *glow1 = [NSBezierPath
      bezierPathWithOvalInRect:NSMakeRect(40, self.bounds.size.height - 240,
                                          260, 260)];
  [[NSColor colorWithRed:0.08 green:0.82 blue:0.96 alpha:0.18] setFill];
  [glow1 fill];

  NSBezierPath *glow2 = [NSBezierPath
      bezierPathWithOvalInRect:NSMakeRect(self.bounds.size.width - 310, 60, 240,
                                          240)];
  [[NSColor colorWithRed:0.34 green:0.96 blue:0.76 alpha:0.14] setFill];
  [glow2 fill];

  NSBezierPath *glow3 = [NSBezierPath
      bezierPathWithOvalInRect:NSMakeRect(self.bounds.size.width - 220,
                                          self.bounds.size.height - 170, 160,
                                          160)];
  [[NSColor colorWithRed:1.0 green:0.48 blue:0.38 alpha:0.08] setFill];
  [glow3 fill];
}

@end

@interface CenteredTextFieldCell : NSTextFieldCell
@end

@implementation CenteredTextFieldCell

- (NSRect)centeredRectForBounds:(NSRect)frame {
  NSRect textRect = NSInsetRect([super drawingRectForBounds:frame], 10.0, 0.0);
  NSFont *font =
      self.font ?: [NSFont systemFontOfSize:15.0 weight:NSFontWeightMedium];
  CGFloat textHeight = ceil(font.ascender - font.descender);
  if (textHeight <= 0.0) {
    textHeight = NSHeight(textRect);
  }

  CGFloat yOffset = floor((NSHeight(frame) - textHeight) * 0.5) - 1.0;
  textRect.origin.y = NSMinY(frame) + MAX(0.0, yOffset);
  textRect.size.height = textHeight;
  return textRect;
}

- (NSRect)drawingRectForBounds:(NSRect)rect {
  return [self centeredRectForBounds:rect];
}

- (void)editWithFrame:(NSRect)aRect
               inView:(NSView *)controlView
               editor:(NSText *)textObj
             delegate:(id)anObject
                event:(NSEvent *)event {
  [super editWithFrame:[self centeredRectForBounds:aRect]
                inView:controlView
                editor:textObj
              delegate:anObject
                 event:event];
}

- (void)selectWithFrame:(NSRect)aRect
                 inView:(NSView *)controlView
                 editor:(NSText *)textObj
               delegate:(id)anObject
                  start:(NSInteger)selStart
                 length:(NSInteger)selLength {
  [super selectWithFrame:[self centeredRectForBounds:aRect]
                  inView:controlView
                  editor:textObj
                delegate:anObject
                   start:selStart
                  length:selLength];
}

@end

@interface CenteredSecureTextFieldCell : NSSecureTextFieldCell
@end

@implementation CenteredSecureTextFieldCell

- (NSRect)centeredRectForBounds:(NSRect)frame {
  NSRect textRect = NSInsetRect([super drawingRectForBounds:frame], 10.0, 0.0);
  NSFont *font =
      self.font ?: [NSFont systemFontOfSize:15.0 weight:NSFontWeightMedium];
  CGFloat textHeight = ceil(font.ascender - font.descender);
  if (textHeight <= 0.0) {
    textHeight = NSHeight(textRect);
  }

  CGFloat yOffset = floor((NSHeight(frame) - textHeight) * 0.5) - 1.0;
  textRect.origin.y = NSMinY(frame) + MAX(0.0, yOffset);
  textRect.size.height = textHeight;
  return textRect;
}

- (NSRect)drawingRectForBounds:(NSRect)rect {
  return [self centeredRectForBounds:rect];
}

- (void)editWithFrame:(NSRect)aRect
               inView:(NSView *)controlView
               editor:(NSText *)textObj
             delegate:(id)anObject
                event:(NSEvent *)event {
  [super editWithFrame:[self centeredRectForBounds:aRect]
                inView:controlView
                editor:textObj
              delegate:anObject
                 event:event];
}

- (void)selectWithFrame:(NSRect)aRect
                 inView:(NSView *)controlView
                 editor:(NSText *)textObj
               delegate:(id)anObject
                  start:(NSInteger)selStart
                 length:(NSInteger)selLength {
  [super selectWithFrame:[self centeredRectForBounds:aRect]
                  inView:controlView
                  editor:textObj
                delegate:anObject
                   start:selStart
                  length:selLength];
}

@end

@interface CenteredBoardTextFieldCell : NSTextFieldCell
@end

@implementation CenteredBoardTextFieldCell

- (NSRect)centeredRectForBounds:(NSRect)frame {
  NSRect textRect = frame;
  NSFont *font =
      self.font ?: [NSFont systemFontOfSize:24.0 weight:NSFontWeightBold];
  CGFloat textHeight = ceil(font.ascender - font.descender);
  if (textHeight <= 0.0) {
    textHeight = NSHeight(textRect);
  }

  CGFloat yOffset = floor((NSHeight(frame) - textHeight) * 0.5);
  textRect.origin.y = NSMinY(frame) + MAX(0.0, yOffset);
  textRect.size.height = textHeight;
  textRect.origin.x = NSMinX(frame);
  textRect.size.width = NSWidth(frame);
  return textRect;
}

- (NSRect)titleRectForBounds:(NSRect)rect {
  return [self centeredRectForBounds:rect];
}

- (NSRect)drawingRectForBounds:(NSRect)rect {
  return [self centeredRectForBounds:rect];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  (void)controlView;

  NSString *text = self.stringValue ?: @"";
  if (text.length == 0) {
    return;
  }

  NSFont *font =
      self.font ?: [NSFont systemFontOfSize:24.0 weight:NSFontWeightBold];
  NSColor *color = self.textColor ?: [NSColor labelColor];
  NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
  style.alignment = self.alignment;
  style.lineBreakMode = NSLineBreakByClipping;

  NSDictionary *attrs = @{
    NSFontAttributeName : font,
    NSForegroundColorAttributeName : color,
    NSParagraphStyleAttributeName : style,
  };

  NSSize textSize = [text sizeWithAttributes:attrs];
  CGFloat y =
      NSMinY(cellFrame) + floor((NSHeight(cellFrame) - textSize.height) * 0.5);
  NSRect drawRect =
      NSMakeRect(NSMinX(cellFrame), y, NSWidth(cellFrame), textSize.height);
  [text drawInRect:drawRect withAttributes:attrs];
}

- (void)editWithFrame:(NSRect)aRect
               inView:(NSView *)controlView
               editor:(NSText *)textObj
             delegate:(id)anObject
                event:(NSEvent *)event {
  [super editWithFrame:[self centeredRectForBounds:aRect]
                inView:controlView
                editor:textObj
              delegate:anObject
                 event:event];
}

- (void)selectWithFrame:(NSRect)aRect
                 inView:(NSView *)controlView
                 editor:(NSText *)textObj
               delegate:(id)anObject
                  start:(NSInteger)selStart
                 length:(NSInteger)selLength {
  [super selectWithFrame:[self centeredRectForBounds:aRect]
                  inView:controlView
                  editor:textObj
                delegate:anObject
                   start:selStart
                  length:selLength];
}

@end

@interface SudokuController
    : NSObject <NSApplicationDelegate, NSTextFieldDelegate>
@end

@interface SudokuController ()
- (void)setupMenuBar;
- (void)buildWindow;

- (NSFont *)fontWithName:(NSString *)name
                    size:(CGFloat)size
          fallbackWeight:(NSFontWeight)weight;
- (NSTextField *)makeLabelWithFrame:(NSRect)frame
                               text:(NSString *)text
                               font:(NSFont *)font
                              color:(NSColor *)color;
- (NSView *)makePanelWithFrame:(NSRect)frame;
- (NSButton *)makeCyberButtonWithFrame:(NSRect)frame
                                 title:(NSString *)title
                                action:(SEL)action;
- (void)stylePopup:(NSPopUpButton *)popup;
- (NSTextField *)makeInputWithFrame:(NSRect)frame
                        placeholder:(NSString *)placeholder
                             secure:(BOOL)secure;

- (void)showLoadingScreen;
- (void)showAuthScreenWithMessage:(NSString *)message color:(NSColor *)color;
- (void)showMainMenu;
- (void)showGameScreen;

- (NSString *)authValidationErrorForUser:(NSString *)username
                                password:(NSString *)password;
- (NSString *)currentPasswordText;
- (void)setAuthStatus:(NSString *)text color:(NSColor *)color;
- (void)togglePasswordVisibility:(id)sender;
- (void)updatePasswordEyeIcon;
- (void)handleLogin:(id)sender;
- (void)handleCreateUser:(id)sender;
- (void)handleLogout:(id)sender;

- (Difficulty)difficultyFromPopupIndex:(NSInteger)idx;
- (void)startGameFromMenu:(id)sender;
- (void)setGameStatus:(NSString *)text color:(NSColor *)color;
- (void)startGameTimer;
- (void)stopGameTimer;
- (void)updateTimer:(NSTimer *)timer;
- (void)refreshUserPanel;
- (NSInteger)initialLivesForDifficulty:(Difficulty)difficulty;
- (void)startNewGame:(id)sender;
- (void)checkBoard:(id)sender;
- (void)solveBoard:(id)sender;
- (void)clearSelectedCell:(id)sender;
- (void)backToMenu:(id)sender;
- (void)refreshAllCells;
- (void)refreshCellAtRow:(int)row col:(int)col;
- (void)handleCellClick:(NSClickGestureRecognizer *)recognizer;
- (void)selectCellAtIndex:(NSInteger)index;
- (void)selectNumberFromPad:(id)sender;
- (void)applyValueToSelectedCell:(int)value;
- (void)applyValue:(int)value toCellAtRow:(int)row col:(int)col;
- (void)triggerGameOver;
- (void)triggerVictory;
- (void)commitCellValue:(NSTextField *)field;

- (NSString *)usersStorePath;
- (NSString *)legacyUsersStorePath;
- (NSInteger)totalPointsForUser:(NSString *)username;
- (void)recordCurrentGamePoints;
- (NSArray<NSString *> *)sortedUsersByScore;
- (void)loadUsers;
- (void)saveUsers;
@end

@implementation SudokuController {
  NSWindow *window_;
  NSMutableDictionary<NSString *, NSString *> *users_;
  NSMutableDictionary<NSString *, NSNumber *> *userPoints_;
  NSMutableDictionary<NSString *, NSNumber *> *userBestTimes_;

  BOOL blockCompleted_[9];

  NSString *currentUser_;
  Difficulty selectedDifficulty_;

  NSTextField *loginUserField_;
  NSSecureTextField *loginPasswordField_;
  NSTextField *loginPasswordPlainField_;
  NSButton *passwordEyeButton_;
  BOOL passwordVisible_;
  NSTextField *authStatusLabel_;

  NSPopUpButton *menuDifficultyPopup_;

  NSMutableArray<NSTextField *> *cells_;
  NSPopUpButton *gameDifficultyPopup_;
  NSTextField *gameStatusLabel_;
  NSTextField *userValueLabel_;
  NSTextField *difficultyValueLabel_;
  NSTextField *movesValueLabel_;
  NSTextField *timeValueLabel_;
  NSTextField *livesValueLabel_;
  NSTextField *pointsValueLabel_;

  NSInteger selectedCellIndex_;
  NSInteger movesCount_;
  NSInteger livesCount_;
  NSInteger pointsCount_;
  BOOL gameLocked_;
  NSDate *gameStartDate_;
  NSTimer *gameTimer_;

  SudokuEngine engine_;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  (void)notification;
  selectedDifficulty_ = Difficulty::Medium;
  selectedCellIndex_ = -1;
  gameLocked_ = NO;
  passwordVisible_ = NO;

  [self setupMenuBar];
  [self loadUsers];
  [self buildWindow];
  [self showLoadingScreen];

  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.3 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        [self showAuthScreenWithMessage:nil color:nil];
      });

  [window_ makeKeyAndOrderFront:nil];
  [NSApp activateIgnoringOtherApps:YES];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
  (void)notification;
  [self stopGameTimer];
  [self saveUsers];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:
    (NSApplication *)sender {
  (void)sender;
  return YES;
}

- (void)setupMenuBar {
  NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"MainMenu"];
  NSMenuItem *appItem = [[NSMenuItem alloc] initWithTitle:@"App"
                                                   action:nil
                                            keyEquivalent:@""];
  [mainMenu addItem:appItem];

  NSMenu *appSubmenu = [[NSMenu alloc] initWithTitle:@"App"];
  NSString *quitTitle = [NSString
      stringWithFormat:@"Salir %@", [[NSProcessInfo processInfo] processName]];
  NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:quitTitle
                                                    action:@selector(terminate:)
                                             keyEquivalent:@"q"];
  [appSubmenu addItem:quitItem];
  [appItem setSubmenu:appSubmenu];

  [NSApp setMainMenu:mainMenu];
}

- (void)buildWindow {
  NSRect frame = NSMakeRect(0, 0, 1180, 830);
  window_ = [[NSWindow alloc]
      initWithContentRect:frame
                styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                           NSWindowStyleMaskMiniaturizable)
                  backing:NSBackingStoreBuffered
                    defer:NO];
  [window_ setTitle:@"Sudoku Cyber"];
  [window_ center];
}

- (NSFont *)fontWithName:(NSString *)name
                    size:(CGFloat)size
          fallbackWeight:(NSFontWeight)weight {
  NSFont *custom = [NSFont fontWithName:name size:size];
  if (custom) {
    return custom;
  }
  return [NSFont systemFontOfSize:size weight:weight];
}

- (NSTextField *)makeLabelWithFrame:(NSRect)frame
                               text:(NSString *)text
                               font:(NSFont *)font
                              color:(NSColor *)color {
  NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
  label.stringValue = text;
  label.font = font;
  label.textColor = color;
  label.editable = NO;
  label.selectable = NO;
  label.bezeled = NO;
  label.drawsBackground = NO;
  return label;
}

- (NSView *)makePanelWithFrame:(NSRect)frame {
  NSView *panel = [[NSView alloc] initWithFrame:frame];
  panel.wantsLayer = YES;
  panel.layer.backgroundColor =
      [NSColor colorWithRed:0.03 green:0.08 blue:0.15 alpha:0.8].CGColor;
  panel.layer.borderWidth = 1.2;
  panel.layer.borderColor =
      [NSColor colorWithRed:0.13 green:0.83 blue:0.93 alpha:0.65].CGColor;
  panel.layer.cornerRadius = 14.0;
  panel.layer.shadowColor =
      [NSColor colorWithRed:0.0 green:0.85 blue:0.96 alpha:0.55].CGColor;
  panel.layer.shadowOpacity = 0.35;
  panel.layer.shadowRadius = 10.0;
  panel.layer.shadowOffset = CGSizeMake(0, -1);
  return panel;
}

- (NSButton *)makeCyberButtonWithFrame:(NSRect)frame
                                 title:(NSString *)title
                                action:(SEL)action {
  NSButton *button = [[NSButton alloc] initWithFrame:frame];
  button.title = title;
  button.target = self;
  button.action = action;
  button.bordered = NO;
  button.font = [self fontWithName:@"Avenir Next Demi Bold"
                              size:13
                    fallbackWeight:NSFontWeightSemibold];
  button.wantsLayer = YES;
  button.layer.backgroundColor =
      [NSColor colorWithRed:0.06 green:0.27 blue:0.42 alpha:1.0].CGColor;
  button.layer.borderWidth = 1.0;
  button.layer.borderColor =
      [NSColor colorWithRed:0.21 green:0.95 blue:0.88 alpha:0.75].CGColor;
  button.layer.cornerRadius = 8.0;
  button.contentTintColor = [NSColor colorWithRed:0.82
                                            green:0.98
                                             blue:0.99
                                            alpha:1.0];
  return button;
}

- (void)stylePopup:(NSPopUpButton *)popup {
  popup.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
  popup.bordered = NO;
  popup.wantsLayer = YES;
  popup.layer.cornerRadius = 8.0;
  popup.layer.backgroundColor =
      [NSColor colorWithRed:0.03 green:0.12 blue:0.2 alpha:0.95].CGColor;
  popup.layer.borderWidth = 1.0;
  popup.layer.borderColor =
      [NSColor colorWithRed:0.16 green:0.8 blue:0.94 alpha:0.7].CGColor;
  popup.contentTintColor = [NSColor colorWithRed:0.78
                                           green:0.97
                                            blue:0.99
                                           alpha:1.0];

  NSDictionary *attrs = @{
    NSForegroundColorAttributeName : [NSColor colorWithRed:0.78
                                                     green:0.97
                                                      blue:0.99
                                                     alpha:1.0],
    NSFontAttributeName : [self fontWithName:@"Menlo-Regular"
                                        size:13
                              fallbackWeight:NSFontWeightRegular],
  };

  for (NSMenuItem *item in popup.itemArray) {
    item.attributedTitle = [[NSAttributedString alloc] initWithString:item.title
                                                           attributes:attrs];
  }
}

- (NSTextField *)makeInputWithFrame:(NSRect)frame
                        placeholder:(NSString *)placeholder
                             secure:(BOOL)secure {
  NSTextField *field = nil;
  if (secure) {
    NSSecureTextField *secureField =
        [[NSSecureTextField alloc] initWithFrame:frame];
    [secureField
        setCell:[[CenteredSecureTextFieldCell alloc] initTextCell:@""]];
    field = secureField;
  } else {
    NSTextField *plainField = [[NSTextField alloc] initWithFrame:frame];
    [plainField setCell:[[CenteredTextFieldCell alloc] initTextCell:@""]];
    field = plainField;
  }

  field.font = [self fontWithName:@"Menlo-Bold"
                             size:16
                   fallbackWeight:NSFontWeightMedium];
  field.textColor = [NSColor colorWithRed:0.78 green:0.97 blue:0.99 alpha:1.0];
  field.editable = YES;
  field.selectable = YES;
  field.enabled = YES;
  field.allowsEditingTextAttributes = NO;
  field.drawsBackground = YES;
  field.backgroundColor = [NSColor colorWithRed:0.03
                                          green:0.11
                                           blue:0.2
                                          alpha:0.93];
  field.bordered = NO;
  field.focusRingType = NSFocusRingTypeNone;
  field.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
  field.wantsLayer = YES;
  field.layer.cornerRadius = 8.0;
  field.layer.borderWidth = 1.0;
  field.layer.borderColor =
      [NSColor colorWithRed:0.16 green:0.8 blue:0.94 alpha:0.7].CGColor;

  [field.cell setUsesSingleLineMode:YES];
  [field.cell setEditable:YES];
  [field.cell setSelectable:YES];
  [field.cell setLineBreakMode:NSLineBreakByClipping];
  [field.cell setWraps:NO];
  [field.cell setScrollable:YES];

  NSDictionary *placeholderAttrs = @{
    NSForegroundColorAttributeName : [NSColor colorWithRed:0.52
                                                     green:0.78
                                                      blue:0.88
                                                     alpha:0.78],
    NSFontAttributeName : [self fontWithName:@"Menlo-Regular"
                                        size:14
                              fallbackWeight:NSFontWeightRegular],
  };
  field.placeholderAttributedString =
      [[NSAttributedString alloc] initWithString:(placeholder ?: @"")
                                      attributes:placeholderAttrs];

  return field;
}

- (void)showLoadingScreen {
  CyberBackgroundView *root =
      [[CyberBackgroundView alloc] initWithFrame:window_.contentView.bounds];

  NSTextField *title =
      [self makeLabelWithFrame:NSMakeRect(360, 500, 460, 70)
                          text:@"NEXUS SUDOKU"
                          font:[self fontWithName:@"Avenir Next Condensed Bold"
                                             size:56
                                   fallbackWeight:NSFontWeightBold]
                         color:[NSColor colorWithRed:0.65
                                               green:0.97
                                                blue:1.0
                                               alpha:1.0]];
  title.alignment = NSTextAlignmentCenter;
  [root addSubview:title];

  NSTextField *subtitle =
      [self makeLabelWithFrame:NSMakeRect(320, 454, 540, 34)
                          text:@"Inicializando sistema seguro de juego"
                          font:[self fontWithName:@"Menlo-Regular"
                                             size:18
                                   fallbackWeight:NSFontWeightRegular]
                         color:[NSColor colorWithRed:0.6
                                               green:0.94
                                                blue:0.86
                                               alpha:0.9]];
  subtitle.alignment = NSTextAlignmentCenter;
  [root addSubview:subtitle];

  NSProgressIndicator *spinner =
      [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(568, 390, 44, 44)];
  spinner.style = NSProgressIndicatorStyleSpinning;
  spinner.controlSize = NSControlSizeLarge;
  spinner.indeterminate = YES;
  [spinner startAnimation:nil];
  [root addSubview:spinner];

  [window_ setContentView:root];
}

- (void)showAuthScreenWithMessage:(NSString *)message color:(NSColor *)color {
  [self stopGameTimer];
  passwordVisible_ = NO;

  CyberBackgroundView *root =
      [[CyberBackgroundView alloc] initWithFrame:window_.contentView.bounds];

  NSView *authPanel = [self makePanelWithFrame:NSMakeRect(315, 190, 550, 460)];
  [root addSubview:authPanel];

  NSTextField *title =
      [self makeLabelWithFrame:NSMakeRect(30, 380, 490, 54)
                          text:@"Acceso al Sistema"
                          font:[self fontWithName:@"Avenir Next Condensed Bold"
                                             size:44
                                   fallbackWeight:NSFontWeightBold]
                         color:[NSColor colorWithRed:0.62
                                               green:0.97
                                                blue:1.0
                                               alpha:1.0]];
  title.alignment = NSTextAlignmentCenter;
  [authPanel addSubview:title];

  NSTextField *hint =
      [self makeLabelWithFrame:NSMakeRect(48, 340, 454, 24)
                          text:@"Inicia sesion o crea un usuario nuevo"
                          font:[self fontWithName:@"Avenir Next Medium"
                                             size:16
                                   fallbackWeight:NSFontWeightMedium]
                         color:[NSColor colorWithRed:0.68
                                               green:0.94
                                                blue:0.86
                                               alpha:0.95]];
  hint.alignment = NSTextAlignmentCenter;
  [authPanel addSubview:hint];

  loginUserField_ = [self makeInputWithFrame:NSMakeRect(70, 262, 410, 44)
                                 placeholder:@"Usuario"
                                      secure:NO];
  [authPanel addSubview:loginUserField_];

  loginPasswordField_ =
      (NSSecureTextField *)[self makeInputWithFrame:NSMakeRect(70, 206, 368, 44)
                                        placeholder:@"Password"
                                             secure:YES];
  [authPanel addSubview:loginPasswordField_];

  loginPasswordPlainField_ =
      [self makeInputWithFrame:NSMakeRect(70, 206, 368, 44)
                   placeholder:@"Password"
                        secure:NO];
  loginPasswordPlainField_.hidden = YES;
  [authPanel addSubview:loginPasswordPlainField_];

  passwordEyeButton_ =
      [[NSButton alloc] initWithFrame:NSMakeRect(444, 212, 36, 32)];
  passwordEyeButton_.target = self;
  passwordEyeButton_.action = @selector(togglePasswordVisibility:);
  passwordEyeButton_.bordered = NO;
  passwordEyeButton_.wantsLayer = YES;
  passwordEyeButton_.layer.cornerRadius = 8.0;
  passwordEyeButton_.layer.backgroundColor =
      [NSColor colorWithRed:0.05 green:0.2 blue:0.33 alpha:1.0].CGColor;
  passwordEyeButton_.layer.borderWidth = 1.0;
  passwordEyeButton_.layer.borderColor =
      [NSColor colorWithRed:0.2 green:0.86 blue:0.95 alpha:0.75].CGColor;
  passwordEyeButton_.contentTintColor = [NSColor colorWithRed:0.78
                                                        green:0.97
                                                         blue:0.99
                                                        alpha:1.0];
  [self updatePasswordEyeIcon];
  [authPanel addSubview:passwordEyeButton_];

  NSButton *loginButton =
      [self makeCyberButtonWithFrame:NSMakeRect(70, 144, 200, 40)
                               title:@"Iniciar sesion"
                              action:@selector(handleLogin:)];
  [authPanel addSubview:loginButton];

  NSButton *registerButton =
      [self makeCyberButtonWithFrame:NSMakeRect(280, 144, 200, 40)
                               title:@"Crear usuario"
                              action:@selector(handleCreateUser:)];
  [authPanel addSubview:registerButton];

  authStatusLabel_ =
      [self makeLabelWithFrame:NSMakeRect(50, 92, 450, 34)
                          text:@""
                          font:[self fontWithName:@"Menlo-Regular"
                                             size:14
                                   fallbackWeight:NSFontWeightRegular]
                         color:[NSColor colorWithRed:0.95
                                               green:0.55
                                                blue:0.52
                                               alpha:1.0]];
  authStatusLabel_.alignment = NSTextAlignmentCenter;
  [authPanel addSubview:authStatusLabel_];

  NSTextField *rules =
      [self makeLabelWithFrame:NSMakeRect(52, 52, 446, 34)
                          text:@"Usuario: 3-16 caracteres (letras, numeros, _, "
                               @"-). Password: minimo 4."
                          font:[self fontWithName:@"Avenir Next Regular"
                                             size:12
                                   fallbackWeight:NSFontWeightRegular]
                         color:[NSColor colorWithRed:0.63
                                               green:0.86
                                                blue:0.95
                                               alpha:0.9]];
  rules.alignment = NSTextAlignmentCenter;
  [authPanel addSubview:rules];

  [window_ setContentView:root];

  if (message.length > 0) {
    [self setAuthStatus:message
                  color:(color
                             ?: [NSColor colorWithRed:0.95
                                                green:0.55
                                                 blue:0.52
                                                alpha:1.0])];
  }
}

- (void)showMainMenu {
  CyberBackgroundView *root =
      [[CyberBackgroundView alloc] initWithFrame:window_.contentView.bounds];

  NSView *menuPanel = [self makePanelWithFrame:NSMakeRect(270, 160, 640, 500)];
  [root addSubview:menuPanel];

  NSTextField *title =
      [self makeLabelWithFrame:NSMakeRect(40, 406, 560, 64)
                          text:@"Menu Principal"
                          font:[self fontWithName:@"Avenir Next Condensed Bold"
                                             size:52
                                   fallbackWeight:NSFontWeightBold]
                         color:[NSColor colorWithRed:0.58
                                               green:0.98
                                                blue:1.0
                                               alpha:1.0]];
  title.alignment = NSTextAlignmentCenter;
  [menuPanel addSubview:title];

  NSInteger totalPoints = [self totalPointsForUser:currentUser_];
  NSTextField *welcome = [self
      makeLabelWithFrame:NSMakeRect(50, 346, 540, 30)
                    text:[NSString
                             stringWithFormat:
                                 @"Usuario activo: %@  |  Puntos totales: %ld",
                                 currentUser_ ?: @"-", (long)totalPoints]
                    font:[self fontWithName:@"Menlo-Bold"
                                       size:18
                             fallbackWeight:NSFontWeightSemibold]
                   color:[NSColor colorWithRed:0.75
                                         green:0.97
                                          blue:0.84
                                         alpha:1.0]];
  welcome.alignment = NSTextAlignmentCenter;
  [menuPanel addSubview:welcome];

  NSTextField *difficultyTitle =
      [self makeLabelWithFrame:NSMakeRect(150, 286, 140, 30)
                          text:@"Dificultad"
                          font:[self fontWithName:@"Avenir Next Demi Bold"
                                             size:18
                                   fallbackWeight:NSFontWeightSemibold]
                         color:[NSColor colorWithRed:0.74
                                               green:0.92
                                                blue:1.0
                                               alpha:1.0]];
  [menuPanel addSubview:difficultyTitle];

  menuDifficultyPopup_ =
      [[NSPopUpButton alloc] initWithFrame:NSMakeRect(295, 286, 190, 32)
                                 pullsDown:NO];
  [menuDifficultyPopup_ addItemsWithTitles:@[ @"Facil", @"Media", @"Dificil" ]];
  [self stylePopup:menuDifficultyPopup_];
  switch (selectedDifficulty_) {
  case Difficulty::Easy:
    [menuDifficultyPopup_ selectItemAtIndex:0];
    break;
  case Difficulty::Medium:
    [menuDifficultyPopup_ selectItemAtIndex:1];
    break;
  case Difficulty::Hard:
    [menuDifficultyPopup_ selectItemAtIndex:2];
    break;
  }
  [menuPanel addSubview:menuDifficultyPopup_];

  NSButton *playButton =
      [self makeCyberButtonWithFrame:NSMakeRect(190, 220, 260, 44)
                               title:@"Jugar Sudoku"
                              action:@selector(startGameFromMenu:)];
  [menuPanel addSubview:playButton];

  NSButton *logoutButton =
      [self makeCyberButtonWithFrame:NSMakeRect(190, 166, 260, 44)
                               title:@"Cerrar sesion"
                              action:@selector(handleLogout:)];
  [menuPanel addSubview:logoutButton];

  NSTextField *info =
      [self makeLabelWithFrame:NSMakeRect(60, 128, 520, 30)
                          text:@"Top Operators: mejores jugadores ordenados "
                               @"por puntuacion"
                          font:[self fontWithName:@"Avenir Next Regular"
                                             size:14
                                   fallbackWeight:NSFontWeightRegular]
                         color:[NSColor colorWithRed:0.66
                                               green:0.88
                                                blue:0.96
                                               alpha:0.9]];
  info.alignment = NSTextAlignmentCenter;
  [menuPanel addSubview:info];

  NSTextField *rankingTitle =
      [self makeLabelWithFrame:NSMakeRect(80, 102, 480, 22)
                          text:@"Top Operators"
                          font:[self fontWithName:@"Avenir Next Demi Bold"
                                             size:17
                                   fallbackWeight:NSFontWeightSemibold]
                         color:[NSColor colorWithRed:0.62
                                               green:0.98
                                                blue:0.99
                                               alpha:1.0]];
  rankingTitle.alignment = NSTextAlignmentCenter;
  [menuPanel addSubview:rankingTitle];

  NSArray<NSString *> *ranking = [self sortedUsersByScore];
  if (ranking.count == 0) {
    NSTextField *empty =
        [self makeLabelWithFrame:NSMakeRect(80, 70, 480, 20)
                            text:@"Aun no hay jugadores registrados"
                            font:[self fontWithName:@"Menlo-Regular"
                                               size:13
                                     fallbackWeight:NSFontWeightRegular]
                           color:[NSColor colorWithRed:0.58
                                                 green:0.82
                                                  blue:0.9
                                                 alpha:0.88]];
    empty.alignment = NSTextAlignmentCenter;
    [menuPanel addSubview:empty];
  } else {
    NSInteger topCount = MIN((NSInteger)ranking.count, 5);
    for (NSInteger i = 0; i < topCount; ++i) {
      NSString *username = ranking[(NSUInteger)i];
      NSInteger score = [self totalPointsForUser:username];
      BOOL current = [username isEqualToString:currentUser_];

      NSTextField *row = [self
          makeLabelWithFrame:NSMakeRect(120, 72 - i * 18, 400, 20)
                        text:[NSString stringWithFormat:@"%ld. %@  -  %ld pts",
                                                        (long)(i + 1), username,
                                                        (long)score]
                        font:[self fontWithName:@"Menlo-Regular"
                                           size:13
                                 fallbackWeight:NSFontWeightRegular]
                       color:(current ? [NSColor colorWithRed:0.57
                                                        green:0.98
                                                         blue:0.77
                                                        alpha:1.0]
                                      : [NSColor colorWithRed:0.73
                                                        green:0.93
                                                         blue:0.99
                                                        alpha:0.94])];
      row.alignment = NSTextAlignmentCenter;
      [menuPanel addSubview:row];
    }
  }

  [window_ setContentView:root];
}

- (void)showGameScreen {
  [self stopGameTimer];
  selectedCellIndex_ = -1;
  gameLocked_ = NO;

  CyberBackgroundView *root =
      [[CyberBackgroundView alloc] initWithFrame:window_.contentView.bounds];

  NSTextField *heading =
      [self makeLabelWithFrame:NSMakeRect(36, 773, 430, 42)
                          text:@"Sudoku Cyber Grid"
                          font:[self fontWithName:@"Avenir Next Condensed Bold"
                                             size:38
                                   fallbackWeight:NSFontWeightBold]
                         color:[NSColor colorWithRed:0.62
                                               green:0.98
                                                blue:1.0
                                               alpha:1.0]];
  [root addSubview:heading];

  NSTextField *headingUser =
      [self makeLabelWithFrame:NSMakeRect(490, 780, 650, 26)
                          text:[NSString stringWithFormat:@"Usuario: %@",
                                                          currentUser_ ?: @"-"]
                          font:[self fontWithName:@"Menlo-Bold"
                                             size:15
                                   fallbackWeight:NSFontWeightSemibold]
                         color:[NSColor colorWithRed:0.72
                                               green:0.96
                                                blue:0.84
                                               alpha:1.0]];
  headingUser.alignment = NSTextAlignmentRight;
  [root addSubview:headingUser];

  NSView *boardPanel = [self makePanelWithFrame:NSMakeRect(38, 56, 720, 700)];
  [root addSubview:boardPanel];

  NSView *userPanel = [self makePanelWithFrame:NSMakeRect(790, 500, 350, 256)];
  [root addSubview:userPanel];

  NSView *controlPanel =
      [self makePanelWithFrame:NSMakeRect(790, 56, 350, 422)];
  [root addSubview:controlPanel];

  NSTextField *userPanelTitle =
      [self makeLabelWithFrame:NSMakeRect(18, 214, 300, 30)
                          text:@"Panel de Usuario"
                          font:[self fontWithName:@"Avenir Next Demi Bold"
                                             size:24
                                   fallbackWeight:NSFontWeightBold]
                         color:[NSColor colorWithRed:0.61
                                               green:0.98
                                                blue:0.99
                                               alpha:1.0]];
  [userPanel addSubview:userPanelTitle];

  userValueLabel_ =
      [self makeLabelWithFrame:NSMakeRect(18, 178, 314, 24)
                          text:@"Usuario: -"
                          font:[self fontWithName:@"Menlo-Regular"
                                             size:15
                                   fallbackWeight:NSFontWeightRegular]
                         color:[NSColor colorWithRed:0.76
                                               green:0.93
                                                blue:1.0
                                               alpha:1.0]];
  [userPanel addSubview:userValueLabel_];

  difficultyValueLabel_ =
      [self makeLabelWithFrame:NSMakeRect(18, 148, 314, 24)
                          text:@"Dificultad: -"
                          font:[self fontWithName:@"Menlo-Regular"
                                             size:15
                                   fallbackWeight:NSFontWeightRegular]
                         color:[NSColor colorWithRed:0.76
                                               green:0.93
                                                blue:1.0
                                               alpha:1.0]];
  [userPanel addSubview:difficultyValueLabel_];

  movesValueLabel_ =
      [self makeLabelWithFrame:NSMakeRect(18, 118, 314, 24)
                          text:@"Movimientos: 0"
                          font:[self fontWithName:@"Menlo-Regular"
                                             size:15
                                   fallbackWeight:NSFontWeightRegular]
                         color:[NSColor colorWithRed:0.76
                                               green:0.93
                                                blue:1.0
                                               alpha:1.0]];
  [userPanel addSubview:movesValueLabel_];

  timeValueLabel_ =
      [self makeLabelWithFrame:NSMakeRect(18, 88, 314, 24)
                          text:@"Tiempo: 00:00"
                          font:[self fontWithName:@"Menlo-Regular"
                                             size:15
                                   fallbackWeight:NSFontWeightRegular]
                         color:[NSColor colorWithRed:0.76
                                               green:0.93
                                                blue:1.0
                                               alpha:1.0]];
  [userPanel addSubview:timeValueLabel_];

  livesValueLabel_ =
      [self makeLabelWithFrame:NSMakeRect(18, 58, 314, 24)
                          text:@"Vidas: 0"
                          font:[self fontWithName:@"Menlo-Regular"
                                             size:15
                                   fallbackWeight:NSFontWeightRegular]
                         color:[NSColor colorWithRed:0.98
                                               green:0.66
                                                blue:0.58
                                               alpha:1.0]];
  [userPanel addSubview:livesValueLabel_];

  pointsValueLabel_ =
      [self makeLabelWithFrame:NSMakeRect(18, 28, 314, 24)
                          text:@"Puntos: 0"
                          font:[self fontWithName:@"Menlo-Regular"
                                             size:15
                                   fallbackWeight:NSFontWeightRegular]
                         color:[NSColor colorWithRed:0.58
                                               green:0.98
                                                blue:0.78
                                               alpha:1.0]];
  [userPanel addSubview:pointsValueLabel_];

  NSTextField *controlTitle =
      [self makeLabelWithFrame:NSMakeRect(18, 384, 300, 30)
                          text:@"Panel de Controles"
                          font:[self fontWithName:@"Avenir Next Demi Bold"
                                             size:24
                                   fallbackWeight:NSFontWeightBold]
                         color:[NSColor colorWithRed:0.61
                                               green:0.98
                                                blue:0.99
                                               alpha:1.0]];
  [controlPanel addSubview:controlTitle];

  gameDifficultyPopup_ =
      [[NSPopUpButton alloc] initWithFrame:NSMakeRect(20, 344, 140, 30)
                                 pullsDown:NO];
  [gameDifficultyPopup_ addItemsWithTitles:@[ @"Facil", @"Media", @"Dificil" ]];
  [self stylePopup:gameDifficultyPopup_];
  switch (selectedDifficulty_) {
  case Difficulty::Easy:
    [gameDifficultyPopup_ selectItemAtIndex:0];
    break;
  case Difficulty::Medium:
    [gameDifficultyPopup_ selectItemAtIndex:1];
    break;
  case Difficulty::Hard:
    [gameDifficultyPopup_ selectItemAtIndex:2];
    break;
  }
  gameDifficultyPopup_.target = self;
  gameDifficultyPopup_.action = @selector(startNewGame:);
  [controlPanel addSubview:gameDifficultyPopup_];

  NSButton *newGameButton =
      [self makeCyberButtonWithFrame:NSMakeRect(170, 340, 160, 34)
                               title:@"Nueva partida"
                              action:@selector(startNewGame:)];
  [controlPanel addSubview:newGameButton];

  NSButton *checkButton =
      [self makeCyberButtonWithFrame:NSMakeRect(20, 294, 150, 34)
                               title:@"Comprobar"
                              action:@selector(checkBoard:)];
  [controlPanel addSubview:checkButton];

  NSButton *solveButton =
      [self makeCyberButtonWithFrame:NSMakeRect(180, 294, 150, 34)
                               title:@"Resolver"
                              action:@selector(solveBoard:)];
  [controlPanel addSubview:solveButton];

  NSButton *clearButton =
      [self makeCyberButtonWithFrame:NSMakeRect(20, 246, 150, 34)
                               title:@"Borrar casilla"
                              action:@selector(clearSelectedCell:)];
  [controlPanel addSubview:clearButton];

  NSButton *menuButton =
      [self makeCyberButtonWithFrame:NSMakeRect(180, 246, 150, 34)
                               title:@"Menu principal"
                              action:@selector(backToMenu:)];
  [controlPanel addSubview:menuButton];

  NSTextField *padTitle =
      [self makeLabelWithFrame:NSMakeRect(20, 210, 310, 24)
                          text:@"Numeros (mouse):"
                          font:[self fontWithName:@"Avenir Next Medium"
                                             size:14
                                   fallbackWeight:NSFontWeightMedium]
                         color:[NSColor colorWithRed:0.7
                                               green:0.93
                                                blue:1.0
                                               alpha:1.0]];
  [controlPanel addSubview:padTitle];

  for (int i = 0; i < 9; ++i) {
    int row = i / 3;
    int col = i % 3;
    CGFloat x = 26.0 + col * 104.0;
    CGFloat y = 166.0 - row * 50.0;

    NSButton *numberButton =
        [self makeCyberButtonWithFrame:NSMakeRect(x, y, 92, 42)
                                 title:[NSString stringWithFormat:@"%d", i + 1]
                                action:@selector(selectNumberFromPad:)];
    numberButton.tag = i + 1;
    [controlPanel addSubview:numberButton];
  }

  gameStatusLabel_ =
      [self makeLabelWithFrame:NSMakeRect(20, 8, 310, 42)
                          text:@"Listo para jugar"
                          font:[self fontWithName:@"Avenir Next Medium"
                                             size:14
                                   fallbackWeight:NSFontWeightMedium]
                         color:[NSColor colorWithRed:0.62
                                               green:0.95
                                                blue:0.99
                                               alpha:1.0]];
  gameStatusLabel_.lineBreakMode = NSLineBreakByWordWrapping;
  [controlPanel addSubview:gameStatusLabel_];

  cells_ = [[NSMutableArray alloc] initWithCapacity:81];

  const CGFloat cellSize = 66.0;
  const CGFloat blockGap = 10.0;
  const CGFloat boardSize = 9 * cellSize + 2 * blockGap;
  const CGFloat originX = (boardPanel.frame.size.width - boardSize) * 0.5;
  const CGFloat originY = (boardPanel.frame.size.height - boardSize) * 0.5;

  for (int r = 0; r < 9; ++r) {
    for (int c = 0; c < 9; ++c) {
      CGFloat x = originX + c * cellSize + (c / 3) * blockGap;
      CGFloat y = originY + (8 - r) * cellSize + ((8 - r) / 3) * blockGap;

      NSTextField *cell = [[NSTextField alloc]
          initWithFrame:NSMakeRect(x, y, cellSize - 6, cellSize - 6)];
      [cell setCell:[[CenteredBoardTextFieldCell alloc] initTextCell:@""]];
      cell.alignment = NSTextAlignmentCenter;
      cell.font = [self fontWithName:@"Menlo-Bold"
                                size:28
                      fallbackWeight:NSFontWeightBold];
      cell.delegate = self;
      cell.tag = r * 9 + c;
      [cell.cell setUsesSingleLineMode:YES];
      [cell.cell setEditable:YES];
      [cell.cell setSelectable:YES];
      [cell.cell setLineBreakMode:NSLineBreakByClipping];
      [cell.cell setWraps:NO];
      [cell.cell setScrollable:YES];
      cell.drawsBackground = NO;
      cell.bordered = NO;
      cell.focusRingType = NSFocusRingTypeNone;
      cell.wantsLayer = YES;
      cell.layer.cornerRadius = 9.0;
      cell.layer.borderWidth = 1.4;

      NSClickGestureRecognizer *click = [[NSClickGestureRecognizer alloc]
          initWithTarget:self
                  action:@selector(handleCellClick:)];
      click.buttonMask = 0x1;
      [cell addGestureRecognizer:click];

      [boardPanel addSubview:cell];
      [cells_ addObject:cell];
    }
  }

  [window_ setContentView:root];
  [self startNewGame:nil];
}

- (Difficulty)difficultyFromPopupIndex:(NSInteger)idx {
  if (idx == 0) {
    return Difficulty::Easy;
  }
  if (idx == 2) {
    return Difficulty::Hard;
  }
  return Difficulty::Medium;
}

- (NSString *)authValidationErrorForUser:(NSString *)username
                                password:(NSString *)password {
  if (username.length < 3 || username.length > 16) {
    return @"El usuario debe tener entre 3 y 16 caracteres";
  }

  for (NSUInteger i = 0; i < username.length; ++i) {
    if (!isValidUserCharacter([username characterAtIndex:i])) {
      return @"Usuario invalido: solo letras, numeros, _ o -";
    }
  }

  if (password.length < 4) {
    return @"La password debe tener minimo 4 caracteres";
  }

  return nil;
}

- (NSString *)currentPasswordText {
  if (passwordVisible_) {
    return loginPasswordPlainField_.stringValue ?: @"";
  }
  return loginPasswordField_.stringValue ?: @"";
}

- (void)setAuthStatus:(NSString *)text color:(NSColor *)color {
  if (!authStatusLabel_) {
    return;
  }

  authStatusLabel_.stringValue = text ?: @"";
  authStatusLabel_.textColor =
      color ?: [NSColor colorWithRed:0.95 green:0.55 blue:0.52 alpha:1.0];
}

- (void)updatePasswordEyeIcon {
  if (!passwordEyeButton_) {
    return;
  }

  if (@available(macOS 11.0, *)) {
    NSString *symbolName = passwordVisible_ ? @"eye.slash" : @"eye";
    NSImage *icon =
        [NSImage imageWithSystemSymbolName:symbolName
                  accessibilityDescription:@"toggle password visibility"];
    if (icon) {
      icon.size = NSMakeSize(15.0, 15.0);
      passwordEyeButton_.image = icon;
      passwordEyeButton_.title = @"";
      return;
    }
  }

  passwordEyeButton_.title = passwordVisible_ ? @"Ocultar" : @"Ver";
}

- (void)togglePasswordVisibility:(id)sender {
  (void)sender;

  NSString *currentPassword = [self currentPasswordText];
  passwordVisible_ = !passwordVisible_;

  if (passwordVisible_) {
    loginPasswordPlainField_.stringValue = currentPassword;
    loginPasswordPlainField_.hidden = NO;
    loginPasswordField_.hidden = YES;
    [window_ makeFirstResponder:loginPasswordPlainField_];
  } else {
    loginPasswordField_.stringValue = currentPassword;
    loginPasswordField_.hidden = NO;
    loginPasswordPlainField_.hidden = YES;
    [window_ makeFirstResponder:loginPasswordField_];
  }

  [self updatePasswordEyeIcon];
}

- (void)handleLogin:(id)sender {
  (void)sender;

  NSString *username = trimmed(loginUserField_.stringValue ?: @"");
  NSString *password = [self currentPasswordText];
  NSString *error = [self authValidationErrorForUser:username
                                            password:password];
  if (error) {
    [self setAuthStatus:error
                  color:[NSColor colorWithRed:0.95
                                        green:0.55
                                         blue:0.52
                                        alpha:1.0]];
    return;
  }

  NSString *stored = users_[username];
  if (!stored) {
    [self setAuthStatus:@"Usuario no encontrado"
                  color:[NSColor colorWithRed:0.95
                                        green:0.55
                                         blue:0.52
                                        alpha:1.0]];
    return;
  }

  if (![stored isEqualToString:passwordHash(password)]) {
    [self setAuthStatus:@"Password incorrecta"
                  color:[NSColor colorWithRed:0.95
                                        green:0.55
                                         blue:0.52
                                        alpha:1.0]];
    return;
  }

  if (userPoints_[username] == nil) {
    userPoints_[username] = @0;
    [self saveUsers];
  }

  currentUser_ = [username copy];
  [self showMainMenu];
}

- (void)handleCreateUser:(id)sender {
  (void)sender;

  NSString *username = trimmed(loginUserField_.stringValue ?: @"");
  NSString *password = [self currentPasswordText];
  NSString *error = [self authValidationErrorForUser:username
                                            password:password];
  if (error) {
    [self setAuthStatus:error
                  color:[NSColor colorWithRed:0.95
                                        green:0.55
                                         blue:0.52
                                        alpha:1.0]];
    return;
  }

  if (users_[username] != nil) {
    [self setAuthStatus:@"Ese usuario ya existe"
                  color:[NSColor colorWithRed:0.95
                                        green:0.55
                                         blue:0.52
                                        alpha:1.0]];
    return;
  }

  users_[username] = passwordHash(password);
  userPoints_[username] = @0;
  [self saveUsers];
  [self setAuthStatus:@"Usuario creado correctamente. Ya puedes iniciar sesion."
                color:[NSColor colorWithRed:0.53
                                      green:0.98
                                       blue:0.75
                                      alpha:1.0]];
}

- (void)handleLogout:(id)sender {
  (void)sender;
  currentUser_ = nil;
  [self showAuthScreenWithMessage:@"Sesion cerrada"
                            color:[NSColor colorWithRed:0.62
                                                  green:0.95
                                                   blue:0.99
                                                  alpha:1.0]];
}

- (void)startGameFromMenu:(id)sender {
  (void)sender;
  selectedDifficulty_ = [self
      difficultyFromPopupIndex:[menuDifficultyPopup_ indexOfSelectedItem]];
  [self showGameScreen];
}

- (void)setGameStatus:(NSString *)text color:(NSColor *)color {
  if (!gameStatusLabel_) {
    return;
  }

  gameStatusLabel_.stringValue = text ?: @"";
  gameStatusLabel_.textColor =
      color ?: [NSColor colorWithRed:0.62 green:0.95 blue:0.99 alpha:1.0];
}

- (void)startGameTimer {
  [self stopGameTimer];
  gameStartDate_ = [NSDate date];
  gameTimer_ = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                target:self
                                              selector:@selector(updateTimer:)
                                              userInfo:nil
                                               repeats:YES];
}

- (void)stopGameTimer {
  if (gameTimer_) {
    [gameTimer_ invalidate];
    gameTimer_ = nil;
  }
}

- (void)updateTimer:(NSTimer *)timer {
  (void)timer;
  if (!timeValueLabel_ || !gameStartDate_) {
    return;
  }

  NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:gameStartDate_];
  NSInteger total = (NSInteger)elapsed;
  NSInteger minutes = total / 60;
  NSInteger seconds = total % 60;
  timeValueLabel_.stringValue = [NSString
      stringWithFormat:@"Tiempo: %02ld:%02ld", (long)minutes, (long)seconds];
}

- (void)refreshUserPanel {
  if (!userValueLabel_ || !difficultyValueLabel_ || !movesValueLabel_ ||
      !timeValueLabel_ || !livesValueLabel_ || !pointsValueLabel_) {
    return;
  }

  userValueLabel_.stringValue =
      [NSString stringWithFormat:@"Usuario: %@", currentUser_ ?: @"-"];
  difficultyValueLabel_.stringValue = [NSString
      stringWithFormat:@"Dificultad: %@", difficultyLabel(selectedDifficulty_)];
  movesValueLabel_.stringValue =
      [NSString stringWithFormat:@"Movimientos: %ld", (long)movesCount_];
  livesValueLabel_.stringValue =
      [NSString stringWithFormat:@"Vidas: %ld", (long)livesCount_];
  pointsValueLabel_.stringValue =
      [NSString stringWithFormat:@"Puntos: %ld", (long)pointsCount_];
  [self updateTimer:nil];
}

- (NSInteger)initialLivesForDifficulty:(Difficulty)difficulty {
  switch (difficulty) {
  case Difficulty::Easy:
    return 5;
  case Difficulty::Medium:
    return 4;
  case Difficulty::Hard:
    return 3;
  }

  return 4;
}

- (void)startNewGame:(id)sender {
  (void)sender;

  if (gameDifficultyPopup_) {
    selectedDifficulty_ = [self
        difficultyFromPopupIndex:[gameDifficultyPopup_ indexOfSelectedItem]];
  }

  selectedCellIndex_ = -1;
  movesCount_ = 0;
  pointsCount_ = 0;
  livesCount_ = [self initialLivesForDifficulty:selectedDifficulty_];
  gameLocked_ = NO;
  for (int i = 0; i < 9; ++i) {
    blockCompleted_[i] = NO;
  }

  engine_.newGame(selectedDifficulty_);
  [self startGameTimer];
  [self refreshAllCells];
  [self refreshUserPanel];
  [self setGameStatus:[NSString
                          stringWithFormat:@"Nueva partida (%@). Vidas: %ld",
                                           difficultyLabel(selectedDifficulty_),
                                           (long)livesCount_]
                color:[NSColor colorWithRed:0.57
                                      green:0.97
                                       blue:0.76
                                      alpha:1.0]];
}

- (void)checkBoard:(id)sender {
  (void)sender;

  if (gameLocked_) {
    if (engine_.isComplete()) {
      [self setGameStatus:@"Partida finalizada: victoria"
                    color:[NSColor colorWithRed:0.55
                                          green:0.98
                                           blue:0.72
                                          alpha:1.0]];
    } else {
      [self setGameStatus:@"Partida finalizada: game over"
                    color:[NSColor colorWithRed:0.98
                                          green:0.56
                                           blue:0.5
                                          alpha:1.0]];
    }
    return;
  }

  if (engine_.isComplete()) {
    [self triggerVictory];
    return;
  }

  int wrong = engine_.wrongCellCount();
  int empty = engine_.emptyCellCount();
  if (wrong > 0) {
    [self
        setGameStatus:[NSString stringWithFormat:@"Hay %d casillas incorrectas",
                                                 wrong]
                color:[NSColor colorWithRed:0.98
                                      green:0.56
                                       blue:0.5
                                      alpha:1.0]];
    return;
  }

  NSInteger filled = 81 - empty;
  [self setGameStatus:[NSString
                          stringWithFormat:@"Avance correcto: %ld/81 celdas",
                                           (long)filled]
                color:[NSColor colorWithRed:0.62
                                      green:0.95
                                       blue:0.99
                                      alpha:1.0]];
}

- (void)solveBoard:(id)sender {
  (void)sender;

  if (gameLocked_) {
    return;
  }

  engine_.revealSolution();
  gameLocked_ = YES;
  [self stopGameTimer];
  [self refreshAllCells];
  [self setGameStatus:@"Tablero resuelto manualmente"
                color:[NSColor colorWithRed:0.62
                                      green:0.95
                                       blue:0.99
                                      alpha:1.0]];
}

- (void)clearSelectedCell:(id)sender {
  (void)sender;
  [self applyValueToSelectedCell:0];
}

- (void)backToMenu:(id)sender {
  (void)sender;
  [self stopGameTimer];
  [self showMainMenu];
}

- (void)refreshAllCells {
  for (int r = 0; r < 9; ++r) {
    for (int c = 0; c < 9; ++c) {
      [self refreshCellAtRow:r col:c];
    }
  }
}

- (void)refreshCellAtRow:(int)row col:(int)col {
  if (!cells_ || cells_.count != 81) {
    return;
  }

  int idx = row * 9 + col;
  NSTextField *cell = cells_[idx];
  int value = engine_.valueAt(row, col);

  if (value == 0) {
    cell.stringValue = @"";
  } else {
    cell.stringValue = [NSString stringWithFormat:@"%d", value];
  }

  BOOL fixed = engine_.isFixed(row, col);
  BOOL selected = (selectedCellIndex_ == idx);

  int selectedRow = -1;
  int selectedCol = -1;
  if (selectedCellIndex_ >= 0) {
    selectedRow = (int)(selectedCellIndex_ / 9);
    selectedCol = (int)(selectedCellIndex_ % 9);
  }
  BOOL inSameAxis = (selectedCellIndex_ >= 0) && !selected &&
                    (row == selectedRow || col == selectedCol);

  cell.editable = !fixed && !gameLocked_;
  cell.selectable = YES;

  if (selected) {
    cell.layer.backgroundColor =
        [NSColor colorWithRed:0.11 green:0.29 blue:0.44 alpha:1.0].CGColor;
    cell.textColor = [NSColor colorWithRed:0.88 green:0.99 blue:1.0 alpha:1.0];
    cell.layer.borderColor =
        [NSColor colorWithRed:0.34 green:1.0 blue:0.88 alpha:1.0].CGColor;
    cell.layer.borderWidth = 2.8;
    return;
  }

  int blockIdx = (row / 3) * 3 + (col / 3);
  BOOL isBlockComplete = blockCompleted_[blockIdx];

  if (fixed) {
    cell.textColor = [NSColor colorWithRed:0.58 green:0.97 blue:0.84 alpha:1.0];
    if (isBlockComplete) {
      cell.layer.backgroundColor =
          [NSColor colorWithRed:0.0 green:0.4 blue:0.4 alpha:0.3].CGColor;
    } else {
      cell.layer.backgroundColor = (inSameAxis ? [NSColor colorWithRed:0.08
                                                                 green:0.17
                                                                  blue:0.28
                                                                 alpha:1.0]
                                               : [NSColor colorWithRed:0.06
                                                                 green:0.14
                                                                  blue:0.23
                                                                 alpha:1.0])
                                       .CGColor;
    }
  } else {
    cell.textColor = [NSColor colorWithRed:0.78 green:0.95 blue:1.0 alpha:1.0];
    if (isBlockComplete) {
      cell.layer.backgroundColor =
          [NSColor colorWithRed:0.0 green:0.4 blue:0.4 alpha:0.4].CGColor;
    } else {
      cell.layer.backgroundColor = (inSameAxis ? [NSColor colorWithRed:0.07
                                                                 green:0.16
                                                                  blue:0.24
                                                                 alpha:1.0]
                                               : [NSColor colorWithRed:0.04
                                                                 green:0.11
                                                                  blue:0.19
                                                                 alpha:1.0])
                                       .CGColor;
    }
  }

  if (isBlockComplete) {
    cell.layer.borderColor =
        [NSColor colorWithRed:0.2 green:0.9 blue:0.8 alpha:1.0].CGColor;
    cell.layer.borderWidth = 1.8;
  } else {
    cell.layer.borderColor =
        [NSColor colorWithRed:0.16 green:0.76 blue:0.92 alpha:0.7].CGColor;
    cell.layer.borderWidth = 1.2;
  }
}

- (void)handleCellClick:(NSClickGestureRecognizer *)recognizer {
  if (recognizer.state != NSGestureRecognizerStateEnded) {
    return;
  }

  NSTextField *cell = (NSTextField *)recognizer.view;
  if (![cell isKindOfClass:[NSTextField class]]) {
    return;
  }

  NSInteger idx = cell.tag;
  if (idx < 0 || idx >= 81) {
    return;
  }

  [self selectCellAtIndex:idx];

  int row = (int)(idx / 9);
  int col = (int)(idx % 9);
  if (!gameLocked_ && !engine_.isFixed(row, col)) {
    [window_ makeFirstResponder:cell];
  }
}

- (void)selectCellAtIndex:(NSInteger)index {
  if (index < 0 || index >= 81) {
    return;
  }

  selectedCellIndex_ = index;
  [self refreshAllCells];
  [self setGameStatus:
            [NSString
                stringWithFormat:@"Casilla seleccionada: fila %ld, columna %ld",
                                 (long)(index / 9 + 1), (long)(index % 9 + 1)]
                color:[NSColor colorWithRed:0.62
                                      green:0.95
                                       blue:0.99
                                      alpha:1.0]];
}

- (void)controlTextDidBeginEditing:(NSNotification *)notification {
  NSTextField *field = (NSTextField *)notification.object;
  if (![field isKindOfClass:[NSTextField class]]) {
    return;
  }

  int idx = (int)field.tag;
  if (idx < 0 || idx >= 81) {
    return;
  }

  [self selectCellAtIndex:idx];
}

- (void)controlTextDidChange:(NSNotification *)notification {
  NSTextField *field = (NSTextField *)notification.object;
  if (![field isKindOfClass:[NSTextField class]]) {
    return;
  }

  if (gameLocked_) {
    return;
  }

  int idx = (int)field.tag;
  if (idx < 0 || idx >= 81) {
    return;
  }

  NSString *raw = trimmed(field.stringValue ?: @"");
  if (raw.length == 0) {
    field.stringValue = @"";
    return;
  }

  unichar accepted = 0;
  for (NSInteger i = (NSInteger)raw.length - 1; i >= 0; --i) {
    unichar ch = [raw characterAtIndex:(NSUInteger)i];
    if (ch >= '1' && ch <= '9') {
      accepted = ch;
      break;
    }
  }

  if (accepted == 0) {
    field.stringValue = @"";
  } else {
    field.stringValue = [NSString stringWithFormat:@"%c", (char)accepted];
  }
}

- (void)controlTextDidEndEditing:(NSNotification *)notification {
  NSTextField *field = (NSTextField *)notification.object;
  if (![field isKindOfClass:[NSTextField class]]) {
    return;
  }

  [self commitCellValue:field];
}

- (void)selectNumberFromPad:(id)sender {
  NSButton *button = (NSButton *)sender;
  if (![button isKindOfClass:[NSButton class]]) {
    return;
  }

  [self applyValueToSelectedCell:(int)button.tag];
}

- (void)applyValueToSelectedCell:(int)value {
  if (selectedCellIndex_ < 0 || selectedCellIndex_ >= 81) {
    [self setGameStatus:@"Selecciona una casilla primero"
                  color:[NSColor colorWithRed:0.96
                                        green:0.7
                                         blue:0.44
                                        alpha:1.0]];
    return;
  }

  int row = (int)(selectedCellIndex_ / 9);
  int col = (int)(selectedCellIndex_ % 9);
  [self applyValue:value toCellAtRow:row col:col];
}

- (void)checkBlocksCompletion {
  for (int b = 0; b < 9; ++b) {
    if (blockCompleted_[b]) {
      continue;
    }

    int startRow = (b / 3) * 3;
    int startCol = (b % 3) * 3;

    BOOL isComplete = YES;
    for (int r = startRow; r < startRow + 3; ++r) {
      for (int c = startCol; c < startCol + 3; ++c) {
        if (engine_.valueAt(r, c) == 0) {
          isComplete = NO;
          break;
        }
      }
      if (!isComplete) {
        break;
      }
    }

    if (isComplete) {
      blockCompleted_[b] = YES;

      for (int r = startRow; r < startRow + 3; ++r) {
        for (int c = startCol; c < startCol + 3; ++c) {
          int idx = r * 9 + c;
          NSTextField *cell = cells_[idx];

          CABasicAnimation *colorAnim =
              [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
          colorAnim.fromValue = (id)cell.layer.backgroundColor;
          colorAnim.toValue =
              (id)[NSColor colorWithRed:0.2 green:1.0 blue:0.8 alpha:0.8]
                  .CGColor;
          colorAnim.duration = 0.5;
          colorAnim.autoreverses = YES;

          [cell.layer addAnimation:colorAnim forKey:@"flashComplete"];
          [self refreshCellAtRow:r col:c];
        }
      }
    }
  }
}

- (void)applyValue:(int)value toCellAtRow:(int)row col:(int)col {
  if (gameLocked_) {
    [self setGameStatus:@"La partida ya esta finalizada"
                  color:[NSColor colorWithRed:0.96
                                        green:0.7
                                         blue:0.44
                                        alpha:1.0]];
    return;
  }

  if (row < 0 || row >= 9 || col < 0 || col >= 9) {
    return;
  }

  if (engine_.isFixed(row, col)) {
    [self refreshCellAtRow:row col:col];
    [self setGameStatus:@"Esa casilla es original y esta bloqueada"
                  color:[NSColor colorWithRed:0.98
                                        green:0.56
                                         blue:0.5
                                        alpha:1.0]];
    return;
  }

  int oldValue = engine_.valueAt(row, col);

  if (value == 0) {
    if (oldValue != 0) {
      engine_.setValue(row, col, 0);
      movesCount_ += 1;
      pointsCount_ = std::max<NSInteger>(0, pointsCount_ - 10);
      [self refreshUserPanel];
    }
    [self refreshCellAtRow:row col:col];
    [self setGameStatus:@"Casilla limpiada"
                  color:[NSColor colorWithRed:0.62
                                        green:0.95
                                         blue:0.99
                                        alpha:1.0]];
    return;
  }

  if (value < 1 || value > 9) {
    [self setGameStatus:@"Solo se permiten valores del 1 al 9"
                  color:[NSColor colorWithRed:0.98
                                        green:0.56
                                         blue:0.5
                                        alpha:1.0]];
    return;
  }

  if (oldValue == value) {
    [self setGameStatus:@"Ese numero ya esta en la casilla"
                  color:[NSColor colorWithRed:0.62
                                        green:0.95
                                         blue:0.99
                                        alpha:1.0]];
    return;
  }

  if (value != engine_.solutionValueAt(row, col)) {
    movesCount_ += 1;
    livesCount_ = std::max<NSInteger>(0, livesCount_ - 1);
    pointsCount_ = std::max<NSInteger>(0, pointsCount_ - 25);

    [self refreshUserPanel];
    [self refreshCellAtRow:row col:col];
    [self
        setGameStatus:[NSString
                          stringWithFormat:@"Incorrecto. Vidas restantes: %ld",
                                           (long)livesCount_]
                color:[NSColor colorWithRed:0.98
                                      green:0.56
                                       blue:0.5
                                      alpha:1.0]];

    if (livesCount_ <= 0) {
      [self triggerGameOver];
    }
    return;
  }

  engine_.setValue(row, col, value);
  movesCount_ += 1;
  pointsCount_ += (oldValue == 0 ? 120 : 50);

  [self checkBlocksCompletion];

  [self refreshCellAtRow:row col:col];
  [self refreshUserPanel];
  [self setGameStatus:[NSString stringWithFormat:@"Correcto. +%d puntos",
                                                 oldValue == 0 ? 120 : 50]
                color:[NSColor colorWithRed:0.57
                                      green:0.97
                                       blue:0.76
                                      alpha:1.0]];

  if (engine_.isComplete()) {
    [self triggerVictory];
  }
}

- (void)triggerGameOver {
  if (gameLocked_) {
    return;
  }

  gameLocked_ = YES;
  [self stopGameTimer];
  [self refreshAllCells];
  [self recordCurrentGamePoints];
  [self setGameStatus:@"GAME OVER: sin vidas"
                color:[NSColor colorWithRed:0.98
                                      green:0.56
                                       blue:0.5
                                      alpha:1.0]];

  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:@"Game Over"];
  [alert setInformativeText:
             [NSString stringWithFormat:@"Te quedaste sin vidas. Puntos: %ld",
                                        (long)pointsCount_]];
  [alert runModal];
}

- (void)triggerVictory {
  if (gameLocked_) {
    return;
  }

  gameLocked_ = YES;
  [self stopGameTimer];

  NSInteger bonus = livesCount_ * 75;
  pointsCount_ += bonus;
  [self recordCurrentGamePoints];

  if (currentUser_ && gameStartDate_) {
    NSInteger totalSecs =
        (NSInteger)[[NSDate date] timeIntervalSinceDate:gameStartDate_];
    NSInteger prevBest = [userBestTimes_[currentUser_] integerValue];
    if (prevBest == 0 || totalSecs < prevBest) {
      userBestTimes_[currentUser_] = @(totalSecs);
      [self saveUsers];
    }
  }

  [self refreshUserPanel];
  [self refreshAllCells];
  [self setGameStatus:[NSString
                          stringWithFormat:@"VICTORIA! Bonus por vidas: +%ld",
                                           (long)bonus]
                color:[NSColor colorWithRed:0.55
                                      green:0.98
                                       blue:0.72
                                      alpha:1.0]];

  [self showVictoryOverlay];
}

- (void)showVictoryOverlay {
  NSRect bounds = window_.contentView.bounds;
  NSView *overlay = [[NSView alloc] initWithFrame:bounds];
  overlay.wantsLayer = YES;
  overlay.layer.backgroundColor =
      [NSColor colorWithRed:0.0 green:0.05 blue:0.1 alpha:0.85].CGColor;

  overlay.alphaValue = 0.0;
  [window_.contentView addSubview:overlay];
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
    context.duration = 0.5;
    overlay.animator.alphaValue = 1.0;
  }];

  NSView *panel =
      [self makePanelWithFrame:NSMakeRect((bounds.size.width - 500) / 2.0,
                                          (bounds.size.height - 300) / 2.0, 500,
                                          300)];
  [overlay addSubview:panel];

  NSTextField *title =
      [self makeLabelWithFrame:NSMakeRect(0, 220, 500, 50)
                          text:@"VICTORIA"
                          font:[self fontWithName:@"Avenir Next Condensed Bold"
                                             size:48
                                   fallbackWeight:NSFontWeightBold]
                         color:[NSColor colorWithRed:0.2
                                               green:0.98
                                                blue:0.8
                                               alpha:1.0]];
  title.alignment = NSTextAlignmentCenter;
  [panel addSubview:title];

  NSString *timeStr = timeValueLabel_.stringValue ?: @"";
  NSTextField *info = [self
      makeLabelWithFrame:NSMakeRect(0, 140, 500, 60)
                    text:[NSString stringWithFormat:
                                       @"¡Has completado el "
                                       @"Sudoku!\n%@\nPuntos finales: %ld",
                                       timeStr, (long)pointsCount_]
                    font:[self fontWithName:@"Menlo-Regular"
                                       size:18
                             fallbackWeight:NSFontWeightRegular]
                   color:[NSColor colorWithRed:0.7
                                         green:0.95
                                          blue:1.0
                                         alpha:1.0]];
  info.alignment = NSTextAlignmentCenter;
  [panel addSubview:info];

  NSButton *menuBtn =
      [self makeCyberButtonWithFrame:NSMakeRect(70, 40, 160, 44)
                               title:@"Menu Principal"
                              action:@selector(dismissVictoryAndGoMenu:)];
  menuBtn.target = self;
  [panel addSubview:menuBtn];

  NSButton *newGameBtn =
      [self makeCyberButtonWithFrame:NSMakeRect(270, 40, 160, 44)
                               title:@"Nueva Partida"
                              action:@selector(dismissVictoryAndNewGame:)];
  newGameBtn.target = self;
  [panel addSubview:newGameBtn];
}

- (void)dismissVictoryAndGoMenu:(NSButton *)sender {
  [sender.superview.superview removeFromSuperview];
  [self backToMenu:nil];
}

- (void)dismissVictoryAndNewGame:(NSButton *)sender {
  [sender.superview.superview removeFromSuperview];
  [self startNewGame:nil];
}

- (void)commitCellValue:(NSTextField *)field {
  int idx = (int)field.tag;
  if (idx < 0 || idx >= 81) {
    return;
  }

  int row = idx / 9;
  int col = idx % 9;
  if (gameLocked_) {
    [self refreshCellAtRow:row col:col];
    return;
  }

  NSString *raw = trimmed(field.stringValue ?: @"");
  if (raw.length == 0) {
    [self applyValue:0 toCellAtRow:row col:col];
    return;
  }

  if (raw.length != 1) {
    [self refreshCellAtRow:row col:col];
    [self setGameStatus:@"Ingresa un valor de 1 a 9"
                  color:[NSColor colorWithRed:0.98
                                        green:0.56
                                         blue:0.5
                                        alpha:1.0]];
    return;
  }

  unichar ch = [raw characterAtIndex:0];
  if (ch < '1' || ch > '9') {
    [self refreshCellAtRow:row col:col];
    [self setGameStatus:@"Solo se permiten numeros del 1 al 9"
                  color:[NSColor colorWithRed:0.98
                                        green:0.56
                                         blue:0.5
                                        alpha:1.0]];
    return;
  }

  [self applyValue:(int)(ch - '0') toCellAtRow:row col:col];
}

- (NSString *)usersStorePath {
  NSFileManager *manager = [NSFileManager defaultManager];
  NSURL *support = [[manager URLsForDirectory:NSApplicationSupportDirectory
                                    inDomains:NSUserDomainMask] firstObject];
  NSURL *appFolder = [support URLByAppendingPathComponent:@"SudokuCyber"
                                              isDirectory:YES];
  [manager createDirectoryAtURL:appFolder
      withIntermediateDirectories:YES
                       attributes:nil
                            error:NULL];
  return [[appFolder URLByAppendingPathComponent:@"users.txt"] path];
}

- (NSString *)legacyUsersStorePath {
  NSFileManager *manager = [NSFileManager defaultManager];
  NSURL *support = [[manager URLsForDirectory:NSApplicationSupportDirectory
                                    inDomains:NSUserDomainMask] firstObject];
  NSURL *appFolder = [support URLByAppendingPathComponent:@"SudokuCyber"
                                              isDirectory:YES];
  [manager createDirectoryAtURL:appFolder
      withIntermediateDirectories:YES
                       attributes:nil
                            error:NULL];
  return [[appFolder URLByAppendingPathComponent:@"users.plist"] path];
}

- (NSInteger)totalPointsForUser:(NSString *)username {
  if (!username || username.length == 0) {
    return 0;
  }

  NSNumber *points = userPoints_[username];
  if (!points) {
    userPoints_[username] = @0;
    return 0;
  }

  NSInteger value = [points integerValue];
  if (value < 0) {
    userPoints_[username] = @0;
    return 0;
  }

  return value;
}

- (void)recordCurrentGamePoints {
  if (!currentUser_ || currentUser_.length == 0) {
    return;
  }

  NSInteger gained = std::max<NSInteger>(0, pointsCount_);
  NSInteger total = [self totalPointsForUser:currentUser_];
  userPoints_[currentUser_] = @(total + gained);
  [self saveUsers];
}

- (NSArray<NSString *> *)sortedUsersByScore {
  NSArray<NSString *> *usernames = [users_ allKeys];
  return [usernames sortedArrayUsingComparator:^NSComparisonResult(
                        NSString *left, NSString *right) {
    NSInteger leftPoints = [self totalPointsForUser:left];
    NSInteger rightPoints = [self totalPointsForUser:right];

    if (leftPoints > rightPoints) {
      return NSOrderedAscending;
    }
    if (leftPoints < rightPoints) {
      return NSOrderedDescending;
    }
    return [left localizedCaseInsensitiveCompare:right];
  }];
}

- (void)loadUsers {
  users_ = [[NSMutableDictionary alloc] init];
  userPoints_ = [[NSMutableDictionary alloc] init];
  userBestTimes_ = [[NSMutableDictionary alloc] init];

  NSString *txtPath = [self usersStorePath];
  NSError *readError = nil;
  NSString *raw = [NSString stringWithContentsOfFile:txtPath
                                            encoding:NSUTF8StringEncoding
                                               error:&readError];
  (void)readError;

  if (raw.length > 0) {
    [raw enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
      (void)stop;
      NSString *clean = trimmed(line);
      if (clean.length == 0) {
        return;
      }

      NSArray<NSString *> *parts = [clean componentsSeparatedByString:@"|"];
      if (parts.count < 2) {
        return;
      }

      NSString *username = trimmed(parts[0]);
      if (username.length == 0) {
        return;
      }

      NSString *passHash = parts[1] ?: @"";
      NSInteger points = 0;
      if (parts.count >= 3) {
        points = std::max<NSInteger>(0, [parts[2] integerValue]);
      }

      NSInteger bestTime = 0;
      if (parts.count >= 4) {
        bestTime = std::max<NSInteger>(0, [parts[3] integerValue]);
      }

      users_[username] = passHash;
      userPoints_[username] = @(points);
      userBestTimes_[username] = @(bestTime);
    }];
  }

  if (users_.count > 0) {
    return;
  }

  NSDictionary *legacy =
      [NSDictionary dictionaryWithContentsOfFile:[self legacyUsersStorePath]];
  if (legacy) {
    for (NSString *username in legacy) {
      NSString *passHash = legacy[username];
      if (![username isKindOfClass:[NSString class]] ||
          ![passHash isKindOfClass:[NSString class]]) {
        continue;
      }

      users_[username] = passHash;
      userPoints_[username] = @0;
      userBestTimes_[username] = @0;
    }

    if (users_.count > 0) {
      [self saveUsers];
    }
  }
}

- (void)saveUsers {
  if (!users_) {
    return;
  }

  if (!userPoints_) {
    userPoints_ = [[NSMutableDictionary alloc] init];
  }
  if (!userBestTimes_) {
    userBestTimes_ = [[NSMutableDictionary alloc] init];
  }

  NSMutableArray<NSString *> *lines = [[NSMutableArray alloc] init];
  NSArray<NSString *> *usernames = [[users_ allKeys]
      sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
  for (NSString *username in usernames) {
    NSString *passHash = users_[username] ?: @"";
    NSInteger points = [self totalPointsForUser:username];
    NSInteger bestTime = [userBestTimes_[username] integerValue];
    [lines addObject:[NSString stringWithFormat:@"%@|%@|%ld|%ld", username,
                                                passHash, (long)points,
                                                (long)bestTime]];
  }

  NSString *path = [self usersStorePath];
  NSString *payload = [lines componentsJoinedByString:@"\n"];
  NSError *writeError = nil;
  [payload writeToFile:path
            atomically:YES
              encoding:NSUTF8StringEncoding
                 error:&writeError];
  (void)writeError;
}

@end

int main() {
  @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    SudokuController *delegate = [[SudokuController alloc] init];
    [NSApp setDelegate:delegate];
    [NSApp run];
  }
  return 0;
}
