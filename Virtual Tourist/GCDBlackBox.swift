//
//  GCDBlackBox.swift
//  Virtual Tourist
//
//  Created by Franklin Pearsall on 4/13/16.
//  Copyright © 2016 flp. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(updates: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        updates()
    }
}