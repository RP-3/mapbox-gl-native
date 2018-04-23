//
//  MBShapeSourceTests.m
//  integration
//
//  Created by Julian Rex on 4/5/18.
//  Copyright © 2018 Mapbox. All rights reserved.
//

#import "MGLMapViewIntegrationTest.h"

@interface MGLShapeSourceTests : MGLMapViewIntegrationTest
@end

@implementation MGLShapeSourceTests

- (void)testSettingShapeSourceToNilInRegionDidChange {

    NSMutableArray *features = [[NSMutableArray alloc] init];

    for (NSUInteger i = 0; i <= 180; i+=5) {
        CLLocationCoordinate2D coord[4] = {
            CLLocationCoordinate2DMake(round(0), round(i)),
            CLLocationCoordinate2DMake(round(20), round(i)),
            CLLocationCoordinate2DMake(round(0), round(i / 2 )),
            CLLocationCoordinate2DMake(round(20), round(i / 2))};

        MGLPolygonFeature *feature = [MGLPolygonFeature polygonWithCoordinates:coord count:4];
        [features addObject:feature];
    }

    MGLShapeSource *shapeSource = [[MGLShapeSource alloc] initWithIdentifier:@"source" features:features options:nil];
    [self.style addSource:shapeSource];

    MGLFillStyleLayer *layer = [[MGLFillStyleLayer alloc] initWithIdentifier:@"layer" source:shapeSource];
    layer.fillOpacity = [NSExpression expressionForConstantValue:@0.5];
    [self.style addLayer:layer];

    XCTestExpectation *expectation = [self expectationWithDescription:@"regionDidChange expectation"];

    __weak typeof(self) weakself = self;
    __block NSInteger delegateCallCount = 0;

    self.regionDidChange = ^(MGLMapView *mapView, MGLCameraChangeReason reason, BOOL animated) {

        MGLShapeSourceTests *strongSelf = weakself;

        if (!strongSelf)
            return;

        delegateCallCount++;

        // Setting the shapeSource.shape = nil, was causing an infinite loop, so here
        // we check for a runaway call. 10 here is arbitrary. We could argue that this
        // should check that the call count is only 1, however in this case we particularly
        // want to check for the infinite loop.
        // See https://github.com/mapbox/mapbox-gl-native/issues/11180

        if (delegateCallCount > 10) {
            MGLTestFail(strongSelf);
        }
        else {
            shapeSource.shape = nil;
        }

        [NSObject cancelPreviousPerformRequestsWithTarget:expectation selector:@selector(fulfill) object:nil];
        [expectation performSelector:@selector(fulfill) withObject:nil afterDelay:0.5];
    };

    // setCenterCoordinate is NOT animated here.
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(10.0, 10.0)];
    [self waitForExpectations:@[expectation] timeout:5.0];
}

- (void)testSettingShapeSourceToNilInRegionIsChanging {

    NSMutableArray *features = [[NSMutableArray alloc] init];

    for (NSUInteger i = 0; i <= 180; i+=5) {
        CLLocationCoordinate2D coord[4] = {
            CLLocationCoordinate2DMake(round(0), round(i)),
            CLLocationCoordinate2DMake(round(20), round(i)),
            CLLocationCoordinate2DMake(round(0), round(i / 2 )),
            CLLocationCoordinate2DMake(round(20), round(i / 2))};

        MGLPolygonFeature *feature = [MGLPolygonFeature polygonWithCoordinates:coord count:4];
        [features addObject:feature];
    }

    MGLShapeSource *shapeSource = [[MGLShapeSource alloc] initWithIdentifier:@"source" features:features options:nil];
    [self.style addSource:shapeSource];

    MGLFillStyleLayer *layer = [[MGLFillStyleLayer alloc] initWithIdentifier:@"layer" source:shapeSource];
    layer.fillOpacity = [NSExpression expressionForConstantValue:@0.5];
    [self.style addLayer:layer];

    XCTestExpectation *expectation = [self expectationWithDescription:@"regionDidChange expectation"];

    __block NSInteger delegateCallCount = 0;
    __weak typeof(self) weakself = self;

    self.regionIsChanging = ^(MGLMapView *mapView) {
        // See https://github.com/mapbox/mapbox-gl-native/issues/11180
        shapeSource.shape = nil;
    };

    self.regionDidChange = ^(MGLMapView *mapView, MGLCameraChangeReason reason, BOOL animated) {

        delegateCallCount++;

        if (delegateCallCount > 1) {
            MGLTestFail(weakself);
        }

        [NSObject cancelPreviousPerformRequestsWithTarget:expectation selector:@selector(fulfill) object:nil];
        [expectation performSelector:@selector(fulfill) withObject:nil afterDelay:0.5];
    };

    // Should take MGLAnimationDuration seconds (0.3)
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(10.0, 10.0) animated:YES];
    [self waitForExpectations:@[expectation] timeout:1.0];
}


@end
