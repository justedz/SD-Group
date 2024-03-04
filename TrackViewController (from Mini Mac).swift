//
//  TrackViewController.swift
//  SD Swift Group
//
//  Created by Edward Zeigler on 3/7/17.
//  Copyright © 2017 Ed Zeigler. All rights reserved.
//

import UIKit
import MediaPlayer

class TrackViewController: UITableViewController {
    
    
    var playlist: MPMediaPlaylist? = nil
    @IBOutlet var resumeButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let defaults = UserDefaults.standard
        let trackNo = defaults.integer(forKey: "trackNo")
        let playlistNotChanged = defaults.bool(forKey: "playlistNotChanged")
        
        if playlistNotChanged {
            // look up row in dictionary and set index path
            let selectedIndexPath = IndexPath(row: trackNo, section: 0)
            tableView.selectRow(at: selectedIndexPath, animated: true, scrollPosition: UITableViewScrollPosition.middle)
            resumeButton.isEnabled = true
            resumeButton.title = "Resume >"
        } else {
            resumeButton.isEnabled = false
            resumeButton.title = ""
        }
    }
    
    var detailTrack: MPMediaPlaylist? {
        didSet {
            playlist = detailTrack
        }
    }
    
    @IBAction func resumeAction(_ sender: Any) {
        if (UIDevice.current.userInterfaceIdiom == .phone) {
            performSegue(withIdentifier: "iPhoneSegue", sender: self)
        } else {
            performSegue(withIdentifier: "iPadSegue", sender: self)
        }
    }
    
    
    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if self.tableView.indexPathForSelectedRow != nil {
            let controller = segue.destination as! PlayerViewController
            let trackNumber = self.tableView.indexPathForSelectedRow?.row
            
            controller.detailPlaylist = self.playlist
            controller.trackNumber = trackNumber!
        }
    }
    
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (playlist != nil) ? playlist!.count: 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let songs = self.playlist?.items
        let song = songs?[indexPath.row]
        let space = (indexPath.row + 1 < 10) ? "  " : ""
        let songNumber = indexPath.row + 1
        let albumTitle = song?.albumTitle ?? ""
        let playCount = song?.playCount ?? 0
        let header = String(format: "\(space)\(songNumber). \(albumTitle) (\(playCount))")
        cell.textLabel?.text = header
        let title = song?.title ?? ""
        let artist = song?.artist ?? ""
        
        cell.detailTextLabel?.text = String(format: "         %@ - %@", (title), (artist))
        if (song?.isCloudItem)! {
            cell.selectionStyle = .none
            cell.textLabel?.textColor = UIColor.gray
        } else {
            cell.selectionStyle = .default
            cell.textLabel?.textColor = UIColor.black
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let trackNumber = indexPath.row
        let songs = playlist?.items
        let song = songs?[trackNumber]
        return (song?.isCloudItem)! ? nil : indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (UIDevice.current.userInterfaceIdiom == .phone) {
            performSegue(withIdentifier: "iPhoneSegue", sender: self)
        } else {
            performSegue(withIdentifier: "iPadSegue", sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
}

