//
//  testicle.swift
//  Hive
//
//  Created by Carter Randall on 2019-04-20.
//  Copyright © 2019 CARTER RANDALL. All rights reserved.
//

import UIKit

class Stupid: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.stupidFunction()
        
    }
    
    func stupidFunction() {
        if 1 == 1 {
            print("we are going to billionize")
        } else {
            fatalError("hey bby")
        }
    }
}
