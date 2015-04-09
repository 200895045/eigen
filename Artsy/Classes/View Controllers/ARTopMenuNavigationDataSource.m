#import "ARTopMenuNavigationDataSource.h"
#import "ARShowFeedViewController.h"
#import "ARBrowseViewController.h"
#import "ARFavoritesViewController.h"
#import "ARAppSearchViewController.h"
#import "ARHeroUnitsNetworkModel.h"
#import "ARInternalMobileWebViewController.h"
#import <SDWebImage/SDWebImagePrefetcher.h>

@interface ARTopMenuNavigationDataSource()

@property (nonatomic, assign, readwrite) NSInteger currentIndex;
@property (nonatomic, strong, readonly) NSArray *navigationControllers;

@property (nonatomic, strong, readonly) ARBrowseViewController *browseViewController;

@property (readonly, nonatomic, strong) ARNavigationController *searchNavigationController;
@property (readonly, nonatomic, strong) ARNavigationController *feedNavigationController;
@property (readonly, nonatomic, strong) ARNavigationController *showsNavigationController;
@property (readonly, nonatomic, strong) ARNavigationController *browseNavigationController;
@property (readonly, nonatomic, strong) ARNavigationController *magazineNavigationController;

@end

@implementation ARTopMenuNavigationDataSource

+ (ARNavigationController *)internalWebViewNavigationController:(NSString *)path;
{
    NSURL *URL = [NSURL URLWithString:path];
    ARInternalMobileWebViewController *viewController = [[ARInternalMobileWebViewController alloc] initWithURL:URL];
    return [[ARNavigationController alloc] initWithRootViewController:viewController];
}

- (instancetype)init
{
    self = [super init];

    ARSearchViewController *searchController = [[ARAppSearchViewController alloc] init];
    _searchNavigationController = [[ARNavigationController alloc] initWithRootViewController:searchController];

    ARShowFeed *showFeed = [[ARShowFeed alloc] init];
    ARFeedTimeline *showFeedTimeline = [[ARFeedTimeline alloc] initWithFeed:showFeed];
    _showFeedViewController = [[ARShowFeedViewController alloc] initWithFeedTimeline:showFeedTimeline];
    _showFeedViewController.heroUnitDatasource = [[ARHeroUnitsNetworkModel alloc] init];
    _feedNavigationController = [[ARNavigationController alloc] initWithRootViewController:_showFeedViewController];

    _showsNavigationController = [self.class internalWebViewNavigationController:@"/shows"];

    _browseViewController = [[ARBrowseViewController alloc] init];
    _browseViewController.networkModel = [[ARBrowseNetworkModel alloc] init];
    _browseNavigationController = [[ARNavigationController alloc] initWithRootViewController:_browseViewController];

    _magazineNavigationController = [self.class internalWebViewNavigationController:@"/articles"];

    return self;
}

- (void)prefetchBrowse
{
    [self.browseViewController.networkModel getBrowseFeaturedLinks:^(NSArray *links) {
        NSArray *urls = [links map:^(FeaturedLink * link){
            return link.largeImageURL;
        }];
        SDWebImagePrefetcher *browsePrefetcher = [[SDWebImagePrefetcher alloc] init];
        [browsePrefetcher prefetchURLs:urls];
    } failure:nil];
}

- (void)prefetchHeroUnits
{
    [self.showFeedViewController.heroUnitDatasource getHeroUnitsWithSuccess:^(NSArray *heroUnits){

        // Grab all but the first and try to pre-download them.
        NSArray *urls = [heroUnits map:^id(SiteHeroUnit *unit) {
            return unit.preferredImageURL;
        }];

        SDWebImagePrefetcher *heroUnitPrefetcher = [[SDWebImagePrefetcher alloc] init];
        [heroUnitPrefetcher prefetchURLs:urls];
        
    } failure:nil];
}

- (ARNavigationController *)favoritesNavigationController
{
    // Make a new one each time the favorites tab is selected, so that it presents up-to-date data.
    //
    // According to Laura, the existing instance was kept alive in the past and updated whenever new favourite data
    // became available, but it was removed because of some crashes. This likely had to do with
    // https://github.com/artsy/eigen/issues/287#issuecomment-88036710
    ARFavoritesViewController *favoritesViewController = [[ARFavoritesViewController alloc] init];
    return [[ARNavigationController alloc] initWithRootViewController:favoritesViewController];
}

#pragma mark ARTabViewDataSource

- (UINavigationController *)viewControllerForTabContentView:(ARTabContentView *)tabContentView atIndex:(NSInteger)index
{
    _currentIndex = index;

    switch (index){
        case ARTopTabControllerIndexSearch:
            return self.searchNavigationController;
        case ARTopTabControllerIndexFeed:
            return self.feedNavigationController;
        case ARTopTabControllerIndexShows:
            return self.showsNavigationController;
        case ARTopTabControllerIndexBrowse:
            return self.browseNavigationController;
        case ARTopTabControllerIndexMagazine:
            return self.magazineNavigationController;
        case ARTopTabControllerIndexFavorites:
            return self.favoritesNavigationController;
    }

    return nil;
}

- (BOOL)tabContentView:(ARTabContentView *)tabContentView canPresentViewControllerAtIndex:(NSInteger)index
{
    return YES;
}

- (NSInteger)numberOfViewControllersForTabContentView:(ARTabContentView *)tabContentView
{
    return 6;
}

@end
