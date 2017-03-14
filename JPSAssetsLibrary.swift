//
//  JPSAssetsLibrary.swift
//  Just Bucket
//
//  Created by Jonathan Sullivan on 3/14/17.
//  Copyright © 2017 Jonathan Sullivan. All rights reserved.
//

import Photos
import CoreImage
import Foundation
import AVFoundation

@objc(JPSAssetsLibrary)
class JPSAssetsLibrary: NSObject
{
    fileprivate static let JPSAssetsLibraryChangeDetailsKey = Notification.Name("JPSAssetsLibraryChangeDetails")
    fileprivate static let JPSAssestsLibraryDidChangeNotification = Notification.Name("JPSAssestsLibraryDidChangeNotification")

    fileprivate var currentAssetCollection: PHAssetCollection?
    fileprivate var currentAssetCollectionAssetsFetchResult: PHFetchResult<PHAsset>?
    
    class func isPhotoLibraryAuthorized() -> Bool {
        return (PHPhotoLibrary.authorizationStatus() == .authorized)
    }
    
    override init()
    {
        super.init()
        
        if JPSAssetsLibrary.isPhotoLibraryAuthorized() {
            PHPhotoLibrary.shared().register(self)
        }
        
        print("(\((#file as NSString).lastPathComponent) \(#function))")
    }
    
    deinit
    {
        if JPSAssetsLibrary.isPhotoLibraryAuthorized() {
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
        
        print("(\((#file as NSString).lastPathComponent) \(#function))")
    }
    
    func assetCollection(with name: String) -> PHAssetCollection?
    {
        let fetchOptions = PHFetchOptions()

        let predicate = NSPredicate(format: "localizedTitle == %@", name)
        fetchOptions.predicate = predicate

        let assetCollectionFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)

        let assetCollection = assetCollectionFetchResult.firstObject

        print("(\((#file as NSString).lastPathComponent) \(#function))")
        
        return assetCollection
    }


    func loadAssetCollection(with name: String)
    {
        self.currentAssetCollection = self.assetCollection(with: name)

        self.currentAssetCollectionAssetsFetchResult = PHAsset.fetchAssets(in: self.currentAssetCollection!, options: nil)
    }

    func createAssetCollection(with name: String, completionHandler: ((Bool, Error?) -> Void)?)
    {
        PHPhotoLibrary.shared().performChanges({ 
            
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            
        }) { (success: Bool, error: Error?) in
            
            DispatchQueue.main.async { completionHandler?(success, error) }
        }
    }

    func saveImage(with info: Dictionary<String, Any>, assetCollection: PHAssetCollection, completionHandler: ((Bool, Error?) -> Void)?)
    {
        PHPhotoLibrary.shared().performChanges({
            
            if (info[UIImagePickerControllerReferenceURL] != nil)
            {
                let originalImage = (info[UIImagePickerControllerOriginalImage] as! UIImage)
                
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: originalImage)
                
                let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
                assetCollectionChangeRequest?.addAssets(NSArray(object: assetChangeRequest.placeholderForCreatedAsset!))
            }
            else {
                let assetURL = (info[UIImagePickerControllerReferenceURL] as! URL)
                let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [assetURL], options: nil)
                let asset = fetchResult.firstObject
                
                self.move(asset: asset!, to: self.currentAssetCollection!, from: nil, completionHandler: completionHandler)
            }
            
        }) { (success: Bool, error: Error?) in
            
            DispatchQueue.main.async { completionHandler?(success, error) }
        }
    }

    func saveVideo(with info: Dictionary<String, Any>, assetCollection: PHAssetCollection, completionHandler: ((Bool, Error?) -> Void)?)
    {
        PHPhotoLibrary.shared().performChanges({
            
            if (info[UIImagePickerControllerReferenceURL] != nil)
            {
                let fileURL = (info[UIImagePickerControllerMediaURL] as! URL)
                
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                
                let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
                assetCollectionChangeRequest?.addAssets(NSArray(object: assetChangeRequest!.placeholderForCreatedAsset!))
            }
            else {
                let assetURL = (info[UIImagePickerControllerReferenceURL] as! URL)
                let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [assetURL], options: nil)
                let asset = fetchResult.firstObject
                
                self.move(asset: asset!, to: self.currentAssetCollection!, from: nil, completionHandler: completionHandler)
            }
            
        }) { (success: Bool, error: Error?) in
            
            DispatchQueue.main.async { completionHandler?(success, error) }
        }
    }
    
    func move(asset: PHAsset, to newAssetCollection: PHAssetCollection?, from oldAssetCollection: PHAssetCollection?, completionHandler: ((Bool, Error?) -> Void)?)
    {
        PHPhotoLibrary.shared().performChanges({
            
            if let _ = newAssetCollection
            {
                let newAssetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: newAssetCollection!)
                
                newAssetCollectionChangeRequest!.addAssets(NSArray(object: asset))
            }
            
            if let _ = oldAssetCollection
            {
                let oldAssetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: oldAssetCollection!)
                
                oldAssetCollectionChangeRequest!.removeAssets(NSArray(object: asset))
            }
            
        }) { (success: Bool, error: Error?) in
    
            DispatchQueue.main.async
            {
                if (success)
                {
                    let fetchResult = PHAsset.fetchAssets(in: self.currentAssetCollection!, options: nil)
                    
                    if (fetchResult.count == 0) {
                        self.deleteAssetCollection(with: completionHandler)
                    }
                    else { completionHandler?(success, error) }
                }
            }
        }
    }

    func deleteAssetCollection(with completionHandler: ((Bool, Error?) -> Void)?)
    {
        PHPhotoLibrary.shared().performChanges({
            
            PHAssetCollectionChangeRequest.deleteAssetCollections(NSArray(object: self.currentAssetCollection!))
            
        }) { (success: Bool, error: Error?) in
            
            DispatchQueue.main.async { completionHandler?(success, error) }
        }
    }
    
    func deleteAssets(assets: Array<PHAsset>, completionHandler: ((Bool, Error?) -> Void)?)
    {
        PHPhotoLibrary.shared().performChanges({
            
            if let _ = self.currentAssetCollection
            {
                let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: self.currentAssetCollection!)
                
                assetCollectionChangeRequest!.removeAssets(NSArray(object: assets))
            }
            
        }) { (success: Bool, error: Error?) in
            
            DispatchQueue.main.async
            {
                if success
                {
                    let fetchResult = PHAsset.fetchAssets(in: self.currentAssetCollection!, options: nil)
                    
                    if (fetchResult.count == 0) {
                        self.deleteAssetCollection(with: completionHandler)
                    }
                    else { completionHandler?(success, error) }
                }
            }
        }
    }

    func renameAssetCollection(to name: String, completionHandler: ((Bool, Error?) -> Void)?)
    {
        PHPhotoLibrary.shared().performChanges({
            
            let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: self.currentAssetCollection!)
            assetCollectionChangeRequest!.title = name

            
        }) { (success: Bool, error: Error?) in
            
            DispatchQueue.main.async { completionHandler?(success, error) }
        }
    }
}

extension JPSAssetsLibrary: PHPhotoLibraryChangeObserver
{
    public func photoLibraryDidChange(_ changeInstance: PHChange)
    {
        DispatchQueue.main.async
        {
            let changeDetails = changeInstance.changeDetails(for: self.currentAssetCollectionAssetsFetchResult!)
            
            guard let _ = changeDetails else { return }
            
            self.currentAssetCollectionAssetsFetchResult = changeDetails!.fetchResultAfterChanges
            
            NotificationCenter.default.post(name: JPSAssetsLibrary.JPSAssestsLibraryDidChangeNotification, object: self, userInfo:[kJPSAssetsLibraryChangeDetailsKey: changeDetails!])
        }
    }
}
