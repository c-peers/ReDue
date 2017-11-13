//
//  IAP.swift
//  RepeatingTasks
//
//  Created by Chase Peers on 11/9/17.
//  Copyright © 2017 Chase Peers. All rights reserved.
//


import Foundation

public struct IAP {
  
  public static let UnlockFullVersion = /*"com.cpeers.ReDue.*/"ReDue_RA001"
  
  fileprivate static let productIdentifiers: Set<ProductIdentifier> = [IAP.UnlockFullVersion]

  public static let store = IAPHelper(productIds: IAP.productIdentifiers)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
  return productIdentifier.components(separatedBy: ".").last
}
