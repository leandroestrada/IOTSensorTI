//
//  UIButtonExtension.swift
//  conectandoDados
//
//  Created by le on 17/08/2018.
//  Copyright © 2018 LeandroEstrada. All rights reserved.
//

import Foundation
import UIKit

extension UIButton{
    func pulsate()
    {
        let pulse = CASpringAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.95
        layer.add(pulse, forKey: nil)
    }
}
