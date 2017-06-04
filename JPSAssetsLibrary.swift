//
//  JPSPhotoLibrary.swift
//
//  Created by Jonathan Sullivan on 3/14/17.
//

import Photos
import CoreImage
import Foundation
import AVFoundation

@objc(JPSPhotoLibrary)
public class JPSPhotoLibrary: NSObject
{
    open class func isAuthorized() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    open required init()
    {
        super.init()
        
        print("(\(type(of: self)) \(#function))")
    }
    
    deinit { print("(\(type(of: self)) \(#function))") }
    
    fileprivate func save(alAssetAtURLs assetURLs: [URL], toAssetCollection: PHAssetCollection, completionHandler: ((Bool, Error?) -> Void)?)
    {
        let asset = PHAsset.fetchAssets(withALAssetURLs: assetURLs, options: nil).firstObject
        self.moveAsset(asset!, toAssetCollection: toAssetCollection, fromAssetCollection: nil, deleteIfEmpty: false, completionHandler: completionHandler)
    }
    
    fileprivate func saveAsset(withChangeRequest changeRequest: PHAssetChangeRequest, toAssetCollection: PHAssetCollection, completionHandler: ((Bool, Error?) -> Void)?)
    {
        let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: toAssetCollection)
        assetCollectionChangeRequest!.addAssets(NSArray(object: changeRequest.placeholderForCreatedAsset!))
    }
    
    fileprivate func deleteAssetCollectionIfEmpty(_ assetCollection, completionHandler: ((Bool, Error?) -> Void)?)
    {
        let fetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
        
        if fetchResult.count == 0 {
            self.delete(assetCollection: assetCollection, completionHandler: completionHandler)
        }
        else { completionHandler?(true, nil) }
    }
    
    @objc(assetCollectionWithName:fetchOptions:)
    open func assetCollection(withName name: String, fetchOptions: PHFetchOptions) -> PHAssetCollection?
    {
        print("(\(type(of: self)) \(#function))")
        
        let predicate = NSPredicate(format: "localizedTitle == %@", name)
        fetchOptions.predicate = predicate

        let assetCollectionFetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
        return assetCollectionFetchResult.firstObject
    }

    @objc(createAssetCollectionWithName:completionHandler:)
    open func createAssetCollection(withName name: String, completionHandler: ((Bool, Error?) -> Void)?)
    {
        print("(\(type(of: self)) \(#function))")
        
        PHPhotoLibrary.shared().performChanges({ 
            
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            
        }) { (success: Bool, error: Error?) in
            DispatchQueue.main.async { completionHandler?(success, error) }
        }
    }

    @objc(deleteAssetCollection:completionHandler:)
    open func delete(assetCollection: PHAssetCollection, completionHandler: ((Bool, Error?) -> Void)?)
    {
        print("(\(type(of: self)) \(#function))")
        
        PHPhotoLibrary.shared().performChanges({
            
            PHAssetCollectionChangeRequest.deleteAssetCollections(NSArray(object: assetCollection))
            
        }) { (success: Bool, error: Error?) in
            DispatchQueue.main.async { completionHandler?(success, error) }
        }
    }
    
    @objc(saveImageWithInfo:toAssetCollection:completionHandler:)
    open func saveImage(withInfo info: Dictionary<String, Any>, toAssetCollection: PHAssetCollection, completionHandler: ((Bool, Error?) -> Void)?)
    {
        print("(\(type(of: self)) \(#function))")
        
        PHPhotoLibrary.shared().performChanges({
            
            if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage
            {
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: originalImage)
                self.saveAsset(withChangeRequest: assetChangeRequest!, toAssetCollection:  toAssetCollection)
            }
            else if let assetURL = info[UIImagePickerControllerReferenceURL] as? URL {
                self.save(alAssetAtURLs: [assetURL], toAssetCollection: toAssetCollection)
            }
            
        }) { (success: Bool, error: Error?) in
            DispatchQueue.main.async { completionHandler?(success, error) }
        }
    }

    @objc(saveVideoWithInfo:toAssetCollection:completionHandler:)
    open func saveVideo(with info: Dictionary<String, Any>, toAssetCollection: PHAssetCollection, completionHandler: ((Bool, Error?) -> Void)?)
    {
        print("(\(type(of: self)) \(#function))")
        
        PHPhotoLibrary.shared().performChanges({
            
            if let mediaURL = info[UIImagePickerControllerMediaURL] as? URL
            {
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: mediaURL)
                self.saveAsset(withChangeRequest: assetChangeRequest!, toAssetCollection:  toAssetCollection)
            }
            else if let assetURL = info[UIImagePickerControllerReferenceURL] as? URL {
                self.save(alAssetAtURLs: [assetURL], toAssetCollection: toAssetCollection)
            }
            
        }) { (success: Bool, error: Error?) in
            DispatchQueue.main.async { completionHandler?(success, error) }
        }
    }
    
    @objc(moveAsset:toAssetCollection:fromAssetCollection:deleteIfEmpty:completionHandler:)
    open func move(asset: PHAsset, toAssetCollection: PHAssetCollection?, fromAssetCollection: PHAssetCollection?, deleteIfEmpty: Bool, completionHandler: ((Bool, Error?) -> Void)?)
    {
        print("(\(type(of: self)) \(#function))")
        
        PHPhotoLibrary.shared().performChanges({
            
            if let newAssetCollection = toAssetCollection
            {
                let newAssetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: newAssetCollection)
                newAssetCollectionChangeRequest!.addAssets(NSArray(object: asset))
            }
            
            if let oldAssetCollection = fromAssetCollection
            {
                let oldAssetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: oldAssetCollection)
                oldAssetCollectionChangeRequest!.removeAssets(NSArray(object: asset))
            }
            
        }) { (success: Bool, error: Error?) in
    
            DispatchQueue.main.async
            {
                if let oldAssetCollection = fromAssetCollection, success, deleteIfEmpty {
                    self.deleteAssetCollectionIfEmpty(oldAssetCollection, completionHandler: completionHandler)
                }
                else { completionHandler?(success, error) }
            }
        }
    }
    
    @objc(deleteAssets:fromAssetCollection:deleteIfEmpty:completionHandler:)
    open func delete(assets: [PHAsset], fromAssetCollection: PHAssetCollection, deleteIfEmpty: Bool, completionHandler: ((Bool, Error?) -> Void)?)
    {
        print("(\(type(of: self)) \(#function))")
        
        PHPhotoLibrary.shared().performChanges({
            
            let changeRequest = PHAssetCollectionChangeRequest(for: fromAssetCollection)
            changeRequest!.removeAssets(NSArray(object: assets))
            
        }) { (success: Bool, error: Error?) in
            
            DispatchQueue.main.async
            {
                if success && deleteIfEmpty {
                    self.deleteAssetCollectionIfEmpty(fromAssetCollection, completionHandler: completionHandler)
                }
                else { completionHandler?(success, error) }
            }
        }
    }

    @objc(renameAssetCollection:toName:completionHandler:)
    open func rename(assetCollection: PHAssetCollection, toName name: String, completionHandler: ((Bool, Error?) -> Void)?)
    {
        print("(\(type(of: self)) \(#function))")
        
        PHPhotoLibrary.shared().performChanges({
            
            let changeRequest = PHAssetCollectionChangeRequest(for: assetCollection)
            changeRequest!.title = name

        }) { (success: Bool, error: Error?) in
            DispatchQueue.main.async { completionHandler?(success, error) }
        }
    }
}
