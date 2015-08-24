#import "NYPLAccount.h"
#import "NYPLBook.h"
#import "NYPLBookCell.h"
#import "NYPLBookDetailViewController.h"
#import "NYPLBookRegistry.h"
#import "NYPLConfiguration.h"
#import "NYPLFacetBarView.h"
#import "NYPLFacetView.h"
#import "NYPLSettingsAccountViewController.h"
#import "NYPLSettings.h"
#import "NSDate+NYPLDateAdditions.h"
#import "NYPLMyBooksDownloadCenter.h"

#import "NYPLMyBooksViewController.h"

// order-dependent
typedef NS_ENUM(NSInteger, Group) {
  GroupSortBy,
  GroupShow
};

// order-dependent
typedef NS_ENUM(NSInteger, FacetShow) {
  FacetShowAll,
  FacetShowOnLoan
};

// order-dependent
typedef NS_ENUM(NSInteger, FacetSort) {
  FacetSortAuthor,
  FacetSortTitle
};

@interface NYPLMyBooksViewController ()
  <NYPLFacetViewDataSource, NYPLFacetViewDelegate, UICollectionViewDataSource,
   UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) FacetShow activeFacetShow;
@property (nonatomic) FacetSort activeFacetSort;
@property (nonatomic) NSArray *books;
@property (nonatomic) NYPLFacetBarView *facetBarView;
@property (nonatomic) UIBarButtonItem *syncButton;
@property (nonatomic) UIBarButtonItem *syncInProgressButton;

@end

@implementation NYPLMyBooksViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;

  self.title = NSLocalizedString(@"MyBooksViewControllerTitle", nil);
  
  if ( [[NYPLSettings sharedSettings] preloadContentCompleted]) {
      [self willReloadCollectionViewData];
  }
  else {
    [self preloadContentWithHandler:^(void) {
      [self willReloadCollectionViewData];
    }];
  }
  
  [[NSNotificationCenter defaultCenter]
   addObserver:self
   selector:@selector(bookRegistryDidChange)
   name:NYPLBookRegistryDidChangeNotification
   object:nil];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.activeFacetShow = FacetShowAll;
  self.activeFacetSort = FacetSortAuthor;
  
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  
  self.facetBarView = [[NYPLFacetBarView alloc] initWithOrigin:CGPointZero width:0];
  self.facetBarView.facetView.dataSource = self;
  self.facetBarView.facetView.delegate = self;
  [self.view addSubview:self.facetBarView];
  
  self.syncButton = [[UIBarButtonItem alloc]
                     initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                     target:self
                     action:@selector(didSelectSync)];
  self.navigationItem.rightBarButtonItem = self.syncButton;
  
  UIActivityIndicatorView *const activityIndicatorView =
    [[UIActivityIndicatorView alloc]
     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [activityIndicatorView sizeToFit];
  activityIndicatorView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                            UIViewAutoresizingFlexibleHeight);
  [activityIndicatorView startAnimating];
  self.syncInProgressButton = [[UIBarButtonItem alloc]
                               initWithCustomView:activityIndicatorView];
  self.syncInProgressButton.enabled = NO;
  
  if([NYPLBookRegistry sharedRegistry].syncing) {
    self.navigationItem.rightBarButtonItem = self.syncInProgressButton;
  } else {
    self.navigationItem.rightBarButtonItem = self.syncButton;
  }
}

- (void)viewWillLayoutSubviews
{
  self.facetBarView.frame = CGRectMake(0,
                                       CGRectGetMaxY(self.navigationController.navigationBar.frame),
                                       CGRectGetWidth(self.view.frame),
                                       CGRectGetHeight(self.facetBarView.frame));
  
  self.collectionView.contentInset = UIEdgeInsetsMake(CGRectGetMaxY(self.facetBarView.frame),
                                                      self.collectionView.contentInset.left,
                                                      self.collectionView.contentInset.bottom,
                                                      self.collectionView.contentInset.right);
  self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
}

#pragma mark UICollectionViewDelegate

- (void)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *const)indexPath
{
  NYPLBook *const book = self.books[indexPath.row];
  
  [[[NYPLBookDetailViewController alloc] initWithBook:book] presentFromViewController:self];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(__attribute__((unused)) UICollectionView *)collectionView
     numberOfItemsInSection:(__attribute__((unused)) NSInteger)section
{
  return self.books.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  NYPLBook *const book = self.books[indexPath.row];
  
  return NYPLBookCellDequeue(collectionView, indexPath, book);
}

#pragma mark NYPLBookCellCollectionViewController

- (void)willReloadCollectionViewData
{
  [super willReloadCollectionViewData];
  
  switch(self.activeFacetShow) {
    case FacetShowAll:
      switch(self.activeFacetSort) {
        case FacetSortAuthor:
          self.books = [[[NYPLBookRegistry sharedRegistry] myBooks] sortedArrayUsingComparator:
                        ^NSComparisonResult(NYPLBook *const a, NYPLBook *const b) {
                          return [a.authors compare:b.authors options:NSCaseInsensitiveSearch];
                        }];
          return;
        case FacetSortTitle:
          self.books = [[[NYPLBookRegistry sharedRegistry] myBooks] sortedArrayUsingComparator:
                        ^NSComparisonResult(NYPLBook *const a, NYPLBook *const b) {
                          return [a.title compare:b.title options:NSCaseInsensitiveSearch];
                        }];
          return;
      }
      break;
    case FacetShowOnLoan:
      self.books = @[];
      return;
  }
  
  @throw NSInternalInconsistencyException;
}

#pragma mark NYPLFacetViewDataSource

- (NSUInteger)numberOfFacetGroupsInFacetView:(__attribute__((unused)) NYPLFacetView *)facetView
{
  return 2;
}

- (NSUInteger)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
numberOfFacetsInFacetGroupAtIndex:(__attribute__((unused)) NSUInteger)index
{
  return 2;
}

- (NSString *)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
nameForFacetGroupAtIndex:(NSUInteger const)index
{
  return @[NSLocalizedString(@"MyBooksViewControllerGroupSortBy", nil),
           NSLocalizedString(@"MyBooksViewControllerGroupShow", nil)
           ][index];
}

- (NSString *)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
nameForFacetAtIndexPath:(NSIndexPath *const)indexPath
{
  switch([indexPath indexAtPosition:0]) {
    case GroupShow:
      switch([indexPath indexAtPosition:1]) {
        case FacetShowAll:
          return NSLocalizedString(@"MyBooksViewControllerFacetAll", nil);
        case FacetShowOnLoan:
          return NSLocalizedString(@"MyBooksViewControllerFacetOnLoan", nil);
      }
      break;
    case GroupSortBy:
      switch([indexPath indexAtPosition:1]) {
        case FacetSortAuthor:
          return NSLocalizedString(@"MyBooksViewControllerFacetAuthor", nil);
        case FacetSortTitle:
          return NSLocalizedString(@"MyBooksViewControllerFacetTitle", nil);
      }
      break;
  }
  
  @throw NSInternalInconsistencyException;
}

- (BOOL)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
isActiveFacetForFacetGroupAtIndex:(__attribute__((unused)) NSUInteger)index
{
  return YES;
}

- (NSUInteger)facetView:(__attribute__((unused)) NYPLFacetView *)facetView
activeFacetIndexForFacetGroupAtIndex:(NSUInteger const)index
{
  switch(index) {
    case GroupShow:
      return self.activeFacetShow;
    case GroupSortBy:
      return self.activeFacetSort;
  }
  
  @throw NSInternalInconsistencyException;
}

#pragma mark NYPLFacetViewDelegate

- (void)facetView:(NYPLFacetView *const)facetView
didSelectFacetAtIndexPath:(NSIndexPath *const)indexPath
{
  switch([indexPath indexAtPosition:0]) {
    case GroupShow:
      switch([indexPath indexAtPosition:1]) {
        case FacetShowAll:
          self.activeFacetShow = FacetShowAll;
          goto OK;
        case FacetShowOnLoan:
          self.activeFacetShow = FacetShowOnLoan;
          goto OK;
      }
      break;
    case GroupSortBy:
      switch([indexPath indexAtPosition:1]) {
        case FacetSortAuthor:
          self.activeFacetSort = FacetSortAuthor;
          goto OK;
        case FacetSortTitle:
          self.activeFacetSort = FacetSortTitle;
          goto OK;
      }
      break;
  }
  
  @throw NSInternalInconsistencyException;
  
OK:
  
  [facetView reloadData];
  [self willReloadCollectionViewData];
  [self.collectionView reloadData];
}

#pragma mark -

- (void)didSelectSync
{
  if([[NYPLAccount sharedAccount] hasBarcodeAndPIN]) {
    [[NYPLBookRegistry sharedRegistry] syncWithStandardAlertsOnCompletion];
  } else {
    // We can't sync if we're not logged in, so let's log in. We don't need a completion handler
    // here because logging in will trigger a sync anyway. The only downside of letting the sync
    // happen elsewhere is that the user will not receive an error if the sync fails because it will
    // be considered an automatic sync and not a manual sync.
    // TODO: We should make this into a manual sync while somehow avoiding double-syncing.
    [NYPLSettingsAccountViewController
     requestCredentialsUsingExistingBarcode:NO
     completionHandler:nil];
  }
}

- (void)bookRegistryDidChange
{
  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    if([NYPLBookRegistry sharedRegistry].syncing) {
      self.navigationItem.rightBarButtonItem = self.syncInProgressButton;
    } else {
      self.navigationItem.rightBarButtonItem = self.syncButton;
    }
  }];
}


- (void) preloadContentWithHandler:(void(^)(void))handler
{
  @synchronized (self) {
    NSArray *booksToPreload = [[NYPLSettings sharedSettings] booksToPreload];
    for (NYPLBook *book in booksToPreload) {
      [[NYPLMyBooksDownloadCenter sharedDownloadCenter] startDownloadForPreloadedBook:book];
    }
    [[NYPLSettings sharedSettings] setPreloadContentCompleted:YES];
    
    if (handler) handler();
  }
}

@end
