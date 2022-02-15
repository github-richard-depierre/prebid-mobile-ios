/*   Copyright 2018-2021 Prebid.org, Inc.
 
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
 
  http://www.apache.org/licenses/LICENSE-2.0
 
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  */

import Foundation

public class MediationNativeAdUnit : NSObject {
    
    var completion: ((ResultCode) -> Void)?
    let mediationDelegate: PrebidMediationDelegate
    
    // MARK: - Public Properties
    
    public var nativeAdUnit: NativeRequest
    
    var configID: String
    
    // MARK: - Public Methods
    public init(configId: String, mediationDelegate: PrebidMediationDelegate) {
        self.configID = configId
        self.mediationDelegate = mediationDelegate
        self.nativeAdUnit = NativeRequest(configId: configId)
    }
    
    public func addEventTracker(_ eventTrackers: [NativeEventTracker]) {
        nativeAdUnit.addNativeEventTracker(eventTrackers)
    }
    
    public func addNativeAssets(_ assets: [NativeAsset]) {
        nativeAdUnit.addNativeAssets(assets)
    }
    
    public func setContextType(_ contextType: ContextType) {
        nativeAdUnit.context = contextType
    }
    
    public func setPlacementType(_ placementType: PlacementType) {
        nativeAdUnit.placementType = placementType
    }
    
    public func setPlacementCount(_ placementCount: Int) {
        nativeAdUnit.placementCount = placementCount
    }
    
    public func setContextSubType(_ contextSubType: ContextSubType) {
        nativeAdUnit.contextSubType = contextSubType
    }
    
    public func setSequence(_ sequence: Int) {
        nativeAdUnit.sequence = sequence
    }
    
    public func setAssetURLSupport(_ assetURLSupport: Int) {
        nativeAdUnit.asseturlsupport = assetURLSupport
    }
    
    public func setDURLSupport(_ dURLSupport: Int) {
        nativeAdUnit.durlsupport = dURLSupport
    }
    
    public func setPrivacy(_ privacy: Int) {
        nativeAdUnit.privacy = privacy
    }
    
    public func setExt(_ ext: AnyObject) {
        nativeAdUnit.ext = ext
    }
    
    public func fetchDemand(completion: ((ResultCode)->Void)?) {
        
        self.completion = completion
        
        mediationDelegate.cleanUpAdObject()
        
        nativeAdUnit.fetchDemand { [weak self] result, kvResultDict in
            guard let self = self else {
                return
            }
            
            guard result == .prebidDemandFetchSuccess else {
                self.completeWithResult(result)
                return
            }
            
            guard let kvResultDict = kvResultDict,
                  let cacheId = kvResultDict["hb_cache_id_local"],
                  CacheManager.shared.isValid(cacheId: cacheId) else {
                      PBMLog.error("\(String(describing: self)): no cache in kvResultDict.")
                      return
                  }
            
            guard let bidString = CacheManager.shared.get(cacheId: cacheId) else {
                PBMLog.error("\(String(describing: self)): no bid for given cache id.")
                return
            }
            
            guard var fetchDemandInfo = Utils.shared.getDictionaryFromString(bidString) else {
                PBMLog.error("\(String(describing: self)): parsing bid string to bid dictionary failed.")
                return
            }
            
            fetchDemandInfo[PrebidLocalCacheIdKey] = cacheId as AnyObject
            
            var fetchDemandResult: ResultCode = .prebidUnknownError
        
            if self.mediationDelegate.setUpAdObject(configId: self.configID,
                                                    configIdKey: PBMMediationConfigIdKey,
                                                    targetingInfo: kvResultDict,
                                                    extrasObject: fetchDemandInfo,
                                                    extrasObjectKey: PBMMediationAdNativeResponseKey) {
                fetchDemandResult = .prebidDemandFetchSuccess
            }
            
            self.completeWithResult(fetchDemandResult)
        }
    }
    
    // MARK: - Private Methods
    
    private func completeWithResult(_ fetchDemandResult: ResultCode) {
        guard let completion = self.completion else {
            return
        }
        
        DispatchQueue.main.async {
            completion(fetchDemandResult)
        }
    }
}