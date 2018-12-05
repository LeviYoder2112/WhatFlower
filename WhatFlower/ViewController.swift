//
//  ViewController.swift
//  WhatFlower
//
//  Created by Levi Yoder on 5/1/18.
//  Copyright © 2018 Levi Yoder. All rights reserved.
//

import UIKit
import CoreML
import Vision
import SwiftyJSON
import Alamofire
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
  
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"


    @IBOutlet weak var info: UITextView!
    @IBOutlet weak var imageView: UIImageView!
   
    let imagePicker = UIImagePickerController()
   
    override func viewDidLoad() {
        super.viewDidLoad()

        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let chosenImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage{
            

            
            guard let ciImage = CIImage(image: chosenImage)
                else {
                    fatalError("Couldn't convert chosen image to CIImage")
        }
            detect(image: ciImage)
        }
imagePicker.dismiss(animated: true, completion: nil)
}

    @IBAction func cameraTapped(_ sender: Any) {
  present(imagePicker, animated: true, completion: nil)    }
    

    func detect(image: CIImage) {
     
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
        fatalError("Can't import model")
        }

        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard  let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("could not classify image")}
            
           self.navigationItem.title = classification.identifier.capitalized
        self.requestInfo(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
        try handler.perform([request])
        }
        catch {
        print(error)
}
}

    func requestInfo(flowerName: String){

        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]

        
 Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
print("Got the wikipedia info")
                print(response)

                let flowerJSON : JSON = JSON(response.result.value!)
        
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue

                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                
                self.info.text = flowerDescription
    }
        }
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
