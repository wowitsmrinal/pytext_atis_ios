//
//  ViewController.swift
//  PyTextATIS
//
//  Created by Mrinal Mohit on 12/8/18.
//  Copyright © 2018 PyText. All rights reserved.
//

import Alamofire
import CoreLocation
import UIKit
import MessageInputBar
import MessageKit
import SwiftyJSON

class ViewController: MessagesViewController {

  // Define constants
  let senderName = "PyTextATIS"
  let mapperName = "mapBot"
  let apiUrl = "http://54.218.83.222"

  var messages: [MessageType] = []

  override func viewDidLoad() {
    super.viewDidLoad()

    // Set delegates
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messageInputBar.delegate = self
    messagesCollectionView.messagesDisplayDelegate = self

    // Customize UI
    messageInputBar.inputTextView.placeholderLabel.text = "A message with city names"
  }

  func insertMessage(as message: MessageType) {
    self.messages.append(message)
    messageInputBar.inputTextView.text = ""
    self.messagesCollectionView.reloadData()
    self.messagesCollectionView.scrollToBottom(animated: true)
  }
}

extension ViewController: MessagesDataSource {
  func numberOfSections(
    in messagesCollectionView: MessagesCollectionView) -> Int {
    return messages.count
  }

  func currentSender() -> Sender {
    return Sender(id: senderName, displayName: senderName)
  }

  func messageForItem(
    at indexPath: IndexPath,
    in messagesCollectionView: MessagesCollectionView) -> MessageType {

    return messages[indexPath.section]
  }

  func messageTopLabelHeight(
    for message: MessageType,
    at indexPath: IndexPath,
    in messagesCollectionView: MessagesCollectionView) -> CGFloat {

    return 12
  }
}

extension ViewController: MessagesLayoutDelegate {
  func heightForLocation(message: MessageType,
                         at indexPath: IndexPath,
                         with maxWidth: CGFloat,
                         in messagesCollectionView: MessagesCollectionView) -> CGFloat {

    return 0
  }
}

extension ViewController: MessagesDisplayDelegate {
  func configureAvatarView(
    _ avatarView: AvatarView,
    for message: MessageType,
    at indexPath: IndexPath,
    in messagesCollectionView: MessagesCollectionView) {

    avatarView.isHidden = true
  }
}

func markup(string text: String, with arr: JSON) -> (NSAttributedString, [String]) {
  let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize*1.1)]

  var attrString = NSMutableAttributedString()
  var entities = [String]()
  var start = String.Index(encodedOffset: 0)
  for boundaryPair in arr {
    let newStart = String.Index(encodedOffset: boundaryPair.1[0].int!)
    let newEnd = String.Index(encodedOffset: boundaryPair.1[1].int!)

    attrString.append(NSAttributedString(string: String(text[start..<newStart])))
    attrString.append(NSAttributedString(string: String(text[newStart..<newEnd]), attributes: attributes))
    entities.append(String(text[newStart..<newEnd]))
    start = newEnd
  }
  attrString.append(NSAttributedString(string: String(text[start..<String.Index(encodedOffset: text.count)])))
  return (attrString, entities)
}

extension ViewController: MessageInputBarDelegate {
  func messageInputBar(
    _ inputBar: MessageInputBar,
    didPressSendButtonWith text: String) {

    Alamofire.request(apiUrl, parameters: ["text": text])
      .validate()
      .response { res in
        if res.data != nil {
          var jsonArray = JSON()
          do {
            jsonArray = try JSON(data: res.data!)
          } catch {}

          // Format string with bold city names
          let (attrString, entities) = markup(string: text, with: jsonArray)

          self.insertMessage(as: Message(
            senderName: self.senderName,
            text: attrString,
            messageId: UUID().uuidString)
          )

          // Generate a map image for every city
          for entity in entities {
            CLGeocoder().geocodeAddressString(entity) { (placemarks, error) in
              guard
                let placemarks = placemarks,
                let location = placemarks.first?.location
                else {
                  return
              }
              self.insertMessage(as: LocationMessage(
                senderName: self.mapperName,
                location: Location(locationValue: location),
                messageId: UUID().uuidString)
              )
            }
          }
        }
    }
  }
}
