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
    static let changeInstanceKey = "JPSAssetsLibraryChangeInstance"
    static let didChangeNotification = Notification.Name("JPSAssestsLibraryDidChangeNotification")
    
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

    func createAssetCollection(_ name: String, completionHandler: ((Bool, Error?) -> Void)?)
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
                
                self.moveAsset(asset!, to: assetCollection, from: nil, completionHandler: completionHandler)
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
                
                self.moveAsset(asset!, to: assetCollection, from: nil, completionHandler: completionHandler)
            }
            
        }) { (success: Bool, error: Error?) in
            
            DispatchQueue.main.async { completionHandler?(success, error) }
        }
    }
    
    func moveAsset(_ asset: PHAsset, to newAssetCollection: PHAssetCollection?, from oldAssetCollection: PHAssetCollection?, completionHandler: ((Bool, Error?) -> Void)?)
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
                if success && oldAssetCollection != nil
                {
                    let fetchResult = PHAsset.fetchAssets(in: oldAssetCollection!, options: nil)
                    
                    if (fetchResult.count == 0) {
                        self.deleteAssetCollection(oldAssetCollection!, completionHandler: completionHandler)
                    }
                    else { completionHandler?(success, error) }
                }
                else { completionHandler?(success, error) }
            }
        }
    }

    func deleteAssetCollection(_ assetCollection: PHAssetCollection, completionHandler: ((Bool, Error?) -> Void)?)
    {
        PHPhotoLibrary.shared().performChanges({
            
            PHAssetCollectionChangeRequest.deleteAssetCollections(NSArray(object: assetCollection))
            
        }) { (success: Bool, error: Error?) in
            
            DispatchQueue.main.async { completionHandler?(success, error) }
        }
    }
    
    func deleteAssets(_ assets: Array<PHAsset>, in assetCollection: PHAssetCollection, completionHandler: ((Bool, Error?) -> Void)?)
    {
        PHPhotoLibrary.shared().performChanges({
            
            let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
            assetCollectionChangeRequest!.removeAssets(NSArray(object: assets))
            
        }) { (success: Bool, error: Error?) in
            
            DispatchQueue.main.async
            {
                if success
                {
                    let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
                    
                    if (fetchResult.count == 0) {
                        self.deleteAssetCollection(assetCollection, completionHandler: completionHandler)
                    }
                    else { completionHandler?(success, error) }
                }
            }
        }
    }

    func renameAssetCollection(_ assetCollection: PHAssetCollection, to name: String, completionHandler: ((Bool, Error?) -> Void)?)
    {
        PHPhotoLibrary.shared().performChanges({
            
            let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
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
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: JPSAssetsLibrary.didChangeNotification, object: self, userInfo:[JPSAssetsLibrary.changeInstanceKey: changeInstance])
        }
    }
}
