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
    @IBOutlet var glassSwitch: UISwitch!
    
    //MARK: - Properties
    
    let log = SwiftyBeaver.self
    
    var appData = AppData()
    let sectionHeaderTitleArray = ["Themes and Color", "Task View", "Task Reset", "Unlock Full Version"]
    
    let removeAdsID = "ReDue_RA001"
    var productID = ""
    var productsRequest = SKProductsRequest()
    var iapProducts = [SKProduct]()

    var colors = Colors(main: HexColor("247BA0")!, bg: FlatWhite(), task1: HexColor("70C1B3")!, task2: HexColor("B2DBBF")!, progress: HexColor("FF1654")!)
    
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
        
        if appData.isGlass {
            glassSwitch.isOn = true
        } else {
            glassSwitch.isOn = false
        }
        
        title = "Application Settings"
        
        if appData.isFullVersion {
            log.info("IAP Purchased")
            purchaseButton.setTitle("Full Version Unlocked", for: .normal)
            footerText.isHidden = true
        } else {
            log.info("IAP not yet purchased")
            purchaseButton.setTitle("Unlock Full Version", for: .normal)
            footerText.isHidden = false
        }
        
        setIAPButtons()
        
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
        save()

        let vc = self.navigationController!.viewControllers.first as? TaskViewController
        vc?.taskList.reloadData()
        vc?.taskList.collectionViewLayout.invalidateLayout()

    }
    
    //MARK: - Table Functions
    
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
            let darkerThemeColor = colors.bg //appData.appColor.darken(byPercentage: 0.25)
            cell.backgroundColor = darkerThemeColor
            //cell.textLabel?.backgroundColor = darkerThemeColor
            //cell.detailTextLabel?.backgroundColor = darkerThemeColor
            //cell.accessoryView?.tintColor = UIColor.gray
            
            if appData.darknessCheck(for: darkerThemeColor) {
                cell.textLabel?.textColor = .white
                cell.detailTextLabel?.textColor = .white
            } else {
                cell.textLabel?.textColor = .black
                cell.detailTextLabel?.textColor = .black
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let themeView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 40))
        
        let headerColor = colors.bg.darken(byPercentage: 0.3) //appData.appColor.darken(byPercentage: 0.2)
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

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let hideIndex = IndexPath(row: 1, section: 3)
        if appData.isFullVersion && (indexPath == hideIndex) {
            return 0
        }

        return 44
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
    
    @IBAction func setGlass(_ sender: UISwitch) {
        appData.isGlass = sender.isOn ? true : false
        print("isGlass set to \(sender.isOn)")
        save()
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
        
        colors = Colors.init(main: appData.mainColor!, bg: appData.bgColor!, task1: appData.taskColor1!, task2: appData.taskColor2!, progress: appData.progressColor!)
        
        navigationController?.navigationBar.barTintColor = colors.main //appData.appColor
        navigationController?.toolbar.barTintColor = colors.main //appData.appColor
        
        let darkerThemeColor = colors.bg //appData.appColor.darken(byPercentage: 0.25)
        tableView.backgroundColor = colors.bg //darkerThemeColor
        tableView.separatorColor =  colors.bg.darken(byPercentage: 0.5) //appData.appColor.darken(byPercentage: 0.6)
        
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
    
    func unlockedAlert() {
        
        // Popup when IAP purchased restored
        let modalView = ModalInfoView()
        modalView.set(title: "Premium Version Unlocked")
        modalView.set(image: #imageLiteral(resourceName: "Check"))
        modalView.set(length: 2.5)
        modalView.set(animationDuration: 0.4)
        view.addSubview(modalView)
        modalView.center = view.center

    }
    
    //MARK: - Data Handling
    
    func save() {
        
        let data = DataHandler()
        data.saveAppSettings(appData)
        //appData.saveAppSettingsToDictionary()
        //appData.save()
        
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //appDelegate.appData.saveAppSettingsToDictionary()
        //appDelegate.appData.save()
        
    }
    
}

// MARK: - Storekit Functions

extension AppSettingsViewController: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        
        log.debug("Restore completed successfully")
        
        appData.isFullVersion = true
        save()
        
        setIAPButtons()
        unlockedAlert()
        
        //let title = "Unlocked"
        //let message = "Ads have been removed and premium feature are now unlocked."
        //popAlert(withTitle: title, andMessage: message)

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
                        unlockedAlert()
                        
                        //let title = "Unlocked"
                        //let message = "Ads have been removed and premium feature are now unlocked."
                        //popAlert(withTitle: title, andMessage: message)

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
