//
//  ViewController.swift
//  UploadImageImgurExample
//
//  Created by John Codeos on 2/20/20.
//  Copyright © 2020 John Codeos. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var selectedImageImageView: UIImageView!
    @IBOutlet var selectImageButton: UIButton!
    @IBOutlet var uploadImageButton: UIButton!

    var selectedImage: UIImage!
    var imagePicker = UIImagePickerController()
    var loadingView = LoadingView()
    var imgurUrl: String = ""

    let CLIENT_ID = "MY_CLIENT_ID"

    override func viewDidLoad() {
        super.viewDidLoad()
        loadingView.initilize(viewController: self)
    }

    @IBAction func selectImageButtonAction(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            imagePicker.modalPresentationStyle = .fullScreen
            present(imagePicker, animated: true, completion: nil)
        }
    }

    @IBAction func uploadImageButtonAction(_ sender: UIButton) {
        uploadImageToImgur(image: selectedImage)
    }

    func uploadImageToImgur(image: UIImage) {
        loadingView.start()
        getBase64Image(image: image) { base64Image in
            let boundary = "Boundary-\(UUID().uuidString)"

            var request = URLRequest(url: URL(string: "https://api.imgur.com/3/image")!)
            request.addValue("Client-ID \(self.CLIENT_ID)", forHTTPHeaderField: "Authorization")
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            request.httpMethod = "POST"

            var body = ""
            body += "--\(boundary)\r\n"
            body += "Content-Disposition:form-data; name=\"image\""
            body += "\r\n\r\n\(base64Image ?? "")\r\n"
            body += "--\(boundary)--\r\n"
            let postData = body.data(using: .utf8)

            request.httpBody = postData

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("failed with error: \(error)")
                    return
                }
                guard let response = response as? HTTPURLResponse,
                    (200...299).contains(response.statusCode) else {
                    print("server error")
                    return
                }
                if let mimeType = response.mimeType, mimeType == "application/json", let data = data, let dataString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.loadingView.stop()
                    }

                    print("imgur upload results: \(dataString)")

                    let parsedResult: [String: AnyObject]
                    do {
                        parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
                        if let dataJson = parsedResult["data"] as? [String: Any] {
                            print("Link is : \(dataJson["link"] as? String ?? "Link not found")")
                            self.imgurUrl = dataJson["link"] as? String ?? ""
                            DispatchQueue.main.async {
                                self.performSegue(withIdentifier: "detailsseg", sender: self)
                            }
                        }
                    } catch {
                        // Display an error
                    }
                }
            }.resume()
        }
    }
    

    func getBase64Image(image: UIImage, complete: @escaping (String?) -> ()) {
        DispatchQueue.main.async {
            let imageData = image.pngData()
            let base64Image = imageData?.base64EncodedString(options: .lineLength64Characters)
            complete(base64Image)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailsseg" {
            let destViewController = segue.destination as? DetailsViewController
            destViewController?.imgurUrl = imgurUrl
        }
    }
}

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            selectedImage = pickedImage
            selectedImageImageView.image = selectedImage
        }

        /*

         Swift Dictionary named “info”.
         We have to unpack it from there with a key asking for what media information we want.
         We just want the image, so that is what we ask for.  For reference, the available options are:

         UIImagePickerControllerMediaType
         UIImagePickerControllerOriginalImage
         UIImagePickerControllerEditedImage
         UIImagePickerControllerCropRect
         UIImagePickerControllerMediaURL
         UIImagePickerControllerReferenceURL
         UIImagePickerControllerMediaMetadata

         */
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
