//
//  AgoraVideoViewController.swift
//  AgoraDemo
//
//  Created by MonkeyMan on 9/23/19.
//  Copyright © 2019 MonkeyMan. All rights reserved.
//  Agora.io official implimentation - iOS: https://docs.agora.io/en/Voice/start_live_ios
//  Agora.io official implimentation - iOS: https://docs.agora.io/en/Voice/start_live_android
//  Generate agora.io token: https://medium.com/agora-io/2-click-setup-testing-token-server-b1c6fea9e1ad

import UIKit
import AgoraRtcKit

class AgoraVideoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var chanelNameTF: UITextField!
    @IBOutlet weak var idTF: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var hangUpButton: UIButton!
    @IBOutlet weak var remoteVideoView: UIView!
    
    let appID: String = "a49308ba7e0e4edaa09b37183e178769"
    var agoraKit: AgoraRtcEngineKit?

    var channelName = "janina"
    let tempToken: String? = "006a49308ba7e0e4edaa09b37183e178769IACRzX0+\\/w4kSTZXVZaUGQqYiJap\\/nO9jo6P8HXwUI4IvRq0y+H0NTV7IgD9mQAAqoGTYQQAAQA6PpJhAwA6PpJhAgA6PpJhBAA6PpJh"
    var userID: UInt = 2882341274
    
    var userName: String? = nil
    var remoteUserIDs: [UInt] = []
    
    var muted = false {
        didSet {
            if muted {
                muteButton.setTitle("Unmute", for: .normal)
            } else {
                muteButton.setTitle("Mute", for: .normal)
            }
        }
    }
    
    var hanguped = false {
        didSet {
            if hanguped {
                hangUpButton.setTitle("Join", for: .normal)
            }
            else {
                hangUpButton.setTitle("Hang Up", for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("AgoraVideoViewController!!!")
        // Do any additional setup after loading the view.
        setUpVideo()
        joinChannel()
    }
    
    @IBAction func connectToVideoCall(_ sender: UIButton) {
        
    }
    func setUpVideo() {
        getAgoraEngine().enableVideo()
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = userID
        videoCanvas.view = localVideoView
        videoCanvas.renderMode = .fit
        getAgoraEngine().setupLocalVideo(videoCanvas)
    }
    
    func joinChannel() {
        agoraKit?.setDefaultAudioRouteToSpeakerphone(true)
        localVideoView.isHidden = false
        
        if let name = userName {
            print("if let name = userName")
            getAgoraEngine().joinChannel(byUserAccount: name, token: tempToken, channelId: channelName) { [weak self] (sid, uid, elapsed) in
                self?.userID = uid
                print(self?.userID)
                print("#####################")
            }
        } else {
            print("getAgoraEngine()")
            getAgoraEngine().joinChannel(byToken: tempToken, channelId: channelName, info: nil, uid: userID) { [weak self] (sid, uid, elapsed) in
                self?.userID = uid
                print(sid)
                print(uid)
                print(elapsed)
                print("Successfully join to Video call...")
            }
        }
    }
    
    private func getAgoraEngine() -> AgoraRtcEngineKit {
        if agoraKit == nil {
            agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: appID, delegate: self)
        }
        return agoraKit!
    }
    
    @IBAction func didToggleMute(_ sender: Any) {
        if muted {
            getAgoraEngine().muteLocalAudioStream(false)
        } else {
            getAgoraEngine().muteLocalAudioStream(true)
        }
        muted = !muted
    }
    
    @IBAction func didTapHangUp(_ sender: Any) {
        if hanguped {
            joinChannel()
        }
        else {
            leaveChannel()
        }
        hanguped = !hanguped
    }
    
    func leaveChannel() {
        getAgoraEngine().leaveChannel(nil)
        localVideoView.isHidden = true
        remoteUserIDs.removeAll()
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return remoteUserIDs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "videoCell", for: indexPath)
        
        let remoteID = remoteUserIDs[indexPath.row]
        if let videoCell = cell as? VideoCollectionViewCell {
            let videoCanvas = AgoraRtcVideoCanvas()
            videoCanvas.uid = remoteID
            videoCanvas.view = videoCell.videoView
            videoCanvas.view = self.remoteVideoView
            videoCanvas.renderMode = .fit
            getAgoraEngine().setupRemoteVideo(videoCanvas)
            
            
            if let userInfo = getAgoraEngine().getUserInfo(byUid: remoteID, withError: nil),
                let username = userInfo.userAccount {
                videoCell.nameplateView.isHidden = false
                videoCell.usernameLabel.text = username
            } else {
                videoCell.nameplateView.isHidden = true
            }
        }
        
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension AgoraVideoViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("All joined users uid list append from this point.")
        remoteUserIDs.append(uid)
        collectionView.reloadData()
    }
    
    //Sometimes, user info isn't immediately available when a remote user joins - if we get it later, reload their nameplate.
    func rtcEngine(_ engine: AgoraRtcEngineKit, didUpdatedUserInfo userInfo: AgoraUserInfo, withUid uid: UInt) {
        print("Sometimes, user info isn't immediately available when a remote user joins - if we get it later, reload their nameplate.")
        if let index = remoteUserIDs.first(where: { $0 == uid }) {
            collectionView.reloadItems(at: [IndexPath(item: Int(index), section: 0)])
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("If a uusers offlined then remove their uid from this point.")
        if let index = remoteUserIDs.firstIndex(where: { $0 == uid }) {
            remoteUserIDs.remove(at: index)
            collectionView.reloadData()
        }
    }
}

extension AgoraVideoViewController {
    private func setJwtKey(issuer : String?, subject : String?) {
        let addminutes : Date = NineSeven00().currentTimePlusThreeSec()
        
        let alg = JWTAlgorithm.hs256(NineSeven00().getJWTKey())
        var payload = JWTPayload()
        payload.subject = subject
        payload.issuer = issuer
        payload.issueAt = Int(NineSeven00().getCurrentTime())
        payload.expiration = Int(addminutes.timeIntervalSince1970)
        if NineSeven00().ctpts(divToken: UserDefaults.standard.string(forKey: "dttval")!) {
            let jwtWithKeyId = try? JWT.init(payload: payload, algorithm: alg, header: nil)
            NineSeven00().setJWTKeyID(jwtKeyID: jwtWithKeyId?.rawString)
        }
    }
}

extension AgoraVideoViewController {
    private func generateAgoraioRTCToken(channel: String, isPublisher: Bool) {
        let urlTo = URL(string: "http://localhost:3000/rtctoken")!
        print("ppppooooooooooo = \(urlTo)")
        let parameters: [String: Any] = [
            "channel":channel,
            "isPublisher":isPublisher
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type":"application/json",
            "Accept": "application/json"
        ]
       
        DispatchQueue.main.async {
            AF.request(
                urlTo,
                method: .post,
                parameters: parameters,
                encoding: JSONEncoding.default,
                headers: headers
                ).responseJSON {
                (response) in
                switch response.result {
                    
                    case .success(let json):
                        let jsonData = JSON(json as Any)
                        guard let statusCode = response.response?.statusCode else { return }
                        if(statusCode == 200) {
                            print(parameters)
                            print(jsonData)
                        }

                    case .failure(let error):
                        print("Usrs list request error: \(error)")

                }
            }
        }
    }
}
