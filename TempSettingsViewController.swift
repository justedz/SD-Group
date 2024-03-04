//
//  TempSettingsViewController.swift
//  SD Group
//
//  Created by Edward Zeigler on 3/14/17.
//  Copyright © 2017 Ed Zeigler. All rights reserved.
//

import UIKit

class TempSettingsViewController: UIViewController {

    @IBOutlet var tempTipTimerLabel: UILabel!
    @IBOutlet var tempTipTimerStepper: UIStepper!
    @IBOutlet var tempOnOff: UISwitch!
    @IBOutlet var tempPlaybackSpeedLabel: UILabel!
    @IBOutlet var tempPlaybackSpeedStepper: UIStepper!

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let defaults = UserDefaults.standard
        var playbackSpeed = defaults.value(forKey: "playbackRate") == nil ? 1.0 : defaults.double(forKey: "playbackRate")
        if playbackSpeed < 0.49 {
            playbackSpeed = 1.0
        }
        let tipTimerOnOff = defaults.bool(forKey: "tipTimerOnOff")
        let tipTimerResetValue = String(format: "%.0f",defaults.double(forKey: "tipTimerResetValue") / 60)
        tempPlaybackSpeedLabel.text = formatPlaybackRate(rate: playbackSpeed)
        tempOnOff.isOn = tipTimerOnOff
        tempTipTimerLabel.text = String("\(tipTimerResetValue):00")
        tempTipTimerStepper.value = defaults.double(forKey: "tipTimerResetValue")
    }
    
    
    @IBAction func tipTimerChange(_ sender: Any) {
// temp to clean up a prior build, can be replaced by the line below
        let tipTimerNewValue = Int(round(Double(tempTipTimerStepper.value / 60))) * 60
//        let tipTimerNewValue = tempTipTimerStepper.value
        let defaults = UserDefaults.standard
        defaults.set(tipTimerNewValue, forKey: "tipTimerResetValue")
        let displayValue = String("\(tipTimerNewValue / 60):00")
        tempTipTimerLabel.text = displayValue
    }
    
    @IBAction func tipTimerOnOffChange(_ sender: Any) {
        let tipTimerOnOff = tempOnOff.isOn
        let defaults = UserDefaults.standard
        defaults.set(tipTimerOnOff, forKey: "tipTimerOnOff")
    }

    @IBAction func playbackSpeedChange(_ sender: Any) {
        let actualSpeed = tempPlaybackSpeedStepper.value
        tempPlaybackSpeedLabel.text = formatPlaybackRate(rate: actualSpeed)
        let defaults = UserDefaults.standard
        defaults.set(actualSpeed, forKey: "playbackRate")
    }
    
    @IBAction func resume100Percent(_ sender: Any) {
        tempPlaybackSpeedStepper.value = 1
        tempPlaybackSpeedLabel.text = formatPlaybackRate(rate: 1)
        let defaults = UserDefaults.standard
        defaults.set(1.0, forKey: "playbackRate")
    }
    func formatPlaybackRate(rate: Double) -> String {
        let displayRate = String(format: "%.0f", rate * 100)
        return String("\(displayRate)%")
    }
    
}
