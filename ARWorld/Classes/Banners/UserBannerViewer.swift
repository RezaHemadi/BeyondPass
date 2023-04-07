//
//  UserBannerViewer.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/7/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

class UserBannerViewer {
    
    // MARK: - Configuration
    
    // Search radius in meters
    let searchRadius: Double = 500
    
    // MARK: - Properties
    
    var currentUser: PFUser = { return PFUser.current()! }()
    
    /// Array to hold currently displayed user banners.
    var displayedBanners: [UserBanner] = []
    
    /// Array to hold currently displayed users
    var nearUsers: [PFUser] = []
    
    /// Array to hold users which are currently being updated
    var updatingUsers: [PFUser] = []
    
    /// location where near users was last updated
    private var lastUpdateLocation: CLLocation
    
    /// Location of the user which is updated constantly
    var location: CLLocation {
        willSet(newValue) {
            geoPoint = PFGeoPoint(location: newValue)
        }
        didSet {
            guard !isUpdating && location.distance(from: lastUpdateLocation) > 5 else { return }
    
            lastUpdateLocation = location
            updateBanners { (succeed) in
                    
            }
        }
    }
    
    /// Current GeoPoint
    var geoPoint: PFGeoPoint
    
    var delegate: UserBannerViewerDelegate?
    
    let updateQueue = DispatchQueue(label: "beyondPass.thingoTeam.userBannerSerial")
    
    var isUpdating: Bool = false
    
    // MARK: - Initialization
    init(location: CLLocation) {
        self.location = location
        lastUpdateLocation = location
        self.geoPoint = PFGeoPoint(location: location)
        updateBanners { (succeed) in
            
        }
    }
    
    // MARK: - Updating Near Users
    
    private func fetchNearUsers(_ completion: @escaping (_ users: [PFUser], _ error: Error?) -> Void) {
        var fetchedUsers: [PFUser] = []
        let userQuery = PFUser.query()
        userQuery?.whereKey("location", nearGeoPoint: geoPoint, withinKilometers: searchRadius / 1000)
        userQuery?.findObjectsInBackground {
            (objects, error) in
            if let objects = objects {
                fetchedUsers = objects.compactMap {
                    if $0.objectId != self.currentUser.objectId {
                        return $0 as? PFUser
                    }
                    return nil
                }
                
                completion(fetchedUsers, nil)
            } else if let error = error {
                completion(fetchedUsers, error)
            }
        }
    }
    
    // MARK: - Displaying and Removing Banners
    
    private func displayBanner(for user: PFUser) {
        if let geoPoint = user["location"] as? PFGeoPoint {
            let location = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
            let banner = UserBanner(id: user.objectId!, location: location)
            delegate?.userBannerViewer(self, shouldDisplay: banner)
            displayedBanners.append(banner)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Update the near users and determine if a user should be removed or added or updated
    private func updateBanners(_ completion: @escaping (_ succeed: Bool?) -> Void) {
        isUpdating = true
        fetchNearUsers() {
            (nearUsers: [PFUser], error: Error?) -> Void in
            guard error == nil else { completion(true); return }
            
            for nearUser in nearUsers {
                // Check if the user is already being updated.
                if self.isUserUpdating(nearUser)  { continue }
                
                // Check if a banner is displayed for this user.
                if self.isBannerAlreadyDisplayed(for: nearUser) {
                    // Update banner location
                    self.updateBanner(for: nearUser)
                } else {
                    // Add a banner for this user
                    self.displayBanner(for: nearUser)
                    self.nearUsers.append(nearUser)
                }
            }
            // Remove any extra banners
            /*
            for redundantBanner in self.redundantBanners(for: nearUsers) {
                self.delegate?.userBannerViewer(self, shouldRemove: redundantBanner)
                
                if let index = self.displayedBanners.index(of: redundantBanner) {
                    self.displayedBanners.remove(at: index)
                }
            } */
            self.isUpdating = false
            completion(true)
        }
    }
    
    private func isBannerAlreadyDisplayed(for user: PFUser) -> Bool {
        return displayedBanners.contains(where: {$0.id == user.objectId!})
    }
    private func updateBanner(for user: PFUser) {
        if let banner = displayedBanners.first(where: {$0.id == user.objectId!}) {
            
            let geoPoint = user["location"] as? PFGeoPoint
                    
            guard geoPoint != nil && !banner.isTargeted else { return }
                    
            let location = CLLocation.init(latitude: geoPoint!.latitude, longitude: geoPoint!.longitude)
            banner.location = location
                    
            delegate?.userBannerViewer(self, shouldUpdate: banner)
        }
    }
    func redundantBanners(for fetchedUsers: [PFUser]) -> [UserBanner] {
        return displayedBanners.compactMap {
            (banner: UserBanner) -> UserBanner? in
            if !fetchedUsers.contains(where: { $0.objectId == banner.id }) {
                return banner
            }
            return nil
        }
    }
    private func isUserUpdating(_ user: PFUser) -> Bool {
        return updatingUsers.contains(where: {$0.objectId! == user.objectId!})
    }
}
