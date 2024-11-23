//
//  ContentView.swift
//  Project
//
//  Created by Asra Papila on 20.11.2024.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var mapView = MKMapView()
    @State private var annotations: [MKPointAnnotation] = []
    @State private var overlays: [MKOverlay] = []

    var body: some View {
        ZStack {
            MapViewRepresentable(mapView: $mapView, annotations: $annotations, overlays: $overlays)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    setupMap()
                    addMockCrowdedness()
                }
            VStack {
                Text("Tap the map to pin location points and calculate a route between them")
                    .font(.headline)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding()
                Spacer()
            }
        }
    }

    // MARK: - Setup Methods
    private func setupMap() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
    }

    private func addMockCrowdedness() {
        let mockData = [
            (coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), level: 1),
            (coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094), level: 2),
            (coordinate: CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.3994), level: 3)
        ]

        for data in mockData {
            let circle = MKCircle(center: data.coordinate, radius: 500)
            circle.title = "\(data.level)"
            overlays.append(circle)
        }
    }
}

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var mapView: MKMapView
    @Binding var annotations: [MKPointAnnotation]
    @Binding var overlays: [MKOverlay]

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotations(annotations)

        uiView.removeOverlays(uiView.overlays)
        uiView.addOverlays(overlays)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(mapView: $mapView, annotations: $annotations, overlays: $overlays)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        @Binding var mapView: MKMapView
        @Binding var annotations: [MKPointAnnotation]
        @Binding var overlays: [MKOverlay]

        init(mapView: Binding<MKMapView>, annotations: Binding<[MKPointAnnotation]>, overlays: Binding<[MKOverlay]>) {
            _mapView = mapView
            _annotations = annotations
            _overlays = overlays
        }

        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)

            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)

            if annotations.count == 2 {
                calculateRoute()
            }
        }

        private func calculateRoute() {
            guard annotations.count >= 2 else { return }

            var previousLocation = annotations.first!.coordinate

            for i in 1..<annotations.count {
                let currentLocation = annotations[i].coordinate
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: previousLocation))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation))
                request.transportType = .walking

                let directions = MKDirections(request: request)
                directions.calculate { [weak self] response, error in
                    guard let self = self, let route = response?.routes.first else { return }

                    // Add the route polyline to the map for each segment
                    self.mapView.addOverlay(route.polyline)

                    // Update the previous location to be the current one for the next segment
                    previousLocation = currentLocation
                }
            }
        }


        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circleOverlay)
                if let level = Int(circleOverlay.title ?? "0") {
                    renderer.fillColor = level == 1 ? UIColor.green.withAlphaComponent(0.4) :
                                      level == 2 ? UIColor.yellow.withAlphaComponent(0.4) :
                                      UIColor.red.withAlphaComponent(0.4)
                }
                renderer.strokeColor = .black
                renderer.lineWidth = 1
                return renderer
            }
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
