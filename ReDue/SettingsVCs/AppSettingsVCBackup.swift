////
////  AppSettingsViewController.swift
////  RepeatingTasks
////
////  Created by Chase Peers on 8/28/17.
////  Copyright © 2017 Chase Peers. All rights reserved.
////
//
//import Foundation
//import UIKit
//import Chameleon
//import StoreKit
//import SwiftyBeaver
//
//class AppSettingsViewController: UITableViewController {
//
//    //MARK: - Outlets
//
//    @IBOutlet weak var setColorLabel: UILabel!
//    @IBOutlet weak var setProgressStyleLabel: UILabel!
//    @IBOutlet weak var setResetTimeLabel: UILabel!
//    @IBOutlet var nightModeSwitch: UISwitch!
//    @IBOutlet weak var footerText: UILabel!
//    @IBOutlet weak var purchaseButton: UIButton!
//    @IBOutlet weak var restoreButton: UIButton!
//
//    //MARK: - Properties
//
//    let log = SwiftyBeaver.self
//
//    var appData = AppData()
//    let sectionHeaderTitleArray = ["Themes and Color", "Task View", "Task Reset", "Unlock Full Version"]
//
//    var productID = ""
//    var productsRequest = SKProductsRequest()
//    var products = [SKProduct]()
//    //    var purchaseButtonInfo: UIButton = {
//    //        let button = UIButton(type: UIButtonType.system)
//    //        button.frame = CGRect(x: 0, y: 0, width: 150, height: 40)
//    //        button.setTitle("Unlock Full Version", for: .normal)
//    //        button.addTarget(self, action: #selector(purchaseAction), for: .touchUpInside)
//    //        return button
//    //    }()
//    //
//    //    var restoreButtonInfo: UIButton = {
//    //        let button = UIButton(type: UIButtonType.system)
//    //        button.frame = CGRect(x: 0, y: 0, width: 150, height: 40)
//    //        button.setTitle("Restore Purchase", for: .normal)
//    //        button.addTarget(self, action: #selector(restoreAction), for: .touchUpInside)
//    //        return button
//    //    }()
//
//    //MARK: - View and Basic Functions
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        setColorLabel.text = appData.appColorName
//        print(appData.appColorName)
//
//        nightModeSwitch.isOn = false
//        nightModeSwitch.isEnabled = false
//
//        title = "Application Settings"
//
//        purchaseButton.setTitle("Unlock Full Version", for: .normal)
//        purchaseButton.addTarget(self, action: #selector(purchaseAction), for: .touchUpInside)
//        restoreButton.setTitle("Restore Purchase", for: .normal)
//        restoreButton.addTarget(self, action: #selector(restoreAction), for: .touchUpInside)
//
//        //        purchaseButton = purchaseButtonInfo
//        //        restoreButton = restoreButtonInfo
//
//        IAP.store.requestProducts{success, products in
//            if success {
//                self.products = products!
//            }
//        }
//
//        NotificationCenter.default.addObserver(self, selector: #selector(handlePurchaseNotification(_:)),
//                                               name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification),
//                                               object: nil)
//
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        animateColorChange()
//        setTextColor()
//
//        setColorLabel.text = appData.appColorName
//        setResetTimeLabel.text = appData.resetOffset
//
//        if appData.usesCircularProgress {
//            setProgressStyleLabel.text = "Circular"
//        } else {
//            setProgressStyleLabel.text = "Flat"
//        }
//
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        self.navigationItem.title = "Settings"
//    }
//
//    //MARK: - Table Functions
//
//    //    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//    //
//    //        let cell = tableView.cellForRow(at: indexPath)
//    //
//    //        if indexPath.section == 3 {
//    //            let cellHeight: CGFloat = (cell?.bounds.height)!
//    //            if indexPath.row == 0 {
//    //                cell?.addSubview(purchaseButton)
//    //                purchaseButton.center = CGPoint(x: view.bounds.width / 2.0, y: cellHeight / 2.0)
//    //            } else {
//    //                cell?.addSubview(restoreButton)
//    //                restoreButton.center = CGPoint(x: view.bounds.width / 2.0, y: cellHeight / 2.0)
//    //            }
//    //            return cell!
//    //        } else {
//    //            return cell!
//    //        }
//    //
//    //    }
//
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//
//        if indexPath.section == 0 {
//            if indexPath.row == 0 {
//                performSegue(withIdentifier: "colorSettingsSegue", sender: self)
//            }
//        } else if indexPath.section == 1 {
//            performSegue(withIdentifier: "progressViewSettingsSegue", sender: self)
//        } else if indexPath.section == 2 {
//            performSegue(withIdentifier: "resetTimeSettingsSegue", sender: self)
//        }
//
//        tableView.deselectRow(at: indexPath, animated: true)
//
//    }
//
//    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//
//        if appData.isNightMode {
//            cell.contentView.backgroundColor = FlatBlack()
//            cell.accessoryView?.backgroundColor = FlatBlack()
//            cell.accessoryView?.tintColor = FlatGray()
//        } else {
//            let darkerThemeColor = appData.appColor.darken(byPercentage: 0.25)
//            cell.backgroundColor = darkerThemeColor
//            //cell.textLabel?.backgroundColor = darkerThemeColor
//            //cell.detailTextLabel?.backgroundColor = darkerThemeColor
//            //cell.accessoryView?.tintColor = UIColor.gray
//
//            if appData.darknessCheck(for: darkerThemeColor) {
//                if indexPath.section == 3 {
//                    //                    if indexPath.row == 0 {
//                    //                        purchaseButton.tintColor = .white
//                    //                    } else {
//                    //                        restoreButton.tintColor = .white
//                    //                    }
//                } else {
//                    cell.textLabel?.textColor = .white
//                    cell.detailTextLabel?.textColor = .white
//                }
//            } else {
//                if indexPath.section == 3 {
//                    //                    purchaseButton.tintColor = .black
//                    //                    restoreButton.tintColor = .black
//                } else {
//                    cell.textLabel?.textColor = .black
//                    cell.detailTextLabel?.textColor = .black
//                }
//            }
//        }
//
//    }
//
//    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let themeView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 40))
//
//        let headerColor = appData.appColor.darken(byPercentage: 0.2)
//        themeView.backgroundColor = headerColor
//
//        let label = UILabel(frame: CGRect(x: 10, y: 5, width: view.frame.size.width, height: 25))
//        label.text = sectionHeaderTitleArray[section]
//        if appData.darknessCheck(for: headerColor) {
//            label.textColor = .white
//        } else {
//            label.textColor = .black
//        }
//        themeView.addSubview(label)
//
//        return themeView
//    }
//
//    @IBAction func nightModeSelected(_ sender: UISwitch) {
//
//        if sender.isOn == true {
//            print("Night mode enabled")
//            appData.isNightMode = true
//
//            setNightMode(to: true)
//
//            save()
//
//        } else {
//            print("Night mode disabled")
//            appData.isNightMode = false
//
//            setNightMode(to: false)
//
//            save()
//
//        }
//
//    }
//
//    //MARK: - Theme/Color Functions
//
//    func setTextColor() {
//
//        let navigationBar = navigationController?.navigationBar
//        let toolbar = navigationController?.toolbar
//
//        let bgColor = navigationBar?.barTintColor
//
//        if appData.darknessCheck(for: bgColor) {
//            navigationBar?.tintColor = .white
//            navigationBar?.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
//            toolbar?.tintColor = .white
//            setStatusBarStyle(.lightContent)
//        } else {
//            navigationBar?.tintColor = .black
//            navigationBar?.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.black]
//            toolbar?.tintColor = .black
//            setStatusBarStyle(.default)
//        }
//
//    }
//    func setNightMode(to nightModeEnabled: Bool) {
//
//        if nightModeEnabled {
//
//            UIView.animate(withDuration: 0.3) {
//
//                self.view.backgroundColor = FlatBlack()
//
//                self.navigationController?.navigationBar.barTintColor = FlatBlackDark()
//                self.navigationController?.toolbar.barTintColor = FlatBlackDark()
//
//                self.navigationController?.navigationBar.layoutIfNeeded()
//
//                self.tableView.backgroundColor = FlatBlack()
//                self.tableView.separatorColor = UIColor.gray
//                //self.tableView.backgroundView?.backgroundColor = FlatBlack()
//                self.tableView.reloadData()
//
//            }
//
//        } else {
//
//            UIView.animate(withDuration: 0.3) {
//
//                self.tableView.reloadData()
//
//                self.setTheme()
//
//            }
//
//        }
//
//    }
//
//    func setLabelColor(for label: UILabel, to color: UIColor) {
//
//        label.backgroundColor = color
//
//    }
//
//    private func animateColorChange() {
//        guard let coordinator = self.transitionCoordinator else {
//            return
//        }
//
//        coordinator.animate(alongsideTransition: {
//            [weak self] context in
//            self?.setTheme()
//            }, completion: nil)
//    }
//
//    private func setTheme() {
//        //setThemeUsingPrimaryColor(self.appData.appColor, withSecondaryColor: UIColor.clear, andContentStyle: .contrast)
//        navigationController?.navigationBar.barTintColor = appData.appColor
//        navigationController?.toolbar.barTintColor = appData.appColor
//
//        let darkerThemeColor = appData.appColor.darken(byPercentage: 0.25)
//        tableView.backgroundColor = darkerThemeColor
//        tableView.separatorColor = appData.appColor.darken(byPercentage: 0.6)
//
//        if appData.darknessCheck(for: darkerThemeColor) {
//            footerText.textColor = .white
//            setStatusBarStyle(.lightContent)
//            purchaseButton.tintColor = .white
//            restoreButton.tintColor = .white
//
//            setColorLabel.textColor = .white
//            setResetTimeLabel.textColor = .white
//            setProgressStyleLabel.textColor = .white
//        } else {
//            footerText.textColor = .black
//            setStatusBarStyle(.default)
//            purchaseButton.tintColor = .black
//            restoreButton.tintColor = .black
//
//            setColorLabel.textColor = .black
//            setResetTimeLabel.textColor = .black
//            setProgressStyleLabel.textColor = .black
//        }
//
//        tableView.reloadData()
//    }
//
//    //MARK: - IAP
//
//    @objc func purchaseAction() {
//        IAP.store.buyProduct(products[0])
//    }
//
//    @objc func restoreAction() {
//        IAP.store.restorePurchases()
//    }
//
//    @objc func handlePurchaseNotification(_ notification: Notification) {
//        guard let productID = notification.object as? String else { return }
//        tableView.reloadSections(IndexSet(4...4), with: .automatic)
//        print("When does this run?")
//        //        for product in products.enumerated() {
//        //            guard product.productIdentifier == productID else { continue }
//        //
//        //            tableView.reloadSections(IndexSet(4...4), with: .automatic)
//        //
//        //        }
//    }
//
//    //MARK: - Navigation
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//        if segue.identifier == "colorSettingsSegue" {
//            let colorSettingsVC = segue.destination as! ColorSettingsViewController
//            colorSettingsVC.appData = appData
//        } else if segue.identifier == "progressViewSettingsSegue" {
//            let progressSettingsVC = segue.destination as! ProgressViewSettingsViewController
//            progressSettingsVC.appData = appData
//        } else if segue.identifier == "resetTimeSettingsSegue" {
//            let resetTimeSettingsVC = segue.destination as! ResetTimeSettingsViewController
//            resetTimeSettingsVC.appData = appData
//        }
//    }
//
//    //MARK: - Data Handling
//
//    func save() {
//
//        appData.saveAppSettingsToDictionary()
//        appData.save()
//
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        appDelegate.appData.saveAppSettingsToDictionary()
//        appDelegate.appData.save()
//
//    }
//
//}
//
