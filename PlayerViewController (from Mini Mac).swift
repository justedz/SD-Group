//
//  PlayerViewController.swift
//  SD Swift Group
//
//  Created by Edward Zeigler on 3/8/17.
//  Copyright © 2017 Ed Zeigler. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

class PlayerViewController: UIViewController, AVAudioPlayerDelegate {
    
    //iPadOutlets
    @IBOutlet var albumLabel: UILabel!
    @IBOutlet var titleArtistLabel: UILabel!
    @IBOutlet var trackProgressSlider: UISlider!
    @IBOutlet var tipTimerLabel: UILabel!
    @IBOutlet var sequenceTimerLabel: UILabel!
    @IBOutlet var playPauseOutlet: UIButton!
    @IBOutlet var adjustSettingsButtonOutlet: UIButton!
    
    //iPhoneOutlets
    @IBOutlet var iPhoneSequenceTimerLabel: UILabel!
    @IBOutlet var iPhonePlayPauseOutlet: UIButton!
    
    
    //setup variables to be used
    var playlist: MPMediaPlaylist?
    var trackNo = 0
    var audioPlayer: AVAudioPlayer?
    var dingAVPlayer: AVAudioPlayer?
    var zeroedValue = 0.0
    var tipTimerValue = 0.0
    var skipPreference = 0.0
    var tipTimerResetValue = 0.0
    var tipTimerResetPreference = 0.0
    var tipTimerRunningFlag: Bool = false
    var appTimer: Timer?
    var dingVolume: Float = 0
    var tipTimerOn = true
    var undoArray = [String]()
    var rewindAfterPauseValue = 0.0
    var currentPlaybackRate: Float = 1.0
    let phone = (UIDevice.current.userInterfaceIdiom == .phone) ? true : false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        loadDefaults()
        
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerViewController.defaultsChanged),name: UserDefaults.didChangeNotification, object: nil)
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        blueBackground()
        
        if audioPlayer == nil {
            setSongToPlay()
        }
        
        
        //#selector(self.appTimerCall)
//        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        
        //make ding not interrupt playback
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        
        //*** need to deal with resume action
        //*** temp, may be in appDelegate, application did finish launch with options to initially set timer
        tipTimerValue = tipTimerResetValue
        
        //only reset it if it is less than one (resume regardless of resume or not)
        if tipTimerValue < 1 {
            tipTimerValue = tipTimerResetValue
        }

        
        allUpdate(decrementTipTimer: false)
        
        if appTimer == nil {
            appTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: 	#selector(self.appTimerCall), userInfo: nil, repeats: true)
        }
        
        //setup ding file
        let dingSound = NSURL(fileURLWithPath: Bundle.main.path(forResource: "Ding", ofType:"mp3")!)
        try! dingAVPlayer = AVAudioPlayer(contentsOf: dingSound as URL)
        dingAVPlayer?.volume = dingVolume
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var detailPlaylist: MPMediaPlaylist? {
        didSet {
            playlist = detailPlaylist
        }
    }
    
    var trackNumber: Int = 0 {
        didSet {
            trackNo = trackNumber
        }
    }
    
    
    //MARK -  key commands
    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var keyCommands: [UIKeyCommand]? {
        var commands: [UIKeyCommand] = []
        let path = Bundle.main.path(forResource: "KeyCommands", ofType: "plist")
        let keyDict = NSDictionary(contentsOfFile: path!)
        for (key, action) in keyDict! {
            commands.append(UIKeyCommand(input: key as! String, modifierFlags: [], action: NSSelectorFromString(action as! String)))

        }
        //setup special keys
        commands.append(UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: [], action: #selector(PlayerViewController.skipBackAction)))
        commands.append(UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: [], action: #selector(PlayerViewController.skipForwardAction)))
        return commands
    }


    //MARK - Notification and timer calls
    func appDidBecomeActiveNotification(notification: NSNotification) -> () {
        setSongToPlay()
        audioPlayer?.currentTime = 5
        allUpdate(decrementTipTimer: false)
    }

 
    //MARK - Action Buttons
 
    @IBAction func iPadPlayPauseButton(_ sender: Any) {
        playPauseButtonAction()
    }
    @IBAction func iPhonePlayPauseButton(_ sender: Any) {
        playPauseButtonAction()
    }
    func playPauseButtonAction() {
        if  (audioPlayer?.isPlaying)! {
            audioPlayer?.pause()
            if phone {
                iPhonePlayPauseOutlet.setTitle("Play", for: .normal)
            } else {
                playPauseOutlet.setTitle("Play", for: .normal)
            }
        } else {
            rewindAfterPause()
            audioPlayer?.play()
            if phone {
                iPhonePlayPauseOutlet.setTitle("Pause", for: .normal)
            } else {
                playPauseOutlet.setTitle("Pause", for: .normal)
            }
            startTipTimer()
        }
    }
    
    @IBAction func previousTrackButton(_ sender: Any) {
        previousTrackAction()
    }
    @IBAction func iPhonePreviousTrackButton(_ sender: Any) {
        previousTrackAction()
    }
    func previousTrackAction() {
        let isPlaying = audioPlayer?.isPlaying
        
        if trackNo == 0 {
            audioPlayer?.stop()
            audioPlayer?.currentTime = 0
        } else {
            saveForUndo(action: "Previous Track")
            let newTrack = findNextOrPreviousTrack(incrementForward: false)
            if newTrack == trackNo {
                audioPlayer?.stop()
                audioPlayer?.currentTime = 0
            } else {
                trackNo = newTrack
                setSongToPlay()
            }
        }
        zeroedValue = (audioPlayer?.currentTime)!
        if isPlaying! {
            audioPlayer?.play()
        } else {
            audioPlayer?.stop()
        }
        allUpdate(decrementTipTimer: false)
    }
    
    @IBAction func nextTrackButton(_ sender: Any) {
        nextTrackAction()
    }
    @IBAction func iPhoneNextTrackButton(_ sender: Any) {
        nextTrackAction()
    }
    func nextTrackAction() {
        let isPlaying = audioPlayer?.isPlaying
        saveForUndo(action: "Next Track")
        let  newTrack = findNextOrPreviousTrack(incrementForward: true)
        if newTrack == trackNo {
            trackNo = -1
            trackNo = findNextOrPreviousTrack(incrementForward: true)
        } else {
            trackNo = newTrack
        }
        setSongToPlay()
        zeroedValue = 0
        if isPlaying! {
            audioPlayer?.play()
        } else {
            audioPlayer?.stop()
        }
        allUpdate(decrementTipTimer: false)
    }

    @IBAction func zeroButton(_ sender: Any) {
        zeroAction()
    }
    @IBAction func iPhoneZeroButton(_ sender: Any) {
        zeroAction()
    }
    func zeroAction() {
        saveForUndo(action: "Zero")
        zeroedValue = (audioPlayer?.currentTime)!
        allUpdate(decrementTipTimer: false)
        if tipTimerValue < 1 {
            tipTimerAction()
        }
    }
    
    @IBAction func overButton(_ sender: Any) {
        overAction()
    }
    @IBAction func iPhoneOverButton(_ sender: Any) {
        overAction()
    }
    func overAction() {
        saveForUndo(action: "Over")
        audioPlayer?.currentTime = zeroedValue
        allUpdate(decrementTipTimer: false)
    }
    
    @IBAction func skipBackButton(_ sender: Any) {
        skipBackAction()
    }
    @IBAction func iPhoneSkipBackButton(_ sender: Any) {
        skipBackAction()
    }
    func skipBackAction() {
        if (audioPlayer?.currentTime)! - skipPreference < 0 {
            audioPlayer?.currentTime = 0
        } else {
            audioPlayer?.currentTime = (audioPlayer?.currentTime)! - skipPreference
        }
        allUpdate(decrementTipTimer: false)
    }
    
    @IBAction func skipForwardButton(_ sender: Any) {
        skipForwardAction()
    }
    @IBAction func iPhoneSkipForwardButton(_ sender: Any) {
        skipForwardAction()
    }
    func skipForwardAction() {
        if (audioPlayer?.currentTime)! + skipPreference > (audioPlayer?.duration)! {
            nextTrackAction()
        } else {
            audioPlayer?.currentTime = (audioPlayer?.currentTime)! + skipPreference
        }
        allUpdate(decrementTipTimer: false)
    }
    
    @IBAction func tipTimerResetButton(_ sender: Any) {
        saveForUndo(action: "Tip Timer Reset")
        tipTimerAction()
    }
    func tipTimerAction() {
        tipTimerValue = tipTimerResetValue
        tipTimerRunningFlag = false
        tipTimerDisplay(time: tipTimerValue)
        blueBackground()
        if (audioPlayer?.isPlaying)! {
            tipTimerRunningFlag = true
        }
    }
    
    
    
    @IBAction func trackProgressChange(_ sender: Any) {
        audioPlayer?.currentTime = TimeInterval(trackProgressSlider.value)
    }
    
    @IBAction func undoButton(_ sender: Any) {
        // first stop everything!
        audioPlayer?.pause()
        tipTimerRunningFlag = false
        
        //nothing to undo that's stored
        if undoArray.count == 0 {
            let alert = UIAlertController(title: "Nothing to Undo!", message: "", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            // are you sure you want to undo?
            let title = String("Undo \(undoArray[0])")
            let alert = UIAlertController(title: title, message: "", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {action in self.alertUndo()}))
            self.present(alert, animated: true, completion: nil)
        }
    }
    

    @IBAction func doneButton(_ sender: Any) {
        doneAction()
    }
    @IBAction func iPhoneDoneButton(_ sender: Any) {
        doneAction()
    }
    func doneAction() {
        if (audioPlayer?.isPlaying)! {
            playPauseButtonAction()
        }
        tipTimerRunningFlag = false
        
        let alert = UIAlertController(title: "Close the Player", message: "", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: {action in self.alertClose()}))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK - Close Player
    func alertClose() {
        let defaults = UserDefaults.standard
        defaults.set(audioPlayer?.currentTime, forKey: "currentTime")
        defaults.set(trackNo, forKey: "trackNo")
        defaults.set(true, forKey: "playlistNotChanged")
        audioPlayer?.stop()
        undoArrayPurge()
        appTimer?.invalidate()
        dismiss(animated: true, completion: nil)
    }
    
 
    // MARK - Undo tools
    func alertUndo() {
        //First safe off current state unless you are Undoing and Undo
        if undoArray[0] != "Undo" {
            undoArrayAdd(action: "Undo")
        }
        
        // reset to previous state that was done
        if undoArray[0] == "Zero" {
            zeroedValue = Double(undoArray[1])!
        } else if undoArray[0] == "Tip" {
            tipTimerValue = Double(undoArray[3])!
        } else {
            // if track reset track and also playtime (repeat) below
            if (undoArray[0].range(of: "Track") != nil) {
                let trackToStore = Double(undoArray[2])
                trackNo = Int(trackToStore!)
                setSongToPlay()
            }
            // used for Repeat undo as well as track above
            audioPlayer?.currentTime = Double(undoArray[4])!
        }
        //clear off old part of array
        undoArrayPurge()
        // reset display
        allUpdate(decrementTipTimer: false)
    }

    /*
     Array of Strings undoArray:
     (0) Type of Action to undo
     (1) TimeInterval zeroedValue
     (2) int currentTrack
     (3) double tipTimerValue
     (4) double currentPlaybackTime
     */
    func saveForUndo(action: String) {
        undoArrayAdd(action: action)
        //purge prior data
        if undoArray.count > 5 {
            undoArrayPurge()
        }
    }
    
    func undoArrayAdd(action: String) {
        let currentPlaybackTime = audioPlayer?.currentTime ?? 0
        undoArray.append(action)
        undoArray.append(String("\(zeroedValue)"))
        undoArray.append(String("\(trackNo)"))
        undoArray.append(String("\(tipTimerValue)"))
        undoArray.append(String("\(currentPlaybackTime)"))
    }
    
    func undoArrayPurge() {
        for _ in 1...5 {
            if undoArray.count > 0 {
                undoArray.remove(at: 0)
            }
        }
    }
    
    
    // MARK - Updates
    
    func allUpdate(decrementTipTimer: Bool) -> () {
        if !phone {
            updateTrackPlaybackProgress()
            updateTrackInfo()
        }
        updatePlayPauseButton()
        updateSequenceTimer()
        if tipTimerOn {
            updateTipTimer(decrementTipTimer: decrementTipTimer)
        } else {
            tipTimerLabel.text = "Off"
            blueBackground()
        }
        updateTempDefaults()
    }
    
    
    func updateTrackPlaybackProgress() {
        trackProgressSlider.minimumValue = 0
        trackProgressSlider.maximumValue = Float((audioPlayer?.duration)!)
        trackProgressSlider.value = Float((audioPlayer?.currentTime)!)
    }
    
    func updateTrackInfo()  {
        let songNumber = trackNo + 1
        let totalSongs = playlist?.count ?? 0
        let albumTitle = songInfo(playlist: playlist!, track: trackNo).albumTitle ?? ""
        albumLabel.text = String("\(songNumber) of \(totalSongs) - \(albumTitle)")
        let title = songInfo(playlist: playlist!, track: trackNo).title ?? ""
        let artist = songInfo(playlist: playlist!, track: trackNo).artist ?? ""
        titleArtistLabel.text = String("\(title) - \(artist)")
    }

    func updatePlayPauseButton() {
        if (audioPlayer?.isPlaying)! {
            if phone {
                iPhonePlayPauseOutlet.setTitle("Pause", for: .normal)
            } else {
                playPauseOutlet.setTitle("Pause", for: .normal)
            }

        } else {
            if phone {
                iPhonePlayPauseOutlet.setTitle("Play", for: .normal)
            } else {
                playPauseOutlet.setTitle("Play", for: .normal)
            }
        }
    }
    
    func updateSequenceTimer() {
        let time = (audioPlayer?.currentTime)! - zeroedValue
        if phone {
            iPhoneSequenceTimerLabel.text = formatForLabel(time: time)
        } else {
            sequenceTimerLabel.text = formatForLabel(time: time)
        }
    }

    func updateTipTimer(decrementTipTimer: Bool) {
        //tip timer disabled, stop all and leave alone!!!
        if tipTimerResetValue == 0 {
            blueBackground()
            tipTimerDisplay(time: tipTimerResetValue)
            tipTimerRunningFlag = false
            
        //tip timer already at zero, keep red and no go and display
        } else if tipTimerValue == 0 {
            redBackground()
            tipTimerDisplay(time: tipTimerValue)
            tipTimerRunningFlag = false
        
        //tip timer zero'd and not playing, make blue, update display add Go
        } else if tipTimerValue == tipTimerResetValue && !(audioPlayer?.isPlaying)! && !tipTimerRunningFlag {
            blueBackground()
            tipTimerDisplay(time: tipTimerResetValue)
            tipTimerRunningFlag = false
            
        // if timer is 1 and button says Pause, zero, red, ding, hide button
        } else if tipTimerValue == 1 && tipTimerRunningFlag {
            tipTimerValue = 0
            tipTimerDisplay(time: tipTimerValue)
            redBackground()
            dingAVPlayer?.play()
            tipTimerRunningFlag = false
            
        //if timer greater than 1 and button says Pause, decrease by one, end
        } else if tipTimerValue  > 1 && tipTimerRunningFlag {
            blueBackground()
            if decrementTipTimer {
                tipTimerValue = tipTimerValue - 1
                tipTimerDisplay(time: tipTimerValue)
            }
        //all else
        } else {
            tipTimerDisplay(time: tipTimerValue)
            if tipTimerValue > 0 {
                blueBackground()
            } else {
                redBackground()
            }
        }
    }
    
    // just to save repeating if not phone for tip timer label
    func tipTimerDisplay(time: Double) {
        if !phone {
            tipTimerLabel.text = formatForLabel(time: time)
        }
    }
    
    func updateTempDefaults() {
        let defaults = UserDefaults.standard
        audioPlayer?.rate = defaults.float(forKey: "playbackRate")
        tipTimerResetValue = defaults.double(forKey: "tipTimerResetValue")
        let tipTimerOnOff = defaults.bool(forKey: "tipTimerOnOff")
        if tipTimerOnOff  && tipTimerLabel.text == "Off" {
            tipTimerValue = tipTimerResetValue
        } else if !tipTimerOnOff && !phone {
            tipTimerLabel.text = "Off"
        }
    }

    
    // MARK - settings/defaults functions
    
    func registerSettingsBundle(){
        let appDefaults = [String:AnyObject]()
        UserDefaults.standard.register(defaults: appDefaults)
        setupTempDefaults()
    }
    
    func defaultsChanged(){
        loadDefaults()
    }
    
    func loadDefaults() {
        let defaults = UserDefaults.standard
        UIApplication.shared.isIdleTimerDisabled = defaults.bool(forKey: "autolock_disable_preference")
        let defaultTipTimer = defaults.double(forKey: "tip_timer_preference")
        if tipTimerResetPreference != defaultTipTimer {
            tipTimerResetPreference = defaultTipTimer
            tipTimerResetValue = defaultTipTimer
        }
        skipPreference = defaults.double(forKey: "skip_interval_preference")
        rewindAfterPauseValue = defaults.double(forKey: "rewind_after_pause_preference")
        dingVolume = defaults.float(forKey: "bell_volume_for_tip_timer_preference")
        dingAVPlayer?.volume = dingVolume
    }
    
    func setupTempDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(1.0, forKey: "playbackSpeed")
        defaults.set(true, forKey: "tipTimerOnOff")
        defaults.set(tipTimerResetValue, forKey: "tipTimerResetValue")
    }

    
    // MARK - general functions
    
    func songInfo(playlist: MPMediaPlaylist, track: Int) -> MPMediaItem {
        let songs = playlist.items
        let song = songs[track]
        return song
    }
    
    func rewindAfterPause() {
        if rewindAfterPauseValue > 0 && ((audioPlayer?.currentTime)! - zeroedValue > 0) {
            if (audioPlayer?.currentTime)! - rewindAfterPauseValue < 0 {
                audioPlayer?.currentTime = 0
            } else if audioPlayer?.currentTime != zeroedValue {
                audioPlayer?.currentTime = (audioPlayer?.currentTime)! - rewindAfterPauseValue
            }
        }
        allUpdate(decrementTipTimer: false)
    }
    
    func startTipTimer() {
        if tipTimerResetValue != 0 {
            tipTimerRunningFlag = true
        }
    }
    
    func formatForLabel(time: TimeInterval) -> String {
        // added special handling for negative numbers
        let newTime = (time < 0) ? time * -1: time
        let minutes = floor(newTime / 60)
        let seconds = Int(round(newTime - minutes * 60))
        //make sure i don't have 60 for seconds
        let formattedSeconds = String(format: "%02d",seconds)
        let finalSecondsFormat = (formattedSeconds == "60") ?"00" : formattedSeconds
        //setup minutes, firt check for 60 seconds to add to mintues
        let adjustedMinutes = Int((formattedSeconds == "60") ? minutes + 1 : minutes)
        let formattedMinutes = String(format: "%02d", adjustedMinutes)
        
        let formattedString = (time < -0.4999999) ? String("-\(formattedMinutes):\(finalSecondsFormat)") : String("\(formattedMinutes):\(finalSecondsFormat)")
        
        return formattedString!
    }
    
    // if increment backward, send in false
    // returns next or previous track that isn't in icloud
    func findNextOrPreviousTrack(incrementForward: Bool) -> Int {
        var newTrack = trackNo
        repeat {
            newTrack = incrementForward ? newTrack + 1 : newTrack - 1
            if (incrementForward && newTrack > (playlist?.count)! - 1) || (!incrementForward && newTrack < 0) {
                newTrack = trackNo
                break
            }
        } while songInfo(playlist: playlist!, track: newTrack).isCloudItem
        
        return newTrack
    }
    
    func setSongToPlay() {
        let oldRate = audioPlayer?.rate
        let songs = playlist?.items
        let song = songs?[trackNo]
        let trackURL = song?.assetURL
        try! audioPlayer = AVAudioPlayer(contentsOf: trackURL!)
        audioPlayer?.enableRate = true
        if oldRate != nil {
            audioPlayer?.rate = oldRate!
        }
        audioPlayer?.delegate = self
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player == audioPlayer && moreTracks() {
            nextTrackAction()
            undoArrayPurge()
            audioPlayer?.play()
        }
        allUpdate(decrementTipTimer: false)
    }
    
    func appTimerCall(timer: Timer) -> () {
        allUpdate(decrementTipTimer: true)
        }

    func blueBackground() {
        view.backgroundColor = UIColor(patternImage: UIImage(named: "background_for_app.jpg")!)
    }
    
    func redBackground() {
        view.backgroundColor = UIColor(patternImage: UIImage(named: "red_background.jpg")!)
    }
    
    func moreTracks() -> Bool {
        let songs = playlist?.items
        return songs!.count > trackNo + 1 ? true : false
    }
}
