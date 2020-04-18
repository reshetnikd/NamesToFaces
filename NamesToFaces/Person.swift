//
//  Person.swift
//  NamesToFaces
//
//  Created by Dmitry Reshetnik on 14.04.2020.
//  Copyright © 2020 Dmitry Reshetnik. All rights reserved.
//

import UIKit

class Person: NSObject, Codable {
    
    var name: String
    var image: String
    
    init(name: String, image: String) {
        self.name = name
        self.image = image
    }
    
}
