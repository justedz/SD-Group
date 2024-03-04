//
//  MyPlaylistStore.swift
//  SD Group
//
//  Created by Edward Zeigler on 3/27/17.
//  Copyright © 2017 Ed Zeigler. All rights reserved.
//

import UIKit
import MediaPlayer

class MyPlaylistStore {
    var allPlaylists = [MyPlaylist]()
    
    init() {
        
    }
    
    func addPlaylist(playlist: MPMediaPlaylist) {
        let newPlaylist = MyPlaylist.init(playlist: playlist)
        allPlaylists.append(newPlaylist)
    }
    
    func removePlaylist(index: Int) {
        allPlaylists.remove(at: index)
    }
    
    func clearAllPlaylists () {
        allPlaylists.removeAll()
    }
    
    
}
