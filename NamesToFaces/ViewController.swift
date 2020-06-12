//
//  ViewController.swift
//  NamesToFaces
//
//  Created by Dmitry Reshetnik on 13.04.2020.
//  Copyright © 2020 Dmitry Reshetnik. All rights reserved.
//

import UIKit
import LocalAuthentication

class ViewController: UICollectionViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    var people = [Person]()
    var isLocked = true
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let savedPeople = defaults.object(forKey: "people") as? Data {
            let decoder = JSONDecoder()
            
            do {
                people = try decoder.decode([Person].self, from: savedPeople)
            } catch {
                print("Failed to load people.")
            }
        }
        
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "lock"), for: .normal)
        button.addTarget(self, action: #selector(authenticate), for: .touchUpInside)
        
        let barButton = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButton
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewPerson))
        navigationItem.leftBarButtonItem?.isEnabled = !isLocked
        
        KeychainWrapper.standard.set("p@$$w0Rd", forKey: "Password")
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isLocked {
            return 0
        } else {
            return people.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Person", for: indexPath) as? PersonCell else {
            // we failed to get a PersonCell - bail out!
            fatalError("Unable to dequeue PersonCell.")
        }
        
        let person = people[indexPath.item]
        cell.name.text = person.name
        
        let path = getDocumentsDirectory().appendingPathComponent(person.image)
        cell.imageView.image = UIImage(contentsOfFile: path.path)
        
        cell.imageView.layer.borderColor = UIColor(white: 0, alpha: 0.3).cgColor
        cell.imageView.layer.borderWidth = 2
        cell.imageView.layer.cornerRadius = 3
        cell.layer.cornerRadius = 7
        
        // if we're still here it means we got a PersonCell, so we can return it
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let person = people[indexPath.item]
        
        let alertController = UIAlertController(title: "Select an action", message: "Do you want to rename or to delete the picture?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.people.remove(at: indexPath.item)
            
            self?.collectionView.reloadData()
            self?.save()
        })
        alertController.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            let ac = UIAlertController(title: "Rename person", message: nil, preferredStyle: .alert)
            ac.addTextField()
            ac.addAction(UIAlertAction(title: "Cancle", style: .cancel))
            ac.addAction(UIAlertAction(title: "OK", style: .default) { [weak self, weak ac] _ in
                guard let newName = ac?.textFields?[0].text else { return }
                person.name = newName

                self?.collectionView.reloadData()
                self?.save()
            })
            
            self?.present(ac, animated: true)
        })
        
        present(alertController, animated: true)
    }
    
    @objc func addNewPerson() {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc func authenticate() {
        if isLocked {
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "Use Touch ID to unlock the secret."
                
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] (success, authenticationError) in
                    DispatchQueue.main.async {
                        if success {
                            self?.isLocked = false
                            self?.collectionView.reloadData()
                            let button = UIButton(type: .system)
                            button.setImage(UIImage(systemName: "lock.open"), for: .normal)
                            button.addTarget(self, action: #selector(self?.authenticate), for: .touchUpInside)
                            
                            let barButton = UIBarButtonItem(customView: button)
                            self?.navigationItem.rightBarButtonItem = barButton
                            self?.navigationItem.leftBarButtonItem?.isEnabled = !self!.isLocked
                        } else {
                            let ac = UIAlertController(title: "Enter password", message: nil, preferredStyle: .alert)
                            ac.addTextField()
                            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                                if ac.textFields![0].text == KeychainWrapper.standard.string(forKey: "Password") {
                                    self?.isLocked = false
                                    self?.collectionView.reloadData()
                                    let button = UIButton(type: .system)
                                    button.setImage(UIImage(systemName: "lock.open"), for: .normal)
                                    button.addTarget(self, action: #selector(self?.authenticate), for: .touchUpInside)
                                    
                                    let barButton = UIBarButtonItem(customView: button)
                                    self?.navigationItem.rightBarButtonItem = barButton
                                    self?.navigationItem.leftBarButtonItem?.isEnabled = !self!.isLocked
                                } else {
                                    let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
                                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                                    self?.present(ac, animated: true)
                                }
                            }))
                            self?.present(ac, animated: true)
                        }
                    }
                }
            } else {
                let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
            }
        } else {
            save()
            isLocked = true
            collectionView.reloadData()
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "lock"), for: .normal)
            button.addTarget(self, action: #selector(authenticate), for: .touchUpInside)
            
            let barButton = UIBarButtonItem(customView: button)
            navigationItem.rightBarButtonItem = barButton
            navigationItem.leftBarButtonItem?.isEnabled = !isLocked
        }
    }
    
    func save() {
        let encoder = JSONEncoder()
        if let savedData = try? encoder.encode(people) {
            defaults.set(savedData, forKey: "people")
        } else {
            print("Failed to save people.")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imagePath)
        }
        
        let person = Person(name: "Unknown", image: imageName)
        people.append(person)
        collectionView.reloadData()
        
        dismiss(animated: true)
        save()
    }


}

