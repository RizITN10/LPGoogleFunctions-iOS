//
//  LPGoogleFunctions.m
//
//  Created by Luka Penger on 7/4/13.
//  Copyright (c) 2013 Luka Penger. All rights reserved.
//

// This code is distributed under the terms and conditions of the MIT license.

// Copyright (c) 2013 Luka Penger
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "LPGoogleFunctions.h"
#import "OrderedDictionary.h"

#import "LPURLSigner.h"


NSString *const STATUS_OK = @"OK";
NSString *const STATUS_NOT_FOUND = @"NOT_FOUND";
NSString *const STATUS_ZERO_RESULTS = @"ZERO_RESULTS";
NSString *const STATUS_MAX_WAYPOINTS_EXCEEDED = @"MAX_WAYPOINTS_EXCEEDED";
NSString *const STATUS_INVALID_REQUEST = @"INVALID_REQUEST";
NSString *const STATUS_OVER_QUERY_LIMIT = @"OVER_QUERY_LIMIT";
NSString *const STATUS_REQUEST_DENIED = @"REQUEST_DENIED";
NSString *const STATUS_UNKNOWN_ERROR = @"UNKNOWN_ERROR";

NSString *const googleAPIUri           = @"https://maps.googleapis.com";
NSString *const googleAPIStreetViewImageURLPath = @"maps/api/streetview";
NSString *const googleAPIPlacesAutocompleteURLPath = @"maps/api/place/autocomplete/json";
NSString *const googleAPINearbySearchURLPath = @"maps/api/place/nearbysearch/json";
NSString *const googleAPIPlaceDetailsURLPath = @"maps/api/place/details/json";
NSString *const googleAPIGeocodingURLPath = @"maps/api/geocode/json";
NSString *const googleAPIPlaceTextSearchURLPath = @"maps/api/place/textsearch/json";
NSString *const googleAPIPlacePhotoURLPath = @"maps/api/place/photo";
NSString *const googleAPIDistanceMatrixURLPath = @"maps/api/distancematrix/json";
NSString *const googleAPIDirectionsURLPath = @"maps/api/directions/json";
NSString *const googleAPIStaticMapImageURLPath = @"maps/api/staticmap";


NSString *const googleAPITextToSpeechURL = @"https://translate.google.com/translate_tts?";

@interface LPGoogleFunctions ()

@end


@implementation LPGoogleFunctions

#pragma mark - Lifecycle

- (id)init
{
    self = [super init];
    if (self) {
        self.sensor = YES;
        self.languageCode = @"en";
    }
    return self;
}

+ (instancetype)sharedInstance
{
    static LPGoogleFunctions *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Functions

+ (NSString *)getMapType:(LPGoogleMapType)maptype
{
    switch (maptype) {
        case LPGoogleMapTypeRoadmap:
            return @"roadmap";
        case LPGoogleMapTypeHybrid:
            return @"hybrid";
        case LPGoogleMapTypeSatellite:
            return @"satellite";
        default:
            return @"terrain";
    }
}

+ (LPGoogleStatus)getGoogleStatusFromString:(NSString *)status
{
    if ([status isEqualToString:STATUS_OK]) {
        return LPGoogleStatusOK;
    } else if ([status isEqualToString:STATUS_NOT_FOUND]) {
        return LPGoogleStatusNotFound;
    } else if ([status isEqualToString:STATUS_ZERO_RESULTS]) {
        return LPGoogleStatusZeroResults;
    } else if ([status isEqualToString:STATUS_MAX_WAYPOINTS_EXCEEDED]) {
        return LPGoogleStatusMaxWaypointsExceeded;
    } else if ([status isEqualToString:STATUS_INVALID_REQUEST]) {
        return LPGoogleStatusInvalidRequest;
    } else if ([status isEqualToString:STATUS_OVER_QUERY_LIMIT]) {
        return LPGoogleStatusOverQueryLimit;
    } else if ([status isEqualToString:STATUS_REQUEST_DENIED]) {
        return LPGoogleStatusRequestDenied;
    } else {
        return LPGoogleStatusUnknownError;
    }
}

+ (NSString*)getGoogleStatus:(LPGoogleStatus)status
{
    switch (status) {
        case LPGoogleStatusOK:
            return STATUS_OK;
        case LPGoogleStatusInvalidRequest:
            return STATUS_INVALID_REQUEST;
        case LPGoogleStatusMaxWaypointsExceeded:
            return STATUS_MAX_WAYPOINTS_EXCEEDED;
        case LPGoogleStatusNotFound:
            return STATUS_NOT_FOUND;
        case LPGoogleStatusOverQueryLimit:
            return STATUS_OVER_QUERY_LIMIT;
        case LPGoogleStatusRequestDenied:
            return STATUS_REQUEST_DENIED;
        case LPGoogleStatusZeroResults:
            return STATUS_ZERO_RESULTS;
        default:
            return STATUS_UNKNOWN_ERROR;
    }
}

- (NSString *)calculateSignatureForURLString_ASSET:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *signature = [[LPURLSigner sharedManager] createSignatureWithHMAC_SHA1:[NSString stringWithFormat:@"%@?%@", [url path], [url query]] key:self.googleAPICryptoKey];
    return signature;
}

- (NSString *)calculateSignatureForURLString_OEM_Places:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *signature = [[LPURLSigner sharedManager] createSignatureWithHMAC_SHA1:[NSString stringWithFormat:@"%@?%@", [url path], [url query]] key:self.googlePlacesAPICryptoKey];
    return signature;
}

- (void)loadStreetViewImageForLocation:(LPLocation *)location imageSize:(CGSize)size heading:(float)heading fov:(float)fov pitch:(float)pitch successfulBlock:(void (^)(UIImage *image))successful failureBlock:(void (^)(NSError *error))failure
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFImageResponseSerializer serializer];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    if (self.googleAPIBrowserKey) {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIBrowserKey] forKey:@"key"];
    }
    else {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIClientID] forKey:@"client"];
    }
    [parameters setObject:[NSString stringWithFormat:@"%@", self.sensor ? @"true" : @"false"] forKey:@"sensor"];
    [parameters setObject:[NSString stringWithFormat:@"%dx%d", (int)size.width, (int)size.height] forKey:@"size"];
    [parameters setObject:[NSString stringWithFormat:@"%f,%f", location.latitude, location.longitude] forKey:@"location"];
    [parameters setObject:[NSString stringWithFormat:@"%.2f", heading] forKey:@"heading"];
    [parameters setObject:[NSString stringWithFormat:@"%.2f", fov] forKey:@"fov"];
    [parameters setObject:[NSString stringWithFormat:@"%.2f", pitch] forKey:@"pitch"];
    
    [manager GET:[NSString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIStreetViewImageURLPath] parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (successful)
            successful(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure)
            failure(error);
    }];
}

- (void)loadStreetViewImageForAddress:(NSString *)address imageSize:(CGSize)size heading:(float)heading fov:(float)fov pitch:(float)pitch successfulBlock:(void (^)(UIImage *image))successful failureBlock:(void (^)(NSError *error))failure
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFImageResponseSerializer serializer];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    if (self.googleAPIBrowserKey) {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIBrowserKey] forKey:@"key"];
    }
    else {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIClientID] forKey:@"client"];
    }
    
    [parameters setObject:[NSString stringWithFormat:@"%@", self.sensor ? @"true" : @"false"] forKey:@"sensor"];
    [parameters setObject:[NSString stringWithFormat:@"%dx%d", (int)size.width, (int)size.height] forKey:@"size"];
    [parameters setObject:[NSString stringWithFormat:@"%@", address] forKey:@"location"];
    [parameters setObject:[NSString stringWithFormat:@"%.2f", heading] forKey:@"heading"];
    [parameters setObject:[NSString stringWithFormat:@"%.2f", fov] forKey:@"fov"];
    [parameters setObject:[NSString stringWithFormat:@"%.2f", pitch] forKey:@"pitch"];
    
    [manager GET:[NSString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIStreetViewImageURLPath] parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (successful)
            successful(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure)
            failure(error);
    }];
}

- (void)loadStaticMapImageForLocation:(LPLocation *)location zoomLevel:(int)zoom imageSize:(CGSize)size imageScale:(int)scale mapType:(LPGoogleMapType)maptype markersArray:(NSArray *)markers successfulBlock:(void (^)(UIImage *image))successful failureBlock:(void (^)(NSError *error))failure
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFImageResponseSerializer serializer];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    [parameters setObject:[NSString stringWithFormat:@"%f,%f", location.latitude, location.longitude] forKey:@"center"];
    [parameters setObject:(self.sensor ? @"true" : @"false") forKey:@"sensor"];
    [parameters setObject:[NSNumber numberWithInt:zoom] forKey:@"zoom"];
    [parameters setObject:[NSNumber numberWithInt:scale] forKey:@"scale"];
    [parameters setObject:[NSString stringWithFormat:@"%dx%d", (int)size.width, (int)size.height] forKey:@"size"];
    [parameters setObject:[LPGoogleFunctions getMapType:maptype] forKey:@"maptype"];
    
    NSMutableSet *parametersMarkers = [[NSMutableSet alloc] init];
    for (int i=0; i<[markers count]; i++) {
        LPMapImageMarker *marker = (LPMapImageMarker *)[markers objectAtIndex:i];
        [parametersMarkers addObject:[marker getMarkerURLString]];
    }
    [parameters setObject:parametersMarkers forKey:@"markers"];
    
    [manager GET:[NSString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIStaticMapImageURLPath]     parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if(successful)
            successful(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(failure)
            failure(error);
    }];
}

- (void)loadStaticMapImageForAddress:(NSString *)address zoomLevel:(int)zoom imageSize:(CGSize)size imageScale:(int)scale mapType:(LPGoogleMapType)maptype markersArray:(NSArray *)markers successfulBlock:(void (^)(UIImage *image))successful failureBlock:(void (^)(NSError *error))failure
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFImageResponseSerializer serializer];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    [parameters setObject:[NSString stringWithFormat:@"%@", address] forKey:@"center"];
    [parameters setObject:(self.sensor ? @"true" : @"false") forKey:@"sensor"];
    [parameters setObject:[NSNumber numberWithInt:zoom] forKey:@"zoom"];
    [parameters setObject:[NSNumber numberWithInt:scale] forKey:@"scale"];
    [parameters setObject:[NSString stringWithFormat:@"%dx%d", (int)size.width, (int)size.height] forKey:@"size"];
    [parameters setObject:[LPGoogleFunctions getMapType:maptype] forKey:@"maptype"];
    
    NSMutableSet *parametersMarkers = [[NSMutableSet alloc] init];
    for (int i=0; i<[markers count]; i++) {
        LPMapImageMarker *marker = (LPMapImageMarker *)[markers objectAtIndex:i];
        [parametersMarkers addObject:[marker getMarkerURLString]];
    }
    [parameters setObject:parametersMarkers forKey:@"markers"];
    
    [manager GET:[NSString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIStaticMapImageURLPath] parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if(successful)
            successful(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(failure)
            failure(error);
    }];
}

- (void)loadPlacesAutocompleteForInput:(NSString *)input offset:(int)offset radius:(int)radius location:(LPLocation *)location placeType:(LPGooglePlaceType)placeType countryRestriction:(NSString *)countryRestriction isStrictBounds:(BOOL)isStrictBounds successfulBlock:(void (^)(LPPlacesAutocomplete *placesAutocomplete))successful failureBlock:(void (^)(LPGoogleStatus status))failure
{
    if ([self.delegate respondsToSelector:@selector(googleFunctionsWillLoadPlacesAutocomplete:forInput:)]) {
        [self.delegate googleFunctionsWillLoadPlacesAutocomplete:self forInput:input];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    if (self.googleAPIBrowserKey) {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIBrowserKey] forKey:@"key"];
    }
    else {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIClientID] forKey:@"client"];
    }
    
    if (isStrictBounds) {
        [parameters setObject:@"" forKey:@"strictbounds"];
    }
    
    [parameters setObject:[NSString stringWithFormat:@"%@", input] forKey:@"input"];
    [parameters setObject:[LPPrediction getStringFromGooglePlaceType:placeType] forKey:@"types"];
    [parameters setObject:[NSString stringWithFormat:@"%d", offset] forKey:@"offset"];
    [parameters setObject:[NSString stringWithFormat:@"%d", radius] forKey:@"radius"];
    [parameters setObject:[NSString stringWithFormat:@"%f,%f",location.latitude, location.longitude] forKey:@"location"];
    [parameters setObject:[NSString stringWithFormat:@"%@", self.sensor ? @"true" : @"false"] forKey:@"sensor"];
    [parameters setObject:[NSString stringWithFormat:@"%@", self.languageCode] forKey:@"language"];
    
    if(countryRestriction) {
        [parameters setObject:[NSString stringWithFormat:@"country:%@", countryRestriction] forKey:@"components"];
    }
    
    [manager GET:[NSString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIPlacesAutocompleteURLPath] parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        LPPlacesAutocomplete *placesAutocomplete = [LPPlacesAutocomplete placesAutocompleteWithObjects:responseObject];
        
        NSString *statusCode = placesAutocomplete.statusCode;
        
        if ([statusCode isEqualToString:@"OK"]) {
            if ([self.delegate respondsToSelector:@selector(googleFunctions:didLoadPlacesAutocomplete:)]) {
                [self.delegate googleFunctions:self didLoadPlacesAutocomplete:placesAutocomplete];
            }
            
            if (successful)
                successful(placesAutocomplete);
        } else {
            LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:statusCode];
            
            if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingPlacesAutocompleteWithStatus:)]) {
                [self.delegate googleFunctions:self errorLoadingPlacesAutocompleteWithStatus:status];
            }
            
            if (failure)
                failure(status);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingPlacesAutocompleteWithStatus:)]) {
            [self.delegate googleFunctions:self errorLoadingPlacesAutocompleteWithStatus:LPGoogleStatusUnknownError];
        }
        
        if (failure)
            failure(LPGoogleStatusUnknownError);
    }];
}

- (void)loadNearbyPlacesFor:(LPLocation *)origin radius:(NSString *)radius forceBrowserKey:(NSString *)browserKey successfulBlock:(void (^)(LPPlaceSearchResults *placeSearchResults))successful failureBlock:(void (^)(LPGoogleStatus status))failure {
    
    if ([self.delegate respondsToSelector:@selector(googleFunctionsWillLoadNearbyPlaces:)]) {
        [self.delegate googleFunctionsWillLoadNearbyPlaces:self];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    OrderedDictionary *parameters = [[OrderedDictionary alloc] init];
    
    [parameters setObject:[NSString stringWithFormat:@"%f,%f", origin.latitude, origin.longitude] forKey:@"location"];
    [parameters setObject:[NSString stringWithFormat:@"%@", self.languageCode] forKey:@"language"];
    
    if (radius) {
        [parameters setObject:radius forKey:@"radius"];
    }
    else {
        [parameters setObject:@"distance" forKey:@"rankby"];
    }
    
    if (browserKey) {
        [parameters setObject:[NSString stringWithFormat:@"%@", browserKey] forKey:@"key"];
    }
    
    //    else if (self.googleAPIBrowserKey) {
    //        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIBrowserKey] forKey:@"key"];
    //    }
    //    else {
    //        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIClientID] forKey:@"client"];
    //    }
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPINearbySearchURLPath];
    for (NSString *key in parameters) {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@&", key, parameters[key]]];
    }
    
    //    if (self.googleAPIBrowserKey) {
    //        [urlString appendString:[NSString stringWithFormat:@"%@=%@", @"key", [NSString stringWithFormat:@"%@", self.googleAPIBrowserKey]]];
    //    }
    //    else {
    //        [urlString appendString:[NSString stringWithFormat:@"%@=%@", @"client", [NSString stringWithFormat:@"%@", self.googlePlacesAPIClientID]]];
    //        [urlString appendString:[NSString stringWithFormat:@"&%@=%@", @"signature", [self calculateSignatureForURLString_OEM_Places:urlString]]];
    //    }
    
    [manager GET:urlString parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        LPPlaceSearchResults *placeSearchResults = [LPPlaceSearchResults placeSearchResultsWithObjects:responseObject];
        
        NSString *statusCode = placeSearchResults.statusCode;
        
        if ([statusCode isEqualToString:@"OK"]) {
            if ([self.delegate respondsToSelector:@selector(googleFunctions:didLoadNearbyPlaces:)]) {
                [self.delegate googleFunctions:self didLoadNearbyPlaces:placeSearchResults];
            }
            
            if (successful)
                successful(placeSearchResults);
        } else {
            LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:statusCode];
            
            if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingNearbyPlacesWithStatus:)]) {
                [self.delegate googleFunctions:self errorLoadingNearbyPlacesWithStatus:status];
            }
            
            if (failure)
                failure(status);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingNearbyPlacesWithStatus:)]) {
            [self.delegate googleFunctions:self errorLoadingNearbyPlacesWithStatus:LPGoogleStatusUnknownError];
        }
        
        if (failure)
            failure(LPGoogleStatusUnknownError);
    }];
}

- (void)loadPlaceDetailsForReference:(NSString *)reference successfulBlock:(void (^)(LPPlaceDetailsResults *placeDetailsResults))successful failureBlock:(void (^)(LPGoogleStatus status))failure
{
    if ([self.delegate respondsToSelector:@selector(googleFunctionsWillLoadPlaceDetailsResult:forReference:)]) {
        [self.delegate googleFunctionsWillLoadPlaceDetailsResult:self forReference:reference];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    if (self.googleAPIBrowserKey) {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIBrowserKey] forKey:@"key"];
    }
    else {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIClientID] forKey:@"client"];
    }
    
    [parameters setObject:[NSString stringWithFormat:@"%@", reference] forKey:@"reference"];
    [parameters setObject:[NSString stringWithFormat:@"%@", self.sensor ? @"true" : @"false"] forKey:@"sensor"];
    [parameters setObject:[NSString stringWithFormat:@"%@", self.languageCode] forKey:@"language"];
    
    [manager GET:[NSString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIPlaceDetailsURLPath] parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        LPPlaceDetailsResults *placeDetailsResults = [LPPlaceDetailsResults placeDetailsResultsWithObjects:responseObject];
        
        NSString *statusCode = placeDetailsResults.statusCode;
        
        if ([statusCode isEqualToString:@"OK"]) {
            if ([self.delegate respondsToSelector:@selector(googleFunctions:didLoadPlaceDetailsResult:)]) {
                [self.delegate googleFunctions:self didLoadPlaceDetailsResult:placeDetailsResults];
            }
            
            if (successful)
                successful(placeDetailsResults);
        } else {
            LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:statusCode];
            
            if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingPlaceDetailsResultWithStatus:)]) {
                [self.delegate googleFunctions:self errorLoadingPlaceDetailsResultWithStatus:status];
            }
            
            if (failure)
                failure(status);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingPlacesAutocompleteWithStatus:)]) {
            [self.delegate googleFunctions:self errorLoadingPlaceDetailsResultWithStatus:LPGoogleStatusUnknownError];
        }
        
        if (failure)
            failure(LPGoogleStatusUnknownError);
    }];
}

- (void)speakText:(NSString *)text failureBlock:(void (^)(NSError *error))failure
{
    [googlePlayer stop];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    [parameters setObject:[NSString stringWithFormat:@"%@", self.languageCode] forKey:@"tl"];
    [parameters setObject:[NSString stringWithFormat:@"%@", text] forKey:@"q"];
    
    [manager GET:googleAPITextToSpeechURL parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSError *error = nil;
        
        googlePlayer = [[AVAudioPlayer alloc] initWithData:responseObject error:&error];
        googlePlayer.delegate = self;
        [googlePlayer play];
        
        if(error) {
            if(failure)
                failure(error);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(failure)
            failure(error);
    }];
}

- (void)loadGeocodingForAddress:(NSString *)address filterComponents:(NSArray *)filterComponents successfulBlock:(void (^)(LPGeocodingResults *geocodingResults))successful failureBlock:(void (^)(LPGoogleStatus status))failure {
    
    if ([self.delegate respondsToSelector:@selector(googleFunctionsWillLoadGeocoding:forAddress:filterComponents:)]) {
        [self.delegate googleFunctionsWillLoadGeocoding:self forAddress:address filterComponents:filterComponents];
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    [parameters setObject:[NSString stringWithFormat:@"%@", address] forKey:@"address"];
    [parameters setObject:[NSString stringWithFormat:@"%@", self.sensor ? @"true" : @"false"] forKey:@"sensor"];
    [parameters setObject:[NSString stringWithFormat:@"%@", self.languageCode] forKey:@"language"];
    
    if ([filterComponents count] > 0) {
        NSString *comString = @"components=";
        
        for (int i=0; i<[filterComponents count]; i++) {
            LPGeocodingFilter *filter = (LPGeocodingFilter *)[filterComponents objectAtIndex:i];
            
            comString = [comString stringByAppendingFormat:@"%@:%@|", [LPGeocodingFilter getGeocodingFilter:filter.filter], filter.value];
        }
    }
    
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"GET" URLString:googleAPIGeocodingURLPath parameters:parameters error:nil];
    
    [self loadGeocodingRequest:request successfulBlock:^(LPGeocodingResults *geocodingResults) {
        
        if (successful)
            successful(geocodingResults);
        
    } failureBlock:^(LPGoogleStatus status) {
        
        if (failure)
            failure(status);
        
    }];
}

- (void)loadGeocodingForPlaceID:(NSString *)placeID filterComponents:(NSArray *)filterComponents successfulBlock:(void (^)(LPGeocodingResults *geocodingResults))successful failureBlock:(void (^)(LPGoogleStatus status, NSString* errorMessage))failure {
    
    if ([self.delegate respondsToSelector:@selector(googleFunctionsWillLoadGeocoding:forPlaceID:filterComponents:)]) {
        [self.delegate googleFunctionsWillLoadGeocoding:self forPlaceID:placeID filterComponents:filterComponents];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    OrderedDictionary *parameters = [[OrderedDictionary alloc] init];
    
    [parameters setObject:placeID forKey:@"place_id"];
    [parameters setObject:self.sensor ? @"true" : @"false" forKey:@"sensor"];
    [parameters setObject:self.languageCode forKey:@"language"];
    
    if ([filterComponents count] > 0) {
        NSString *comString = @"components=";
        
        for (int i=0; i<[filterComponents count]; i++) {
            LPGeocodingFilter *filter = (LPGeocodingFilter *)[filterComponents objectAtIndex:i];
            
            comString = [comString stringByAppendingFormat:@"%@:%@|", [LPGeocodingFilter getGeocodingFilter:filter.filter], filter.value];
        }
    }
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIGeocodingURLPath];
    for (NSString *key in parameters) {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@&", key, parameters[key]]];
    }
    
    if (self.googleAPIBrowserKey) {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@", @"key", [NSString stringWithFormat:@"%@", self.googleAPIBrowserKey]]];
    }
    else {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@", @"client", [NSString stringWithFormat:@"%@", self.googleAPIClientID]]];
        [urlString appendString:[NSString stringWithFormat:@"&%@=%@", @"signature", [self calculateSignatureForURLString_ASSET:urlString]]];
    }
    
    //    NSLog(@"URLString: %@", urlString);
    [manager GET:urlString parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        LPGeocodingResults *results = [LPGeocodingResults geocodingResultsWithObjects:responseObject];
        
        LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:results.statusCode];
        
        NSString *statusCode = results.statusCode;
        
        if (status == LPGoogleStatusOK) {
            
            if ([self.delegate respondsToSelector:@selector(googleFunctions:didLoadGeocodingResults:)]) {
                [self.delegate googleFunctions:self didLoadGeocodingResults:results];
            }
            if (successful)
                successful(results);
        } else {
            LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:statusCode];
            
            if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingGeocodingWithStatus:)]) {
                [self.delegate googleFunctions:self errorLoadingGeocodingWithStatus:status];
            }
            
            if (failure)
                failure(status, results.errorMessage);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingGeocodingWithStatus:)]) {
            [self.delegate googleFunctions:self errorLoadingGeocodingWithStatus:LPGoogleStatusUnknownError];
        }
        
        if (failure)
            failure(LPGoogleStatusUnknownError, [error localizedDescription]);
    }];
}

- (void)loadGeocodingForLocation:(LPLocation *)location filterComponents:(NSArray *)filterComponents successfulBlock:(void (^)(LPGeocodingResults *geocodingResults))successful failureBlock:(void (^)(LPGoogleStatus status, NSString *errorMessage))failure
{
    if ([self.delegate respondsToSelector:@selector(googleFunctionsWillLoadGeocoding:forLocation:filterComponents:)]) {
        [self.delegate googleFunctionsWillLoadGeocoding:self forLocation:location filterComponents:filterComponents];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    OrderedDictionary *parameters = [[OrderedDictionary alloc] init];
    
    [parameters setObject:[NSString stringWithFormat:@"%f,%f", location.latitude, location.longitude] forKey:@"latlng"];
    [parameters setObject:self.sensor ? @"true" : @"false" forKey:@"sensor"];
    [parameters setObject:self.languageCode forKey:@"language"];
    
    if ([filterComponents count] > 0) {
        NSString *comString = @"";
        
        for (int i=0; i<[filterComponents count]; i++) {
            LPGeocodingFilter *filter = (LPGeocodingFilter *)[filterComponents objectAtIndex:i];
            
            comString = [comString stringByAppendingFormat:@"%@:%@|", [LPGeocodingFilter getGeocodingFilter:filter.filter], filter.value];
        }
        
        [parameters setObject:comString forKey:@"components"];
    }
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIGeocodingURLPath];
    for (NSString *key in parameters) {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@&", key, parameters[key]]];
    }
    
    if (self.googleAPIBrowserKey) {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@", @"key", [NSString stringWithFormat:@"%@", self.googleAPIBrowserKey]]];
    }
    else {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@", @"client", [NSString stringWithFormat:@"%@", self.googleAPIClientID]]];
        [urlString appendString:[NSString stringWithFormat:@"&%@=%@", @"signature", [self calculateSignatureForURLString_ASSET:urlString]]];
    }
    
    //    NSLog(@"URLString: %@", urlString);
    [manager GET:urlString parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        LPGeocodingResults *results = [LPGeocodingResults geocodingResultsWithObjects:responseObject];
        
        LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:results.statusCode];
        
        NSString *statusCode = results.statusCode;
        
        if (status == LPGoogleStatusOK) {
            
            if ([self.delegate respondsToSelector:@selector(googleFunctions:didLoadGeocodingResults:)]) {
                [self.delegate googleFunctions:self didLoadGeocodingResults:results];
            }
            if (successful)
                successful(results);
        } else {
            LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:statusCode];
            
            if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingGeocodingWithStatus:)]) {
                [self.delegate googleFunctions:self errorLoadingGeocodingWithStatus:status];
            }
            
            if (failure)
                failure(status, results.errorMessage);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingGeocodingWithStatus:)]) {
            [self.delegate googleFunctions:self errorLoadingGeocodingWithStatus:LPGoogleStatusUnknownError];
        }
        
        if (failure)
            failure(LPGoogleStatusUnknownError, [error localizedDescription]);
    }];
}

- (void)loadGeocodingRequest:(NSMutableURLRequest *)request successfulBlock:(void (^)(LPGeocodingResults *geocodingResults))successful failureBlock:(void (^)(LPGoogleStatus status))failure
{
    AFHTTPSessionManager *requestOperation = [AFHTTPSessionManager manager];
    
    [requestOperation GET:request.URL.absoluteString parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        LPGeocodingResults *results = [LPGeocodingResults geocodingResultsWithObjects:responseObject];
        
        NSString *statusCode = results.statusCode;
        
        if ([statusCode isEqualToString:@"OK"]) {
            if ([self.delegate respondsToSelector:@selector(googleFunctions:didLoadGeocodingResults:)]) {
                [self.delegate googleFunctions:self didLoadGeocodingResults:results];
            }
            
            if (successful)
                successful(results);
        } else {
            LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:statusCode];
            
            if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingGeocodingWithStatus:)]) {
                [self.delegate googleFunctions:self errorLoadingGeocodingWithStatus:status];
            }
            
            if (failure)
                failure(status);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingGeocodingWithStatus:)]) {
            [self.delegate googleFunctions:self errorLoadingGeocodingWithStatus:LPGoogleStatusUnknownError];
        }
        
        if (failure)
            failure(LPGoogleStatusUnknownError);
    }];
}

- (void)loadPlacesAutocompleteWithDetailsForInput:(NSString *)input offset:(int)offset radius:(int)radius location:(LPLocation *)location placeType:(LPGooglePlaceType)placeType countryRestriction:(NSString *)countryRestriction isStrictBounds:(BOOL)isStrictBounds successfulBlock:(void (^)(NSArray *placesWithDetails))successful failureBlock:(void (^)(LPGoogleStatus status))failure
{
    [self loadPlacesAutocompleteForInput:input offset:offset radius:radius location:location placeType:placeType countryRestriction:countryRestriction isStrictBounds:isStrictBounds successfulBlock:^(LPPlacesAutocomplete *placesAutocomplete) {
        
        __block int whichLoaded = 0;
        NSMutableArray *array = [NSMutableArray new];
        __block BOOL blockSend = NO;
        
        for (int i=0; i<[placesAutocomplete.predictions count]; i++) {
            NSString *reference = ((LPPrediction *)[placesAutocomplete.predictions objectAtIndex:i]).reference;
            
            [self loadPlaceDetailsForReference:reference successfulBlock:^(LPPlaceDetailsResults *placeDetailsResults) {
                LPPlaceDetails *placeWithDetails = [placeDetailsResults.result copy];
                
                [array addObject:placeWithDetails];
                
                whichLoaded++;
                
                if (whichLoaded >= [placesAutocomplete.predictions count]) {
                    if ([array count] > 0) {
                        if (!blockSend) {
                            if (successful)
                                successful(array);
                            
                            blockSend = YES;
                        }
                    } else {
                        if (!blockSend) {
                            if (failure)
                                failure(LPGoogleStatusZeroResults);
                            
                            blockSend = YES;
                        }
                    }
                }
            } failureBlock:^(LPGoogleStatus status) {
                whichLoaded++;
                
                if (whichLoaded >= [placesAutocomplete.predictions count]) {
                    if ([array count] > 0) {
                        if (!blockSend) {
                            if (successful)
                                successful(array);
                            
                            blockSend = YES;
                        }
                    } else {
                        if (!blockSend) {
                            if (failure)
                                failure(LPGoogleStatusZeroResults);
                            
                            blockSend = YES;
                        }
                    }
                }
            }];
        }
        
    } failureBlock:^(LPGoogleStatus status) {
        if (failure)
            failure(status);
    }];
}

- (void)loadPlaceTextSearchForQuery:(NSString *)query location:(LPLocation *)location radius:(int)radius successfulBlock:(void (^)(LPPlaceSearchResults *placeResults))successful failureBlock:(void (^)(LPGoogleStatus status))failure
{
    if ([self.delegate respondsToSelector:@selector(googleFunctionsWillLoadPlaceSearch:forQuery:)]) {
        [self.delegate googleFunctionsWillLoadPlaceSearch:self forQuery:query];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    if (self.googleAPIBrowserKey) {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIBrowserKey] forKey:@"key"];
    }
    else {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIClientID] forKey:@"client"];
    }
    
    [parameters setObject:[NSString stringWithFormat:@"%@", query] forKey:@"query"];
    [parameters setObject:[NSString stringWithFormat:@"%@", self.sensor ? @"true" : @"false"] forKey:@"sensor"];
    [parameters setObject:[NSString stringWithFormat:@"%@", self.languageCode] forKey:@"language"];
    
    if (location && radius > 0) {
        [parameters setObject:[NSString stringWithFormat:@"%f,%f", location.latitude, location.longitude] forKey:@"location"];
        [parameters setObject:[NSString stringWithFormat:@"%d", radius] forKey:@"radius"];
    }
    
    [manager GET:[NSString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIPlaceTextSearchURLPath] parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        LPPlaceSearchResults *placeDetailsResults = [LPPlaceSearchResults placeSearchResultsWithObjects:responseObject];
        
        NSString *statusCode = placeDetailsResults.statusCode;
        
        if ([statusCode isEqualToString:@"OK"]) {
            if ([self.delegate respondsToSelector:@selector(googleFunctions:didLoadPlaceSearch:)]) {
                [self.delegate googleFunctions:self didLoadPlaceSearch:placeDetailsResults];
            }
            
            if (successful)
                successful(placeDetailsResults);
        } else {
            LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:statusCode];
            
            if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingPlaceSearchWithStatus:)]) {
                [self.delegate googleFunctions:self errorLoadingPlaceSearchWithStatus:status];
            }
            
            if (failure)
                failure(status);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingPlaceSearchWithStatus:)]) {
            [self.delegate googleFunctions:self errorLoadingPlaceSearchWithStatus:LPGoogleStatusUnknownError];
        }
        
        if (failure)
            failure(LPGoogleStatusUnknownError);
    }];
}

- (void)loadPlacePhotoForReference:(NSString *)reference maxHeight:(int)maxHeight maxWidth:(int)maxWidth successfulBlock:(void (^)(UIImage *image))successful failureBlock:(void (^)(NSError *error))failure
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFImageResponseSerializer serializer];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    if (self.googleAPIBrowserKey) {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIBrowserKey] forKey:@"key"];
    }
    else {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIClientID] forKey:@"client"];
    }
    
    [parameters setObject:[NSString stringWithFormat:@"%@", self.sensor ? @"true" : @"false"] forKey:@"sensor"];
    [parameters setObject:[NSString stringWithFormat:@"%@", reference] forKey:@"photoreference"];
    
    if (maxHeight > 0 && maxHeight <= 1600) {
        [parameters setObject:[NSString stringWithFormat:@"%d", maxHeight] forKey:@"maxheight"];
    }
    
    if (maxWidth > 0 && maxWidth <= 1600) {
        [parameters setObject:[NSString stringWithFormat:@"%d", maxWidth] forKey:@"maxwidth"];
    }
    
    [manager GET:[NSString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIPlacePhotoURLPath] parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if(successful)
            successful(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure)
            failure(error);
    }];
}

#pragma mark - Added methods for custom usage

- (void)loadDistanceMatrixForOrigins:(NSArray *)origins forDestinations:(NSArray *)destinations directionsTravelMode:(LPGoogleDistanceMatrixTravelMode)travelMode directionsAvoidTolls:(LPGoogleDistanceMatrixAvoid)avoid directionsUnit:(LPGoogleDistanceMatrixUnit)unit departureTime:(NSDate *)departureTime trafficModel:(NSString *)trafficModel successfulBlock:(void (^)(LPDistanceMatrix *distanceMatrix))successful failureBlock:(void (^)(LPGoogleStatus status))failure {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    OrderedDictionary *parameters = [[OrderedDictionary alloc] init];
    
    NSMutableString *originsString = [NSMutableString new];
    for (int i=0; i<[origins count]; i++) {
        LPLocation *location = (LPLocation *)[origins objectAtIndex:i];
        
        NSString *coordinate = [NSString stringWithFormat:@"%f,%f", location.latitude, location.longitude];
        
        [originsString appendString:coordinate];
        
        if ([origins count] > 1 && i<([origins count]-1)) {
            [originsString appendString:@"|"];
        }
    }
    [parameters setObject:[NSString stringWithFormat:@"%@", originsString] forKey:@"origins"];
    
    NSMutableString *destinationsString = [NSMutableString new];
    for (int i=0; i<[destinations count]; i++) {
        LPLocation *location = (LPLocation *)[destinations objectAtIndex:i];
        
        NSString *coordinate = [NSString stringWithFormat:@"%f,%f", location.latitude, location.longitude];
        
        [destinationsString appendString:coordinate];
        
        if ([destinations count] > 1 && i<([destinations count]-1)) {
            [destinationsString appendString:@"|"];
        }
    }
    [parameters setObject:[NSString stringWithFormat:@"%@", destinationsString] forKey:@"destinations"];
    
    [parameters setObject:[NSString stringWithFormat:@"%@", self.languageCode] forKey:@"language"];
    [parameters setObject:[LPDistanceMatrix getDistanceMatrixTravelMode:travelMode] forKey:@"mode"];
    if (trafficModel) {
        [parameters setObject:trafficModel forKey:@"traffic_model"];
    }
    
    if ([[LPDistanceMatrix getDistanceMatrixAvoid:avoid] length] != 0) {
        [parameters setObject:[LPDistanceMatrix getDistanceMatrixAvoid:avoid] forKey:@"avoid"];
    }
    
    [parameters setObject:[LPDistanceMatrix getDistanceMatrixUnit:unit] forKey:@"units"];
    
    if (departureTime) {
        [parameters setObject:[NSString stringWithFormat:@"%.0f", [departureTime timeIntervalSince1970]] forKey:@"departure_time"];
    }
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIDistanceMatrixURLPath];
    for (NSString *key in parameters) {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@&", key, parameters[key]]];
    }
    
    if (self.googleAPIBrowserKey) {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@", @"key", [NSString stringWithFormat:@"%@", self.googleAPIBrowserKey]]];
    }
    else {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@", @"client", [NSString stringWithFormat:@"%@", self.googleAPIClientID]]];
        [urlString appendString:[NSString stringWithFormat:@"&%@=%@", @"signature", [self calculateSignatureForURLString_ASSET:urlString]]];
    }
    
    [manager GET:urlString parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        LPDistanceMatrix *distanceMatrix = [LPDistanceMatrix distanceMatrixWithObjects:responseObject];
        distanceMatrix.requestTravelMode = travelMode;
        
        LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:distanceMatrix.statusCode];
        
        if (status == LPGoogleStatusOK) {
            if ([self.delegate respondsToSelector:@selector(googleFunctions:didLoadDistanceMatrix:)]) {
                [self.delegate googleFunctions:self didLoadDistanceMatrix:distanceMatrix];
            }
            
            if (successful)
                successful(distanceMatrix);
        } else {
            if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingDistanceMatrixWithStatus:)]) {
                [self.delegate googleFunctions:self errorLoadingDistanceMatrixWithStatus:status];
            }
            
            if (failure)
                failure(status);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingDistanceMatrixWithStatus:)]) {
            [self.delegate googleFunctions:self errorLoadingDistanceMatrixWithStatus:LPGoogleStatusUnknownError];
        }
        
        if (failure)
            failure(LPGoogleStatusUnknownError);
    }];
}

- (void)loadDirectionsForOrigin:(LPLocation *)origin forDestination:(LPLocation *)destination directionsTravelMode:(LPGoogleDirectionsTravelMode)travelMode directionsAvoidTolls:(LPGoogleDirectionsAvoid)avoid directionsUnit:(LPGoogleDirectionsUnit)unit directionsAlternatives:(BOOL)alternatives departureTime:(NSDate *)departureTime arrivalTime:(NSDate *)arrivalTime waypoints:(NSArray *)waypoints trafficModel:(NSString *)trafficModel successfulBlock:(void (^)(LPDirections *directions))successful failureBlock:(void (^)(LPGoogleStatus status, NSString *errorMessage))failure {
    
    if ([self.delegate respondsToSelector:@selector(googleFunctionsWillLoadDirections:)]) {
        [self.delegate googleFunctionsWillLoadDirections:self];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    OrderedDictionary *parameters = [[OrderedDictionary alloc] init];
    
    [parameters setObject:[NSString stringWithFormat:@"%f,%f", origin.latitude, origin.longitude] forKey:@"origin"];
    [parameters setObject:[NSString stringWithFormat:@"%f,%f", destination.latitude, destination.longitude] forKey:@"destination"];
    //    [parameters setObject:[NSString stringWithFormat:@"%@", self.sensor ? @"true" : @"false"] forKey:@"sensor"];
    [parameters setObject:@"en" forKey:@"language"];
    [parameters setObject:[LPStep getDirectionsTravelMode:travelMode] forKey:@"mode"];
    if (trafficModel) {
        [parameters setObject:trafficModel forKey:@"traffic_model"]; // , optimistic
    }
    
    if ([[LPDirections getDirectionsAvoid:avoid] length] != 0) {
        [parameters setObject:[LPDirections getDirectionsAvoid:avoid] forKey:@"avoid"];
    }
    [parameters setObject:[LPDirections getDirectionsUnit:unit] forKey:@"units"];
    [parameters setObject:[NSString stringWithFormat:@"%@", alternatives ? @"true" : @"false"] forKey:@"alternatives"];
    
    if (departureTime) {
        [parameters setObject:[NSString stringWithFormat:@"%.0f", [departureTime timeIntervalSince1970]] forKey:@"departure_time"];
        //        [parameters setObject:[NSString stringWithFormat:@"%lli", (long long)([[NSDate date] timeIntervalSince1970] * 1000.0)] forKey:@"departure_time"];
    }
    
    if (arrivalTime) {
        [parameters setObject:[NSString stringWithFormat:@"%.0f", [arrivalTime timeIntervalSince1970]] forKey:@"arrival_time"];
    }
    
    if (waypoints.count > 0) {
        
        NSString *waypointsString = @"";
        
        for (int i=0; i<[waypoints count]; i++) {
            LPWaypoint *waypoint = (LPWaypoint *)[waypoints objectAtIndex:i];
            
            if (i < waypoints.count - 1) {
                waypointsString = [waypointsString stringByAppendingFormat:@"%f,%f%%7C", waypoint.location.latitude, waypoint.location.longitude];// 0.7f
            } else {
                
                waypointsString = [waypointsString stringByAppendingFormat:@"%f,%f", waypoint.location.latitude, waypoint.location.longitude];
            }
            
        }
        
        [parameters setObject:waypointsString forKey:@"waypoints"];
    }
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIDirectionsURLPath];
    for (NSString *key in parameters) {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@&", key, parameters[key]]];
    }
    
    if (self.googleAPIBrowserKey) {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@", @"key", [NSString stringWithFormat:@"%@", self.googleAPIBrowserKey]]];
    }
    else {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@", @"client", [NSString stringWithFormat:@"%@", self.googleAPIClientID]]];
        [urlString appendString:[NSString stringWithFormat:@"&%@=%@", @"signature", [self calculateSignatureForURLString_ASSET:urlString]]];
    }
    
    //    if (parameters[@"waypoints"]) {
    //        NSLog(@"URLString: %@", urlString);
    //    }
    
    [manager GET:urlString parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        LPDirections *directions = [LPDirections directionsWithObjects:responseObject];
        directions.requestTravelMode = travelMode;
        
        LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:directions.statusCode];
        
        if (status == LPGoogleStatusOK) {
            if ([self.delegate respondsToSelector:@selector(googleFunctions:didLoadDirections:)]) {
                [self.delegate googleFunctions:self didLoadDirections:directions];
            }
            
            if (successful)
                successful(directions);
        } else {
            if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingDirectionsWithStatus:)]) {
                [self.delegate googleFunctions:self errorLoadingDirectionsWithStatus:status];
            }
            
            if (failure)
                failure(status, directions.errorMessage);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingDirectionsWithStatus:)]) {
            [self.delegate googleFunctions:self errorLoadingDirectionsWithStatus:LPGoogleStatusUnknownError];
        }
        
        if (failure)
            failure(LPGoogleStatusUnknownError, [error localizedDescription]);
    }];
}

- (void)loadDirectionsForOriginFromAddress:(NSString *)origin forDestination:(NSString *)destination directionsTravelMode:(LPGoogleDirectionsTravelMode)travelMode directionsAvoidTolls:(LPGoogleDirectionsAvoid)avoid directionsUnit:(LPGoogleDirectionsUnit)unit directionsAlternatives:(BOOL)alternatives departureTime:(NSDate *)departureTime arrivalTime:(NSDate *)arrivalTime waypoints:(NSArray *)waypoints trafficModel:(NSString *)trafficModel successfulBlock:(void (^)(LPDirections *directions))successful failureBlock:(void (^)(LPGoogleStatus status, NSString *errorMessage))failure {
    
    if ([self.delegate respondsToSelector:@selector(googleFunctionsWillLoadDirectionsForAddress:)]) {
        [self.delegate googleFunctionsWillLoadDirectionsForAddress:self];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    OrderedDictionary *parameters = [[OrderedDictionary alloc] init];
    
    
    [parameters setObject:origin forKey:@"origin"];
    [parameters setObject:destination forKey:@"destination"];
    //    [parameters setObject:[NSString stringWithFormat:@"%@", self.sensor ? @"true" : @"false"] forKey:@"sensor"];
    [parameters setObject:@"en" forKey:@"language"]; // self.languageCode
    [parameters setObject:[LPStep getDirectionsTravelMode:travelMode] forKey:@"mode"];
    if (trafficModel) {
        [parameters setObject:trafficModel forKey:@"traffic_model"];
    }
    
    if ([[LPDirections getDirectionsAvoid:avoid] length] != 0) {
        [parameters setObject:[LPDirections getDirectionsAvoid:avoid] forKey:@"avoid"];
    }
    [parameters setObject:[LPDirections getDirectionsUnit:unit] forKey:@"units"];
    [parameters setObject:[NSString stringWithFormat:@"%@", alternatives ? @"true" : @"false"] forKey:@"alternatives"];
    
    if (departureTime) {
        
        //        NSLog(@"Milliseconds: %@, Seconds: %@", [NSString stringWithFormat:@"%lli", [@(floor([departureTime timeIntervalSince1970] * 1000)) longLongValue]], [NSString stringWithFormat:@"%.0f", [departureTime timeIntervalSince1970]]);
        [parameters setObject:[NSString stringWithFormat:@"%.0f", [departureTime timeIntervalSince1970]] forKey:@"departure_time"];
        //        [parameters setObject:[NSString stringWithFormat:@"%lli", (long long)([[NSDate date] timeIntervalSince1970] * 1000.0)] forKey:@"departure_time"];
    }
    
    if (arrivalTime) {
        [parameters setObject:[NSString stringWithFormat:@"%.0f", [arrivalTime timeIntervalSince1970]] forKey:@"arrival_time"];
    }
    
    if (waypoints.count > 0) {
        NSString *waypointsString = @"";
        
        for (int i=0; i<[waypoints count]; i++) {
            NSString *waypoint = [waypoints objectAtIndex:i];
            
            waypointsString = [waypointsString stringByAppendingFormat:@"%@", waypoint]; // @|
        }
        
        waypointsString = [NSString stringWithFormat:@"via:%@", waypointsString];
        
        [parameters setObject:waypointsString forKey:@"waypoints"];
    }
    
    //    if (waypoints.count > 0) {
    //        NSString *waypointsString = @"";
    //        \
    //        for (int i=0; i<[waypoints count]; i++) {
    //            LPWaypoint *waypoint = (LPWaypoint *)[waypoints objectAtIndex:i];
    //
    //            waypointsString = [waypointsString stringByAppendingFormat:@"%f,%f|", waypoint.location.latitude, waypoint.location.longitude];
    //        }
    //
    //        [parameters setObject:waypointsString forKey:@"waypoints"];
    //    }
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIDirectionsURLPath];
    for (NSString *key in parameters) {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@&", key, parameters[key]]];
    }
    
    if (self.googleAPIBrowserKey) {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@", @"key", [NSString stringWithFormat:@"%@", self.googleAPIBrowserKey]]];
    }
    else {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@", @"client", [NSString stringWithFormat:@"%@", self.googleAPIClientID]]];
        [urlString appendString:[NSString stringWithFormat:@"&%@=%@", @"signature", [self calculateSignatureForURLString_ASSET:urlString]]];
    }
    
    //    NSLog(@"URLString: %@", urlString);
    
    [manager GET:urlString parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        LPDirections *directions = [LPDirections directionsWithObjects:responseObject];
        directions.requestTravelMode = travelMode;
        
        LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:directions.statusCode];
        
        if (status == LPGoogleStatusOK) {
            if ([self.delegate respondsToSelector:@selector(googleFunctions:didLoadDirections:)]) {
                [self.delegate googleFunctions:self didLoadDirections:directions];
            }
            
            if (successful)
                successful(directions);
        } else {
            if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingDirectionsWithStatus:)]) {
                [self.delegate googleFunctions:self errorLoadingDirectionsWithStatus:status];
            }
            
            if (failure)
                failure(status, directions.errorMessage);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingDirectionsWithStatus:)]) {
            [self.delegate googleFunctions:self errorLoadingDirectionsWithStatus:LPGoogleStatusUnknownError];
        }
        
        if (failure)
            failure(LPGoogleStatusUnknownError, [error localizedDescription]);
    }];
}

- (void)loadStaticMapImageWithSize:(CGSize)size imageScale:(int)scale mapType:(LPGoogleMapType)maptype sourceMarker:(NSString *)sourceMarker destMarker:(NSString *)destMarker path:(NSString *)path format:(NSString *)format successfulBlock:(void (^)(UIImage *image))successful failureBlock:(void (^)(NSError *error))failure {
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFImageResponseSerializer serializer];
    
    OrderedDictionary *parameters = [[OrderedDictionary alloc] init];
    
    [parameters setObject:[NSNumber numberWithInt:scale] forKey:@"scale"];
    [parameters setObject:[NSString stringWithFormat:@"%dx%d", (int)size.width, (int)size.height] forKey:@"size"];
    [parameters setObject:[LPGoogleFunctions getMapType:maptype] forKey:@"maptype"];
    [parameters setObject:path forKey:@"path"];
    [parameters setObject:format forKey:@"format"];
    
    NSMutableSet *parametersMarkers = [[NSMutableSet alloc] init];
    [parametersMarkers addObject:sourceMarker];
    [parametersMarkers addObject:destMarker];
    
    [parameters setObject:parametersMarkers forKey:@"markers"];
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIStaticMapImageURLPath];
    for (NSString *key in parameters) {
        if ([parameters[key] isKindOfClass:[NSMutableSet class]]) {
            for (int i=0; i<[parameters[key] count]; i++) {
                [urlString appendString:[NSString stringWithFormat:@"%@=%@&", key, [parameters[key] allObjects][i]]];
            }
        }
        else {
            [urlString appendString:[NSString stringWithFormat:@"%@=%@&", key, parameters[key]]];
        }
    }
    
    if (self.googleAPIBrowserKey) {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@", @"key", [NSString stringWithFormat:@"%@", self.googleAPIBrowserKey]]];
    }
    else {
        [urlString appendString:[NSString stringWithFormat:@"%@=%@", @"client", [NSString stringWithFormat:@"%@", self.googleAPIClientID]]];
        [urlString appendString:[NSString stringWithFormat:@"&%@=%@", @"signature", [self calculateSignatureForURLString_ASSET:urlString]]];
    }
    
    [manager GET:urlString parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if(successful)
            successful(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(failure)
            failure(error);
    }];
}

- (void)loadPlacesAutocompleteForInput:(NSString *)input offset:(int)offset location:(LPLocation *)location placeType:(LPGooglePlaceType)placeType countryRestriction:(NSString *)countryRestriction forceBrowserKey:(NSString *)browserKey successfulBlock:(void (^)(NSArray *placesAutocomplete))successful failureBlock:(void (^)(LPGoogleStatus status))failure {
    if ([self.delegate respondsToSelector:@selector(googleFunctionsWillLoadPlacesAutocomplete:forInput:)]) {
        [self.delegate googleFunctionsWillLoadPlacesAutocomplete:self forInput:input];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    if (browserKey) {
        [parameters setObject:[NSString stringWithFormat:@"%@", browserKey] forKey:@"key"];
    }
    else if (self.googleAPIBrowserKey) {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIBrowserKey] forKey:@"key"];
    }
    else {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIClientID] forKey:@"client"];
    }
    
    [parameters setObject:[NSString stringWithFormat:@"%@", input] forKey:@"input"];
    [parameters setObject:[LPPrediction getStringFromGooglePlaceType:placeType] forKey:@"types"];
    [parameters setObject:[NSString stringWithFormat:@"%d", offset] forKey:@"offset"];
    [parameters setObject:[NSString stringWithFormat:@"%f,%f",location.latitude, location.longitude] forKey:@"location"];
    [parameters setObject:[NSString stringWithFormat:@"%@", self.languageCode] forKey:@"language"];
    
    if(countryRestriction) {
        [parameters setObject:[NSString stringWithFormat:@"country:%@", countryRestriction] forKey:@"components"];
    }
    
    [manager GET:[NSString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIPlacesAutocompleteURLPath] parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dictionary = responseObject;
        
        if ([dictionary isKindOfClass:[NSNull class]]
            || [[dictionary objectForKey:@"predictions"] isKindOfClass:[NSNull class]]
            || [[dictionary objectForKey:@"status"] isKindOfClass:[NSNull class]]) {
            
            if (failure)
                failure(LPGoogleStatusUnknownError);
        }
        else {
            
            NSString *statusCode = dictionary[@"status"];
            
            if ([statusCode isEqualToString:@"OK"]) {
                if ([self.delegate respondsToSelector:@selector(googleFunctions:didLoadPlacesAutocomplete:)]) {
                    [self.delegate googleFunctions:self didLoadPlacesAutocomplete:dictionary[@"predictions"]];
                }
                
                if (successful)
                    successful(dictionary[@"predictions"]);
            } else {
                LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:statusCode];
                
                if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingPlacesAutocompleteWithStatus:)]) {
                    [self.delegate googleFunctions:self errorLoadingPlacesAutocompleteWithStatus:status];
                }
                
                if (failure)
                    failure(status);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingPlacesAutocompleteWithStatus:)]) {
            [self.delegate googleFunctions:self errorLoadingPlacesAutocompleteWithStatus:LPGoogleStatusUnknownError];
        }
        
        if (failure)
            failure(LPGoogleStatusUnknownError);
    }];
}

- (void)loadPlacesAutocompleteForInput:(NSString *)input offset:(int)offset location:(LPLocation *)location radius:(int)radius isStrictBounds:(BOOL)isStrictBounds placeType:(LPGooglePlaceType)placeType countryRestriction:(NSString *)countryRestriction forceBrowserKey:(NSString *)browserKey successfulBlock:(void (^)(NSArray *placesAutocomplete))successful failureBlock:(void (^)(LPGoogleStatus status))failure {
    if ([self.delegate respondsToSelector:@selector(googleFunctionsWillLoadPlacesAutocomplete:forInput:)]) {
        [self.delegate googleFunctionsWillLoadPlacesAutocomplete:self forInput:input];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    if (browserKey) {
        [parameters setObject:[NSString stringWithFormat:@"%@", browserKey] forKey:@"key"];
    }
    else if (self.googleAPIBrowserKey) {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIBrowserKey] forKey:@"key"];
    }
    else {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIClientID] forKey:@"client"];
    }
    
    [parameters setObject:[NSString stringWithFormat:@"%@", input] forKey:@"input"];
    [parameters setObject:[LPPrediction getStringFromGooglePlaceType:placeType] forKey:@"types"];
    [parameters setObject:[NSString stringWithFormat:@"%d", offset] forKey:@"offset"];
    [parameters setObject:[NSString stringWithFormat:@"%f,%f",location.latitude, location.longitude] forKey:@"location"];
    [parameters setObject:[NSString stringWithFormat:@"%d", radius] forKey:@"radius"];
    [parameters setObject:[NSString stringWithFormat:@"%@", self.languageCode] forKey:@"language"];
    
    if(countryRestriction) {
        [parameters setObject:[NSString stringWithFormat:@"country:%@", countryRestriction] forKey:@"components"];
    }
    
    if (isStrictBounds) {
        [parameters setObject:@"" forKey:@"strictbounds"];
    }
    
    [manager GET:[NSString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIPlacesAutocompleteURLPath] parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *dictionary = responseObject;
        
        if ([dictionary isKindOfClass:[NSNull class]]
            || [[dictionary objectForKey:@"predictions"] isKindOfClass:[NSNull class]]
            || [[dictionary objectForKey:@"status"] isKindOfClass:[NSNull class]]) {
            
            if (failure)
                failure(LPGoogleStatusUnknownError);
        }
        else {
            
            NSString *statusCode = dictionary[@"status"];
            
            if ([statusCode isEqualToString:@"OK"]) {
                if ([self.delegate respondsToSelector:@selector(googleFunctions:didLoadPlacesAutocomplete:)]) {
                    [self.delegate googleFunctions:self didLoadPlacesAutocomplete:dictionary[@"predictions"]];
                }
                
                if (successful)
                    successful(dictionary[@"predictions"]);
            } else {
                LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:statusCode];
                
                if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingPlacesAutocompleteWithStatus:)]) {
                    [self.delegate googleFunctions:self errorLoadingPlacesAutocompleteWithStatus:status];
                }
                
                if (failure)
                    failure(status);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingPlacesAutocompleteWithStatus:)]) {
            [self.delegate googleFunctions:self errorLoadingPlacesAutocompleteWithStatus:LPGoogleStatusUnknownError];
        }
        
        if (failure)
            failure(LPGoogleStatusUnknownError);
    }];
}


- (void)loadPlaceDetailsForPlaceID:(NSString *)placeID forceBrowserKey:(NSString *)browserKey successfulBlock:(void (^)(LPPlaceDetailsResults *placeDetailsResults))successful failureBlock:(void (^)(LPGoogleStatus status))failure {
    if ([self.delegate respondsToSelector:@selector(googleFunctionsWillLoadPlaceDetailsResult:forPlaceID:)]) {
        [self.delegate googleFunctionsWillLoadPlaceDetailsResult:self forPlaceID:placeID];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    if (browserKey) {
        [parameters setObject:[NSString stringWithFormat:@"%@", browserKey] forKey:@"key"];
    }
    else if (self.googleAPIBrowserKey) {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIBrowserKey] forKey:@"key"];
    }
    else {
        [parameters setObject:[NSString stringWithFormat:@"%@", self.googleAPIClientID] forKey:@"client"];
    }
    
    [parameters setObject:[NSString stringWithFormat:@"%@", placeID] forKey:@"placeid"];
    [parameters setObject:[NSString stringWithFormat:@"%@", self.languageCode] forKey:@"language"];
    
    [manager GET:[NSString stringWithFormat:@"%@/%@?", googleAPIUri, googleAPIPlaceDetailsURLPath] parameters:parameters progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        LPPlaceDetailsResults *placeDetailsResults = [LPPlaceDetailsResults placeDetailsResultsWithObjects:responseObject];
        
        NSString *statusCode = placeDetailsResults.statusCode;
        
        if ([statusCode isEqualToString:@"OK"]) {
            if ([self.delegate respondsToSelector:@selector(googleFunctions:didLoadPlaceDetailsResult:)]) {
                [self.delegate googleFunctions:self didLoadPlaceDetailsResult:placeDetailsResults];
            }
            
            if (successful)
                successful(placeDetailsResults);
        } else {
            LPGoogleStatus status = [LPGoogleFunctions getGoogleStatusFromString:statusCode];
            
            if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingPlaceDetailsResultWithStatus:)]) {
                [self.delegate googleFunctions:self errorLoadingPlaceDetailsResultWithStatus:status];
            }
            
            if (failure)
                failure(status);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if ([self.delegate respondsToSelector:@selector(googleFunctions:errorLoadingPlacesAutocompleteWithStatus:)]) {
            [self.delegate googleFunctions:self errorLoadingPlaceDetailsResultWithStatus:LPGoogleStatusUnknownError];
        }
        
        if (failure)
            failure(LPGoogleStatusUnknownError);
    }];
}

@end
