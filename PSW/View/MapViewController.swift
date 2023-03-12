//
//  MapViewController.swift
//  PSW
//
//  Created by Alexey Gaidykov on 11.03.2023.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    let mapView: MKMapView = {
        let mapView = MKMapView()
        let moscowCoordinate = CLLocationCoordinate2D(
            latitude: 55.7558,
            longitude: 37.6173
        )
        mapView.setRegion(
            MKCoordinateRegion(
                center: moscowCoordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.05,
                    longitudeDelta: 0.05)
            ),
            animated: true
        )
        mapView.translatesAutoresizingMaskIntoConstraints = false
        return mapView
    }()
    
    let spwImage: UIImageView = {
        let spwImage = UIImageView()
        spwImage.image = UIImage(named: "psw")
        spwImage.contentMode = .scaleAspectFit
        spwImage.translatesAutoresizingMaskIntoConstraints = false
        return spwImage
    }()
    
    let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Пуск", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let buildButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Построить маршрут", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    let searchField1: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.placeholder = "Добавить адресс"
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.cornerRadius = 15
        return field
    }()
    
    let searchField2: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.placeholder = "Добавить адресс"
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.cornerRadius = 15
        return field
    }()
    
    let searchField3: UITextField = {
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.placeholder = "Добавить адресс"
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.cornerRadius = 15
        return field
    }()
    
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    var annotationArray = [MKPointAnnotation]()
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        mapView.delegate = self
        setConstrains()
        
        startButton.addTarget(
            self,
            action: #selector(buttonTapped),
            for: .touchUpInside
        )
        
        buildButton.addTarget(
            self,
            action: #selector(buildButtonTapp),
            for: .touchUpInside
        )
    }
    
    //MARK: - objc Method
    @objc func buttonTapped() {
        // Check if text fields are empty
        guard let startAddress = searchField1.text, !startAddress.isEmpty,
              let endAddress = searchField2.text, !endAddress.isEmpty,
              let searchFiled3 = searchField3.text, !searchFiled3.isEmpty else {
            let alert = UIAlertController(
                title: "Пустые поля",
                message: "Пожалуйста добавьте адресс",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        for array in 0...annotationArray.count - 2 {
            createDirectionRequest(startCoordinate: annotationArray[array].coordinate, destinationCoordinate: annotationArray[array + 1].coordinate)
        }
        mapView.showAnnotations(annotationArray, animated: true)
    }
    
    @objc func buildButtonTapp() {
        setupPlacemark(addressPlase: searchField1.text ?? "")
        setupPlacemark(addressPlase: searchField2.text ?? "")
        setupPlacemark(addressPlase: searchField3.text ?? "")
    }
    
    
    //MARK: - Private func
    /// Creating pin
    /// - Parameter adressPlase: Address
    private func setupPlacemark(addressPlase: String) {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(addressPlase) { [self] (plasemark, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let plasemarks = plasemark else { return }
            let placemark = plasemarks.first
            
            let annotation = MKPointAnnotation()
            annotation.title = "\(addressPlase)"
            guard let plasemarkLocation = placemark?.location else { return }
            annotation.coordinate = plasemarkLocation.coordinate
            
            annotationArray.append(annotation)
            
            if annotationArray.count > 2 {
                startButton.isHidden = false
                buildButton.isHidden = false
            }
            
            DispatchQueue.main.async { [self] in
                self.mapView.showAnnotations(annotationArray, animated: true)
            }
        }
    }
    
    /// Constructing a route between two points
    private func createDirectionRequest(
        startCoordinate: CLLocationCoordinate2D,
        destinationCoordinate: CLLocationCoordinate2D
    ) {
        let startLocation = MKPlacemark(coordinate: startCoordinate)
        let destinatioLocation = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startLocation)
        request.destination = MKMapItem(placemark: destinatioLocation)
        request.transportType = .walking
        request.requestsAlternateRoutes = true
        
        let direction = MKDirections(request: request)
        direction.calculate { (response, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let response = response else { return }
            var minRoute = response.routes[0]
            for route in response.routes {
                minRoute = (route.distance < minRoute.distance) ? route : minRoute
            }
            self.mapView.addOverlay(minRoute.polyline)
        }
    }
}

//MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        render.strokeColor = .green
        return render
    }
}
//MARK: - SetConstrains
extension MapViewController {
    func setConstrains() {
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
        ])
        
        mapView.addSubview(spwImage)
        NSLayoutConstraint.activate([
            spwImage.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 20),
            spwImage.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 20),
            spwImage.widthAnchor.constraint(equalToConstant: 40),
            spwImage.heightAnchor.constraint(equalToConstant: 40),
        ])
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 20),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            stackView.widthAnchor.constraint(equalToConstant: 40),
            stackView.heightAnchor.constraint(equalToConstant: 40),
        ])
        stackView.addArrangedSubview(searchField1)
        stackView.addArrangedSubview(searchField2)
        stackView.addArrangedSubview(searchField3)
        stackView.addArrangedSubview(startButton)
        stackView.addArrangedSubview(buildButton)
    }
}

