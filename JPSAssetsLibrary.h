//
//  JPSAssetsLibrary.h
//  Just Bucket
//
//  Created by Jonathan Sullivan on 8/3/13.
//  Copyright (c) 2013 Jonathan Sullivan. All rights reserved.
//

@import AssetsLibrary;
@import MediaPlayer;
@import Photos;


extern NSString * const kJPSAssetsLibraryChangeDetailsKey;
extern NSString * const kJPSAssestsLibraryDidChangeNotification;


@interface JPSAssetsLibrary : NSObject

@property (strong, nonatomic, readonly) PHAssetCollection * currentAssetCollection;
@property (strong, nonatomic, readonly) PHFetchResult * currentAssetCollectionAssetsFetchResult;


+ (BOOL)isPhotoLibraryAuthorized;

- (PHAssetCollection *)assetCollectionWithName:(NSString *)assetCollectionName;

- (void)loadAssetCollectionWithName:(NSString *)assetCollectionName;

- (void)createAssetCollectionWithName:(NSString *)assetCollectionName completionHandler:(void(^)(BOOL success))completionHandler;

- (void)saveImageWithInfo:(NSDictionary *)info assetCollection:(PHAssetCollection *)assetCollection completionHandler:(void(^)(BOOL success))completionHandler;

- (void)saveVideoWithInfo:(NSDictionary *)info assetCollection:(PHAssetCollection *)assetCollection completionHandler:(void(^)(BOOL success))completionHandler;

- (void)moveAsset:(PHAsset *)asset toAssetCollection:(PHAssetCollection *)toAssetCollection fromAssetCollection:(PHAssetCollection *)fromAssetCollection completionHandler:(void(^)(BOOL success))completionHandler;

- (void)deleteAssetCollectionWithCompletionHandler:(void(^)(BOOL success))completionHandler;

- (void)deleteAssets:(NSArray *)assets completionHandler:(void(^)(BOOL success))completionHandler;

- (void)renameAssetCollectionTo:(NSString *)assetCollectionName completionHandler:(void(^)(BOOL success))completionHandler;

@end
