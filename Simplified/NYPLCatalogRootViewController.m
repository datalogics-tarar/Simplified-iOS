#import "NYPLBookDetailViewController.h"
#import "NYPLCatalogCategoryViewController.h"
#import "NYPLCatalogSearchViewController.h"
#import "NYPLCatalogLane.h"
#import "NYPLCatalogLaneCell.h"
#import "NYPLCatalogRoot.h"
#import "NYPLCatalogSubsectionLink.h"
#import "NYPLConfiguration.h"
#import "NYPLSession.h"

#import "NYPLCatalogRootViewController.h"

static CGFloat const rowHeight = 115.0;
static CGFloat const sectionHeaderHeight = 35.0;

@interface NYPLCatalogRootViewController ()
  <NYPLCatalogLaneCellDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic) NYPLCatalogRoot *catalogRoot;
@property (nonatomic) NSMutableDictionary *cachedCells;
@property (nonatomic) NSMutableDictionary *URLsToImageData;
@property (nonatomic) NSUInteger indexOfNextLaneRequiringImageDownload;
@property (nonatomic) UITableView *tableView;

@end

@implementation NYPLCatalogRootViewController

#pragma mark NSObject

- (instancetype)init
{
  self = [super init];
  if(!self) return nil;
  
  self.cachedCells = [NSMutableDictionary dictionary];
  self.URLsToImageData = [NSMutableDictionary dictionary];
  self.title = NSLocalizedString(@"Catalog", nil);
  
  return self;
}

#pragma mark UIViewController

- (void)viewDidLoad
{
  self.view.backgroundColor = [NYPLConfiguration backgroundColor];
  
  self.navigationItem.titleView =
    [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Catalog"]];
  
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                            initWithImage:[UIImage imageNamed:@"Search"]
                                            style:UIBarButtonItemStylePlain
                                            target:self
                                            action:@selector(didSelectSearch)];
  
  self.navigationItem.rightBarButtonItem.enabled = NO;
  
  self.activityIndicatorView = [[UIActivityIndicatorView alloc]
                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  [self.view addSubview:self.activityIndicatorView];
  
  self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
  self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight);
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.sectionHeaderHeight = sectionHeaderHeight;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.allowsSelection = NO;
  self.tableView.hidden = YES;
  [self.view addSubview:self.tableView];
  
  [self downloadFeed];
}

- (void)viewWillLayoutSubviews
{
  self.activityIndicatorView.center = self.view.center;
  
  UIEdgeInsets const insets = UIEdgeInsetsMake(self.topLayoutGuide.length,
                                               0,
                                               self.bottomLayoutGuide.length,
                                               0);
  
  self.tableView.contentInset = insets;
  self.tableView.scrollIndicatorInsets = insets;
}

- (void)didReceiveMemoryWarning
{
  [self.cachedCells removeAllObjects];
}

#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(__attribute__((unused)) UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *const)indexPath
{
  UITableViewCell *const cachedCell = self.cachedCells[indexPath];
  if(cachedCell) {
    return cachedCell;
  }
  
  if(indexPath.section < (NSInteger) self.indexOfNextLaneRequiringImageDownload) {
    NYPLCatalogLaneCell *const cell =
      [[NYPLCatalogLaneCell alloc]
       initWithLaneIndex:indexPath.section
       books:((NYPLCatalogLane *) self.catalogRoot.lanes[indexPath.section]).books
       URLsToImageData:self.URLsToImageData];
    cell.delegate = self;
    self.cachedCells[indexPath] = cell;
    return cell;
  } else {
    // TODO: Add loading cell.
    return [[UITableViewCell alloc] init];
  }
}

- (NSInteger)tableView:(__attribute__((unused)) UITableView *)tableView
 numberOfRowsInSection:(__attribute__((unused)) NSInteger)section
{
  return 1;
}

- (NSInteger)numberOfSectionsInTableView:(__attribute__((unused)) UITableView *)tableView
{
  return self.catalogRoot.lanes.count;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(__attribute__((unused)) UITableView *)tableView
heightForRowAtIndexPath:(__attribute__((unused)) NSIndexPath *)indexPath
{
  return rowHeight;
}

- (CGFloat)tableView:(__attribute__((unused)) UITableView *)tableView
heightForHeaderInSection:(__attribute__((unused)) NSInteger)section
{
  return sectionHeaderHeight;
}

- (UIView *)tableView:(__attribute__((unused)) UITableView *)tableView
viewForHeaderInSection:(NSInteger const)section
{
  CGRect const frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), sectionHeaderHeight);
  UIView *const view = [[UIView alloc] initWithFrame:frame];
  view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  
  {
    UIButton *const button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.titleLabel.font = [UIFont systemFontOfSize:17];
    NSString *const title = ((NYPLCatalogLane *) self.catalogRoot.lanes[section]).title;
    [button setTitle:title forState:UIControlStateNormal];
    [button sizeToFit];
    button.frame = CGRectMake(7, 5, CGRectGetWidth(button.frame), CGRectGetHeight(button.frame));
    button.tag = section;
    [button addTarget:self
               action:@selector(didSelectCategory:)
     forControlEvents:UIControlEventTouchUpInside];
    button.exclusiveTouch = YES;
    [view addSubview:button];
  }
  
  view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
  
  return view;
}

#pragma mark NYPLCatalogLaneCellDelegate

- (void)catalogLaneCell:(NYPLCatalogLaneCell *const)cell
     didSelectBookIndex:(NSUInteger const)bookIndex
{
  NYPLCatalogLane *const lane = self.catalogRoot.lanes[cell.laneIndex];
  NYPLBook *const book = lane.books[bookIndex];
  
  [[[NYPLBookDetailViewController alloc] initWithBook:book] presentFromViewController:self];
}

#pragma mark -

- (void)downloadFeed
{
  self.tableView.hidden = YES;
  self.activityIndicatorView.hidden = NO;
  [self.activityIndicatorView startAnimating];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  [NYPLCatalogRoot
   withURL:[NYPLConfiguration mainFeedURL]
   handler:^(NYPLCatalogRoot *const root) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       self.activityIndicatorView.hidden = YES;
       [self.activityIndicatorView stopAnimating];
       [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
       
       if(!root) {
         [[[UIAlertView alloc]
           initWithTitle:NSLocalizedString(@"CatalogViewControllerFeedDownloadFailedTitle", nil)
           message:NSLocalizedString(@"CheckConnection", nil)
           delegate:nil
           cancelButtonTitle:nil
           otherButtonTitles:NSLocalizedString(@"OK", nil), nil]
          show];
         return;
       }
       
       self.tableView.hidden = NO;
       self.catalogRoot = root;
       [self.tableView reloadData];
       
       if(self.catalogRoot.searchTemplate) {
         self.navigationItem.rightBarButtonItem.enabled = YES;
       }
       
       [self downloadImages];
     }];
   }];
}

- (void)downloadImages
{
  if(self.indexOfNextLaneRequiringImageDownload >= self.catalogRoot.lanes.count) {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    return;
  }
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  NYPLCatalogLane *const lane = self.catalogRoot.lanes[self.indexOfNextLaneRequiringImageDownload];
  
  [[NYPLSession sharedSession]
   withURLs:lane.imageURLs
   handler:^(NSDictionary *const URLToDataOrNull) {
     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
       [URLToDataOrNull enumerateKeysAndObjectsUsingBlock:^(id const key,
                                                            id const value,
                                                            __attribute__((unused)) BOOL *stop) {
         if(![value isKindOfClass:[NSNull class]]) {
           assert([key isKindOfClass:[NSURL class]]);
           assert([value isKindOfClass:[NSData class]]);
           [self.URLsToImageData setValue:value forKey:key];
         }
       }];
       
       [self.tableView reloadData];
       ++self.indexOfNextLaneRequiringImageDownload;
       [self downloadImages];
     }];
   }];
}

- (void)didSelectCategory:(UIButton *const)button
{
  NYPLCatalogLane *const lane = self.catalogRoot.lanes[button.tag];
  
  // TODO: Show the correct controller based on the |lane.subsectionLink.type|.
  NYPLCatalogCategoryViewController *const viewController =
    [[NYPLCatalogCategoryViewController alloc]
     initWithURL:lane.subsectionLink.URL
     title:lane.title];
  
  [self.navigationController pushViewController:viewController animated:YES];
}

- (void)didSelectSearch
{
  [self.navigationController
   pushViewController:[[NYPLCatalogSearchViewController alloc]
                       initWithCategoryTitle:NSLocalizedString(@"Catalog", nil)
                       searchTemplate:self.catalogRoot.searchTemplate]
   animated:YES];
}

@end