//
//  JPSAssetsLibrary.m
//  Just Bucket
//
//  Created by Jonathan Sullivan on 8/3/13.
//  Copyright (c) 2013 Jonathan Sullivan. All rights reserved.
//

@import AVFoundation;
@import CoreImage;


#import "AppDelegate.h"
#import "JPSAssetsLibrary.h"


NSString * const kJPSAssetsLibraryChangeDetailsKey = @"JPSAssetsLibraryChangeDetails";
NSString * const kJPSAssestsLibraryDidChangeNotification = @"JPSAssestsLibraryDidChangeNotification";


@interface JPSAssetsLibrary () <PHPhotoLibraryChangeObserver>

@property (nonatomic, strong) PHAssetCollection * currentAssetCollection;
@property (nonatomic, strong) PHFetchResult * currentAssetCollectionAssetsFetchResult;

@end


@implementation JPSAssetsLibrary


#pragma mark - Initialization Methods

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
#ifdef DEBUG
        NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
        
        AppDelegate * appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        
        if (appDelegate.arePhotoServicesEnabled)
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    return self;
}

- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    
    AppDelegate * appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    if (appDelegate.arePhotoServicesEnabled)
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark -


#pragma mark - Actions

- (PHAssetCollection *)assetCollectionWithName:(NSString *)assetCollectionName
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    
    PHFetchOptions * fetchOptions = [[PHFetchOptions alloc] init];
    
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"localizedTitle == %@", assetCollectionName];
    fetchOptions.predicate = predicate;
    
    PHFetchResult * assetCollectionFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:fetchOptions];
    
    PHAssetCollection * assetCollection;
    
    if ([assetCollectionFetchResult count])
        assetCollection = (PHAssetCollection *)assetCollectionFetchResult[0];
    
    return assetCollection;
}

- (void)loadAssetCollectionWithName:(NSString *)assetCollectionName
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    
    self.currentAssetCollection = [self assetCollectionWithName:assetCollectionName];
    
    self.currentAssetCollectionAssetsFetchResult = [PHAsset fetchAssetsInAssetCollection:self.currentAssetCollection options:nil];
}

- (void)createAssetCollectionWithName:(NSString *)assetCollectionName completionHandler:(void(^)(BOOL success))completionHandler
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
    {
        [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:assetCollectionName];
    }
    completionHandler:^(BOOL success, NSError * error)
    {
        if (!success)
        {
#ifdef DEBUG
            NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
#endif
        }
        
        if (completionHandler)
            completionHandler(success);
    }];
}

- (void)saveImageWithInfo:(NSDictionary *)info assetCollection:(PHAssetCollection *)assetCollection completionHandler:(void(^)(BOOL success))completionHandler
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
    {
        if (!info[UIImagePickerControllerReferenceURL])
        {
            UIImage * originalImage = (UIImage *)info[UIImagePickerControllerOriginalImage];
            
            PHAssetChangeRequest * assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:originalImage];
            
            if (assetCollection)
            {
                PHAssetCollectionChangeRequest * assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                
                [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
            }
        }
        else {
            NSURL * assetURL = (NSURL *)info[UIImagePickerControllerReferenceURL];
            
            PHFetchResult * fetchResult = [PHAsset fetchAssetsWithALAssetURLs:@[assetURL] options:nil];
            
            if ([fetchResult count])
            {
                PHAsset * asset = [fetchResult firstObject];
                [self moveAsset:asset toAssetCollection:self.currentAssetCollection fromAssetCollection:nil completionHandler:completionHandler];
            }
        }
    }
    completionHandler:^(BOOL success, NSError * error)
    {
        if (!success)
        {
#ifdef DEBUG
            NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
#endif
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler)
                completionHandler(success);
        });
    }];
}

- (void)saveVideoWithInfo:(NSDictionary *)info assetCollection:(PHAssetCollection *)assetCollection completionHandler:(void(^)(BOOL success))completionHandler
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
     {
         if (!info[UIImagePickerControllerReferenceURL])
         {
             NSURL * fileURL = (NSURL *)info[UIImagePickerControllerMediaURL];
             
             PHAssetChangeRequest * assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
             
             if (assetCollection)
             {
                 PHAssetCollectionChangeRequest * assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                 
                 [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
             }
         }
         else {
             NSURL * assetURL = (NSURL *)info[UIImagePickerControllerReferenceURL];
             
             PHFetchResult * fetchResult = [PHAsset fetchAssetsWithALAssetURLs:@[assetURL] options:nil];
             
             if ([fetchResult count])
             {
                 PHAsset * asset = [fetchResult firstObject];
                 [self moveAsset:asset toAssetCollection:self.currentAssetCollection fromAssetCollection:nil completionHandler:completionHandler];
             }
         }
     }
     completionHandler:^(BOOL success, NSError * error)
     {
         if (!success)
         {
#ifdef DEBUG
             NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
#endif
         }
         
         dispatch_async(dispatch_get_main_queue(), ^{
             if (completionHandler)
                 completionHandler(success);
         });
     }];
}

- (void)moveAsset:(PHAsset *)asset toAssetCollection:(PHAssetCollection *)toAssetCollection fromAssetCollection:(PHAssetCollection *)fromAssetCollection completionHandler:(void(^)(BOOL success))completionHandler
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
     {
         if (toAssetCollection)
         {
             PHAssetCollectionChangeRequest * toAssetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:toAssetCollection];
             
             [toAssetCollectionChangeRequest addAssets:@[asset]];
         }
         
         if (fromAssetCollection)
         {
             PHAssetCollectionChangeRequest * fromAssetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:fromAssetCollection];
             
             [fromAssetCollectionChangeRequest removeAssets:@[asset]];
         }
     }
     completionHandler:^(BOOL success, NSError * error)
     {
         if (success)
         {
             PHFetchResult * fetchResult = [PHAsset fetchAssetsInAssetCollection:self.currentAssetCollection options:nil];
             
             if ([fetchResult count] <= 0)
             {
                 [self deleteAssetCollectionWithCompletionHandler:^(BOOL success)
                  {
                      dispatch_async(dispatch_get_main_queue(), ^{
                          if (completionHandler)
                              completionHandler(success);
                      });
                  }];
             }
             else {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if (completionHandler)
                         completionHandler(success);
                 });
             }
         }
         else {
#ifdef DEBUG
             NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
#endif
         }
     }];
}

- (void)deleteAssetCollectionWithCompletionHandler:(void(^)(BOOL success))completionHandler
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
     {
         if (self.currentAssetCollection) {
             [PHAssetCollectionChangeRequest deleteAssetCollections:@[self.currentAssetCollection]];
         }
     }
     completionHandler:^(BOOL success, NSError * error)
     {
         if (!success)
         {
#ifdef DEBUG
             NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
#endif
         }
         
         dispatch_async(dispatch_get_main_queue(), ^{
             if (completionHandler)
                 completionHandler(success);
         });
     }];
}

- (void)deleteAssets:(NSArray *)assets completionHandler:(void(^)(BOOL success))completionHandler
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
     {
         if (self.currentAssetCollection)
         {
             PHAssetCollectionChangeRequest * assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.currentAssetCollection];
             
             [assetCollectionChangeRequest removeAssets:assets];
         }
     }
     completionHandler:^(BOOL success, NSError * error)
     {
         if (success)
         {
             PHFetchResult * fetchResult = [PHAsset fetchAssetsInAssetCollection:self.currentAssetCollection options:nil];
             
             if ([fetchResult count] <= 0)
             {
                 [self deleteAssetCollectionWithCompletionHandler:^(BOOL success)
                 {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         if (completionHandler)
                             completionHandler(success);
                     });
                 }];
             }
             else {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if (completionHandler)
                         completionHandler(success);
                 });
             }
         }
         else {
#ifdef DEBUG
             NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
#endif
         }
     }];
}

- (void)renameAssetCollectionTo:(NSString *)assetCollectionName completionHandler:(void(^)(BOOL success))completionHandler
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^
     {
         if (self.currentAssetCollection)
         {
             PHAssetCollectionChangeRequest * assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self.currentAssetCollection];
             
             assetCollectionChangeRequest.title = assetCollectionName;
         }
     }
     completionHandler:^(BOOL success, NSError * error)
     {
         if (!success)
         {
#ifdef DEBUG
             NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
#endif
         }
         
         dispatch_async(dispatch_get_main_queue(), ^{
             if (completionHandler)
                 completionHandler(success);
         });
     }];
}

#pragma mark -


#pragma mark - PHPhotoLibraryChangeObserver Methods

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        PHFetchResultChangeDetails * changeDetails = [changeInstance changeDetailsForFetchResult:self.currentAssetCollectionAssetsFetchResult];
        
        if (changeDetails)
        {
            self.currentAssetCollectionAssetsFetchResult = [changeDetails fetchResultAfterChanges];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kJPSAssestsLibraryDidChangeNotification object:self userInfo:@{kJPSAssetsLibraryChangeDetailsKey: changeDetails}];
        }
    });
}

#pragma mark -


@end
