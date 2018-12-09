//
//  Message.swift
//  PyTextATIS
//
//  Created by Mrinal Mohit on 12/8/18.
//  Copyright © 2018 PyText. All rights reserved.
//

import CoreLocation
import Foundation
import UIKit
import MessageKit

struct Message {
  let senderName: String
  let text: NSAttributedString
  let messageId: String
}

extension Message: MessageType {
  var sender: Sender {
    return Sender(id: senderName, displayName: senderName)
  }

  var sentDate: Date {
    return Date()
  }

  var kind: MessageKind {
    return .attributedText(text)
  }
}

struct Location {
  let locationValue: CLLocation
}

extension Location: LocationItem {
  var location: CLLocation {
    return locationValue
  }
  var size: CGSize {
    return CGSize(width: 200, height: 200)
  }
}

struct LocationMessage {
  let senderName: String
  let location: LocationItem
  let messageId: String
}

extension LocationMessage: MessageType {
  var sender: Sender {
    return Sender(id: senderName, displayName: senderName)
  }

  var sentDate: Date {
    return Date()
  }

  var kind: MessageKind {
    return .location(location)
  }
}
