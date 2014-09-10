#import "NYPLConfiguration.h"
#import "NYPLLinearView.h"
#import "NYPLRoundedButton.h"

#import "NYPLBookDetailNormalView.h"

@interface NYPLBookDetailNormalView ()

@property (nonatomic) UIView *backgroundView;
@property (nonatomic) NYPLRoundedButton *deleteButton;
@property (nonatomic) NYPLRoundedButton *downloadButton;
@property (nonatomic) NYPLLinearView *deleteReadLinearView;
@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) NYPLRoundedButton *readButton;

@end

@implementation NYPLBookDetailNormalView

#pragma mark UIView

- (instancetype)initWithWidth:(CGFloat)width
{
  self = [super initWithFrame:CGRectMake(0, 0, width, 70)];
  if(!self) return nil;
  
  self.backgroundView = [[UIView alloc] init];
  self.backgroundView.backgroundColor = [NYPLConfiguration mainColor];
  [self addSubview:self.backgroundView];
  
  self.downloadButton = [NYPLRoundedButton button];
  [self.downloadButton setTitle:NSLocalizedString(@"Download", nil)
                       forState:UIControlStateNormal];
  [self.downloadButton addTarget:self
                          action:@selector(didSelectDownload)
                forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.downloadButton];
  
  self.deleteButton = [NYPLRoundedButton button];
  [self.deleteButton setTitle:NSLocalizedString(@"Delete", nil)
                     forState:UIControlStateNormal];
  [self.deleteButton addTarget:self
                        action:@selector(didSelectDelete)
              forControlEvents:UIControlEventTouchUpInside];
  
  self.messageLabel = [[UILabel alloc] init];
  self.messageLabel.font = [UIFont systemFontOfSize:12];
  self.messageLabel.textColor = [NYPLConfiguration backgroundColor];
  [self addSubview:self.messageLabel];
  
  self.readButton = [NYPLRoundedButton button];
  [self.readButton setTitle:NSLocalizedString(@"Read", nil)
                   forState:UIControlStateNormal];
  [self.readButton addTarget:self
                      action:@selector(didSelectRead)
            forControlEvents:UIControlEventTouchUpInside];
  
  self.deleteReadLinearView = [[NYPLLinearView alloc] init];
  self.deleteReadLinearView.padding = 5.0;
  [self.deleteReadLinearView addSubview:self.deleteButton];
  [self.deleteReadLinearView addSubview:self.readButton];
  [self addSubview:self.deleteReadLinearView];
  
  self.state = NYPLBookDetailNormalViewStateUnregistered;
  
  return self;
}

#pragma mark UIView

- (void)layoutSubviews
{
  self.backgroundView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), 30);
  
  [self.messageLabel sizeToFit];
  self.messageLabel.center = self.backgroundView.center;
 
  [self.downloadButton sizeToFit];
  self.downloadButton.center = self.center;
  self.downloadButton.frame = CGRectMake(CGRectGetMinX(self.downloadButton.frame),
                                         (CGRectGetHeight(self.frame) -
                                          CGRectGetHeight(self.downloadButton.frame)),
                                         CGRectGetWidth(self.downloadButton.frame),
                                         CGRectGetHeight(self.downloadButton.frame));
  
  [self.deleteButton sizeToFit];
  
  [self.readButton sizeToFit];
  
  [self.deleteReadLinearView sizeToFit];
  self.deleteReadLinearView.center = self.center;
  self.deleteReadLinearView.frame = CGRectMake(CGRectGetMinX(self.deleteReadLinearView.frame),
                                               (CGRectGetHeight(self.frame) -
                                                CGRectGetHeight(self.deleteReadLinearView.frame)),
                                               CGRectGetWidth(self.deleteReadLinearView.frame),
                                               CGRectGetHeight(self.deleteReadLinearView.frame));
}

#pragma mark -

- (void)setState:(NYPLBookDetailNormalViewState const)state
{
  _state = state;
  
  switch(state) {
    case NYPLBookDetailNormalViewStateUnregistered:
      // fallthrough
    case NYPLBookDetailNormalViewStateDownloadNeeded:
      self.deleteReadLinearView.hidden = YES;
      self.downloadButton.hidden = NO;
      break;
    case NYPLBookDetailNormalViewStateDownloadSuccessful:
      self.deleteReadLinearView.hidden = NO;
      self.downloadButton.hidden = YES;
      break;
    case NYPLBookDetailNormalViewStateUsed:
      self.deleteReadLinearView.hidden = NO;
      self.downloadButton.hidden = YES;
      break;
  }
}

- (void)didSelectDelete
{
  [self.delegate didSelectDeleteForBookDetailNormalView:self];
}

- (void)didSelectDownload
{
  [self.delegate didSelectDownloadForBookDetailNormalView:self];
}

- (void)didSelectRead
{
  [self.delegate didSelectReadForBookDetailNormalView:self];
}

@end