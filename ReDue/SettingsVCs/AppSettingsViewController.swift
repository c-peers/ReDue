//
//  AppSettingsViewController.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 8/28/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//

import Foundation
import UIKit
import Chameleon
import StoreKit
import SwiftyBeaver

class AppSettingsViewController: UITableViewController {
    
    //MARK: - Outlets
    
    @IBOutlet weak var setColorLabel: UILabel!
    @IBOutlet weak var setProgressStyleLabel: UILabel!
    @IBOutlet weak var setResetTimeLabel: UILabel!
    @IBOutlet var nightModeSwitch: UISwitch!
    @IBOutlet weak var footerText: UILabel!
    @IBOutlet weak var purchaseButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    
    //MARK: - Properties
    
    let log = SwiftyBeaver.self
    
    var appData = AppData()
    let sectionHeaderTitleArray = ["Themes and Color", "Task View", "Task Reset", "Unlock Full Version"]
    
    let removeAdsID = "ReDue_RA001"
    var productID = ""
    var productsRequest = SKProductsRequest()
    var iapProducts = [SKProduct]()

//    var purchaseButtonInfo: UIButton = {
//        let button = UIButton(type: UIButtonType.system)
//        button.frame = CGRect(x: 0, y: 0, width: 150, height: 40)
//        button.setTitle("Unlock Full Version", for: .normal)
//        button.addTarget(self, action: #selector(purchaseAction), for: .touchUpInside)
//        return button
//    }()
//
//    var restoreButtonInfo: UIButton = {
//        let button = UIButton(type: UIButtonType.system)
//        button.frame = CGRect(x: 0, y: 0, width: 150, height: 40)
//        button.setTitle("Restore Purchase", for: .normal)
//        button.addTarget(self, action: #selector(restoreAction), for: .touchUpInside)
//        return button
//    }()

    //MARK: - View and Basic Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setColorLabel.text = appData.appColorName
        print(appData.appColorName)
                
        nightModeSwitch.isOn = false
        nightModeSwitch.isEnabled = false
        
        title = "Application Settings"
        
        if appData.isFullVersion {
            log.info("IAP Purchased")
        } else {
            log.info("IAP not yet purchased")
        }
        
        setIAPButtons()
        
        purchaseButton.setTitle("Unlock Full Version", for: .normal)
        purchaseButton.addTarget(self, action: #selector(purchaseAction), for: .touchUpInside)
        restoreButton.setTitle("Restore Purchase", for: .normal)
        restoreButton.addTarget(self, action: #selector(restoreAction), for: .touchUpInside)

        // Fetch IAP Products available
        fetchAvailableProducts()
        
//        purchaseButton = purchaseButtonInfo
//        restoreButton = restoreButtonInfo
        
//        IAP.store.requestProducts{success, products in
//            if success {
//                self.iapProducts = products!
//            }
//        }

//        NotificationCenter.default.addObserver(self, selector: #selector(handlePurchaseNotification(_:)),
//                                               name: NSNotification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification),
//                                               object: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateColorChange()
        setTextColor()

        setColorLabel.text = appData.appColorName
        setResetTimeLabel.text = appData.resetOffset
        
        if appData.usesCircularProgress {
            setProgressStyleLabel.text = "Circular"
        } else {
            setProgressStyleLabel.text = "Flat"
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationItem.title = "Settings"
    }
    
    //MARK: - Table Functions
    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        let cell = tableView.cellForRow(at: indexPath)
//
//        if indexPath.section == 3 {
//            let cellHeight: CGFloat = (cell?.bounds.height)!
//            if indexPath.row == 0 {
//                cell?.addSubview(purchaseButton)
//                purchaseButton.center = CGPoint(x: view.bounds.width / 2.0, y: cellHeight / 2.0)
//            } else {
//                cell?.addSubview(restoreButton)
//                restoreButton.center = CGPoint(x: view.bounds.width / 2.0, y: cellHeight / 2.0)
//            }
//            return cell!
//        } else {
//            return cell!
//        }
//
//    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
            performSegue(withIdentifier: "colorSettingsSegue", sender: self)
            }
        } else if indexPath.section == 1 {
            performSegue(withIdentifier: "progressViewSettingsSegue", sender: self)
        } else if indexPath.section == 2 {
            performSegue(withIdentifier: "resetTimeSettingsSegue", sender: self)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if appData.isNightMode {
            cell.contentView.backgroundColor = FlatBlack()
            cell.accessoryView?.backgroundColor = FlatBlack()
            cell.accessoryView?.tintColor = FlatGray()
        } else {
            let darkerThemeColor = appData.appColor.darken(byPercentage: 0.25)
            cell.backgroundColor = darkerThemeColor
            //cell.textLabel?.backgroundColor = darkerThemeColor
            //cell.detailTextLabel?.backgroundColor = darkerThemeColor
            //cell.accessoryView?.tintColor = UIColor.gray
            
            if appData.darknessCheck(for: darkerThemeColor) {
                if indexPath.section == 3 {
//                    if indexPath.row == 0 {
//                        purchaseButton.tintColor = .white
//                    } else {
//                        restoreButton.tintColor = .white
//                    }
                } else {
                    cell.textLabel?.textColor = .white
                    cell.detailTextLabel?.textColor = .white
                }
            } else {
                if indexPath.section == 3 {
//                    purchaseButton.tintColor = .black
//                    restoreButton.tintColor = .black
                } else {
                    cell.textLabel?.textColor = .black
                    cell.detailTextLabel?.textColor = .black
                }
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let themeView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 40))
        
        let headerColor = appData.appColor.darken(byPercentage: 0.2)
        themeView.backgroundColor = headerColor
        
        let label = UILabel(frame: CGRect(x: 10, y: 5, width: view.frame.size.width, height: 25))
        label.text = sectionHeaderTitleArray[section]
        if appData.darknessCheck(for: headerColor) {
            label.textColor = .white
        } else {
            label.textColor = .black
        }
        themeView.addSubview(label)
        
        return themeView
    }

    @IBAction func nightModeSelected(_ sender: UISwitch) {
        
        if sender.isOn == true {
            print("Night mode enabled")
            appData.isNightMode = true
            
            setNightMode(to: true)
            
            save()
            
        } else {
            print("Night mode disabled")
            appData.isNightMode = false
            
            setNightMode(to: false)
            
            save()
            
        }
        
    }
    
    //MARK: - Theme/Color Functions

    func setTextColor() {
        
        let navigationBar = navigationController?.navigationBar
        let toolbar = navigationController?.toolbar
        
        let bgColor = navigationBar?.barTintColor
        
        if appData.darknessCheck(for: bgColor) {
            navigationBar?.tintColor = .white
            navigationBar?.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
            toolbar?.tintColor = .white
            setStatusBarStyle(.lightContent)
        } else {
            navigationBar?.tintColor = .black
            navigationBar?.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.black]
            toolbar?.tintColor = .black
            setStatusBarStyle(.default)
        }
        
    }
    func setNightMode(to nightModeEnabled: Bool) {
        
        if nightModeEnabled {
            
            UIView.animate(withDuration: 0.3) {

                self.view.backgroundColor = FlatBlack()
                
                self.navigationController?.navigationBar.barTintColor = FlatBlackDark()
                self.navigationController?.toolbar.barTintColor = FlatBlackDark()

                self.navigationController?.navigationBar.layoutIfNeeded()
                
                self.tableView.backgroundColor = FlatBlack()
                self.tableView.separatorColor = UIColor.gray
                //self.tableView.backgroundView?.backgroundColor = FlatBlack()
                self.tableView.reloadData()
                
            }
            
        } else {
            
            UIView.animate(withDuration: 0.3) {
                
                self.tableView.reloadData()
                
                self.setTheme()
                
            }
            
        }
        
    }
    
    func setLabelColor(for label: UILabel, to color: UIColor) {
        
        label.backgroundColor = color
        
    }
    
    private func animateColorChange() {
        guard let coordinator = self.transitionCoordinator else {
            return
        }
        
        coordinator.animate(alongsideTransition: {
            [weak self] context in
            self?.setTheme()
            }, completion: nil)
    }
    
    private func setTheme() {
        //setThemeUsingPrimaryColor(self.appData.appColor, withSecondaryColor: UIColor.clear, andContentStyle: .contrast)
        navigationController?.navigationBar.barTintColor = appData.appColor
        navigationController?.toolbar.barTintColor = appData.appColor
        
        let darkerThemeColor = appData.appColor.darken(byPercentage: 0.25)
        tableView.backgroundColor = darkerThemeColor
        tableView.separatorColor = appData.appColor.darken(byPercentage: 0.6)
        
        if appData.darknessCheck(for: darkerThemeColor) {
            footerText.textColor = .white
            setStatusBarStyle(.lightContent)
            purchaseButton.tintColor = .white
            restoreButton.tintColor = .white

            setColorLabel.textColor = .white
            setResetTimeLabel.textColor = .white
            setProgressStyleLabel.textColor = .white
        } else {
            footerText.textColor = .black
            setStatusBarStyle(.default)
            purchaseButton.tintColor = .black
            restoreButton.tintColor = .black

            setColorLabel.textColor = .black
            setResetTimeLabel.textColor = .black
            setProgressStyleLabel.textColor = .black
        }

        tableView.reloadData()
    }
    
    //MARK: - IAP
    
    func setIAPButtons() {
        purchaseButton.isEnabled = !appData.isFullVersion
        restoreButton.isEnabled = !appData.isFullVersion
    }
    
    @objc func purchaseAction() {
        //IAP.store.buyProduct(iapProducts[0])
        purchaseIAP(product: iapProducts[0])
        log.debug("Purchase button tapped. Product \(iapProducts[0])")
    }
    
    @objc func restoreAction() {
        //IAP.store.restorePurchases()
        log.debug("Restore button tapped")
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func fetchAvailableProducts()  {
        
        // Put here your IAP Products ID's
        let productIdentifiers = NSSet(objects: removeAdsID)
        
        log.debug("IAP is the following: \(productIdentifiers)")
        log.debug("Fetch available products")
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<String>)
        productsRequest.delegate = self
        productsRequest.start()
    }
    
    @objc func handlePurchaseNotification(_ notification: Notification) {
        //guard let productID = notification.object as? String else { return }
        //tableView.reloadSections(IndexSet(4...4), with: .automatic)
        print("When does this run?")
//        for product in products.enumerated() {
//            guard product.productIdentifier == productID else { continue }
//
//            tableView.reloadSections(IndexSet(4...4), with: .automatic)
//
//        }
    }

    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "colorSettingsSegue" {
            let colorSettingsVC = segue.destination as! ColorSettingsViewController
            colorSettingsVC.appData = appData
        } else if segue.identifier == "progressViewSettingsSegue" {
            let progressSettingsVC = segue.destination as! ProgressViewSettingsViewController
            progressSettingsVC.appData = appData
        } else if segue.identifier == "resetTimeSettingsSegue" {
            let resetTimeSettingsVC = segue.destination as! ResetTimeSettingsViewController
            resetTimeSettingsVC.appData = appData
        }
    }
    
    //MARK: - Alert Function
    
    func popAlert(withTitle title: String, andMessage message: String) {
        
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default){ (action: UIAlertAction) in
            print("Hello")
        }
        
        alertController.addAction(okAction)
        
        present(alertController,animated: true,completion: nil)
        
    }
    
    //MARK: - Data Handling
    
    func save() {
        
        appData.saveAppSettingsToDictionary()
        appData.save()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.appData.saveAppSettingsToDictionary()
        appDelegate.appData.save()
        
    }
    
}

// MARK: - Storekit Functions

extension AppSettingsViewController: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        
        log.debug("Restore completed successfully")
        
        appData.isFullVersion = true
        save()
        
        setIAPButtons()
        
        let title = "Unlocked"
        let message = "Ads have been removed and premium feature are now unlocked."
        popAlert(withTitle: title, andMessage: message)

    }

    // MARK: - REQUEST IAP PRODUCTS
    func productsRequest (_ request:SKProductsRequest, didReceive response:SKProductsResponse) {
        if (response.products.count > 0) {
            iapProducts = response.products
            
            let removedAdsProduct = response.products[0] as SKProduct
            
            log.debug("Product #1 is \(removedAdsProduct.productIdentifier)")
            
            // Get its price from iTunes Connect
//            let numberFormatter = NumberFormatter()
//            numberFormatter.formatterBehavior = .behavior10_4
//            numberFormatter.numberStyle = .currency
//            numberFormatter.locale = removedAdsProduct.priceLocale
//            let price2Str = numberFormatter.string(from: removedAdsProduct.price)
            
            // Show its description
            //label.text = removedAdsProduct.localizedDescription + "\nfor just \(price2Str!)"

        } else {
            log.info("No products")
        }
    }
    
    // MARK: - MAKE PURCHASE OF A PRODUCT
    func canMakePurchases() -> Bool {  return SKPaymentQueue.canMakePayments()  }
    
    func purchaseIAP(product: SKProduct) {
        if self.canMakePurchases() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
            
            print("PRODUCT TO PURCHASE: \(product.productIdentifier)")
            log.info("PRODUCT TO PURCHASE: \(product.productIdentifier)")
            
            productID = product.productIdentifier
            
            // IAP Purchases dsabled on the Device
        } else {
            log.debug("Purchased disabled")
            
            let title = "Error"
            let message = "Purchases are disabled in your device."
            popAlert(withTitle: title, andMessage: message)
        }
    }
    
    // MARK:- IAP PAYMENT QUEUE
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction:AnyObject in transactions {
            if let trans = transaction as? SKPaymentTransaction {
                switch trans.transactionState {
                    
                case .purchased:
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    
                    log.debug("Product purchased")
                    
                    if productID == removeAdsID {
                        
                        // Save your purchase locally (needed only for Non-Consumable IAP)
                        appData.isFullVersion = true
                        save()
                        
                        setIAPButtons()
                        
                        let title = "Unlocked"
                        let message = "Ads have been removed and premium feature are now unlocked."
                        popAlert(withTitle: title, andMessage: message)

                    }
                    
                    break
                    
                case .failed:
                    log.debug("Failed with error \(String(describing: trans.error))")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    break
                case .restored:
                    log.debug("")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    break
                    
                default: break
                }}}
    }
    
}
