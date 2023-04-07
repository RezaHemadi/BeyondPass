//
//  UserBannerViewerDelegate.swift
//  ARWorld
//
//  Created by Reza Hemadi on 4/9/18.
//  Copyright © 2018 ArvandGroup. All rights reserved.
//

import Foundation

protocol UserBannerViewerDelegate {
    func userBannerViewer(_ userBannerViewer: UserBannerViewer, shouldDisplay banner: UserBanner) -> Bool
    func userBannerViewer(_ userBannerViewer: UserBannerViewer, shouldRemove banner: UserBanner)
    func userBannerViewer(_ userBannerViewer: UserBannerViewer, shouldUpdate banner: UserBanner)
}
