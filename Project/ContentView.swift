//
//  ContentView.swift
//  Project
//
//  Created by Asra Papila on 20.11.2024.
//

import SwiftUI
import MapKit
import CoreLocation

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct InitialView: View {
    @State private var preferences: [String: Bool] = [
        "Atatürk": false, "Train": false, "Plane": false, "Car": false, "Toys": false,
        "Period": false, "Science": false, "Ship": false, "Comms": false, "Motor": false,
        "Ferry": false
           ]

    var body: some View {
        VStack {
            Text("Koç Museum")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.purple)
                .padding(.bottom, 70)

            Text("Choose an Option")
                .font(.headline)
                .padding(.top, 20)

            NavigationLink(destination: ContentView()) {
                Text("Go to Map View")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            NavigationLink(destination: PreferencesView(preferences: $preferences)) {
                Text("Set Preferences")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            NavigationLink(destination: ContentPage()) {
                Text("Go to Content Page")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

struct InitialView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InitialView()
        }
    }
}


struct MapView: UIViewRepresentable {
    let annotations: [MuseumSectionAnnotation]
    @Binding var zoomLevel: MKCoordinateSpan

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        let coordinator = context.coordinator
        coordinator.mapView = mapView // Pass mapView reference to Coordinator
        mapView.delegate = coordinator

        // Center the map on Rahmi Koç Museum
        let museumCenter = CLLocationCoordinate2D(latitude: 41.04241, longitude: 28.94881)
        let region = MKCoordinateRegion(center: museumCenter, span: zoomLevel)
        mapView.setRegion(region, animated: false)

        // Add annotations
        mapView.addAnnotations(annotations)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotations(annotations)

        let museumCenter = CLLocationCoordinate2D(latitude: 41.0421, longitude: 28.9497)
        let updatedRegion = MKCoordinateRegion(center: museumCenter, span: zoomLevel)
        uiView.setRegion(updatedRegion, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var selectedAnnotations = [MuseumSectionAnnotation]()
        var mapView: MKMapView?

        // Compute distances between two coordinates
        private func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
            let loc1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
            let loc2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
            return loc1.distance(from: loc2)
        }

        // Find the shortest path using a greedy algorithm
        private func shortestPath() -> [CLLocationCoordinate2D] {
            guard selectedAnnotations.count > 1 else { return selectedAnnotations.map { $0.coordinate } }

            var unvisited = selectedAnnotations.map { $0.coordinate }
            var path: [CLLocationCoordinate2D] = []
            var current = unvisited.removeFirst() // Start at the first pin
            path.append(current)

            while !unvisited.isEmpty {
                // Find the nearest unvisited pin
                if let nearest = unvisited.min(by: { distance(from: current, to: $0) < distance(from: current, to: $1) }) {
                    path.append(nearest)
                    current = nearest
                    unvisited.removeAll { $0 == nearest }
                }
            }

            return path
        }

        // Update route with shortest path
        func updateRoute() {
            guard let mapView = mapView else { return }

            // Remove existing overlays
            mapView.removeOverlays(mapView.overlays)

            // Get the shortest path and create a polyline
            let path = shortestPath()
            guard path.count > 1 else { return } // Need at least two points for a route
            let polyline = MKPolyline(coordinates: path, count: path.count)
            mapView.addOverlay(polyline)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let museumAnnotation = annotation as? MuseumSectionAnnotation else { return nil }

            let identifier = "MuseumPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            // Customize appearance based on crowdedness
            switch museumAnnotation.crowdednessLevel {
            case "High":
                annotationView?.markerTintColor = .red
            case "Medium":
                annotationView?.markerTintColor = .orange
            default:
                annotationView?.markerTintColor = .green
            }

            // Highlight selected annotations
            if museumAnnotation.isSelected {
                annotationView?.markerTintColor = .blue
                annotationView?.glyphText = "★"
            } else {
                annotationView?.glyphText = nil
            }

            return annotationView
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? MuseumSectionAnnotation else { return }

            if annotation.crowdednessLevel == "High" {
                // Show warning alert
                showCrowdednessWarning(for: annotation, mapView: mapView)
            } else {
                toggleSelection(for: annotation, in: mapView)
            }
        }

        private func showCrowdednessWarning(for annotation: MuseumSectionAnnotation, mapView: MKMapView) {
            let alert = UIAlertController(
                title: "Warning",
                message: "\(annotation.title ?? "This location") is crowded now. Do you still want to proceed?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
                self.toggleSelection(for: annotation, in: mapView)
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel))
            
            // Present the alert
            if let viewController = mapView.window?.rootViewController {
                viewController.present(alert, animated: true)
            }
        }

        private func toggleSelection(for annotation: MuseumSectionAnnotation, in mapView: MKMapView) {
            annotation.isSelected.toggle()

            if annotation.isSelected {
                selectedAnnotations.append(annotation)
            } else {
                selectedAnnotations.removeAll { $0 === annotation }
            }

            updateRoute()

            // Refresh annotation appearance
            mapView.removeAnnotation(annotation)
            mapView.addAnnotation(annotation)
        }

    }
}

class MuseumSectionAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    var isSelected: Bool = false
    var crowdednessLevel: String

    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.crowdednessLevel = ["Low", "Medium", "High"].randomElement()! // Assign random level
    }
}




struct ContentView: View {
    @State private var zoomLevel = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
    @State private var currentFloor: Floor = .groundLevel
    @State private var showLegend = false // State to toggle the legend view

    enum Floor {
        case groundLevel, firstFloor, basementLevel
    }

    // Annotations for different levels
    let groundLevelAnnotations = [
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04189, longitude: 28.94845), title: "DC-3 Yolcu Uçağı", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04193, longitude: 28.94849), title: "Müze Mağaza", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04204, longitude: 28.94814), title: "Berlin 65 Vagonu", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04241, longitude: 28.94882), title: "Turgut Alp Vinci", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04230, longitude: 28.94863), title: "Buhar Makinası", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04224, longitude: 28.94855), title: "Elmalı Barajı Pompası", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04250, longitude: 28.94832), title: "Açık Teşhir Alanı", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04267, longitude: 28.94847), title: "B-24 Liberator", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04251, longitude: 28.94804), title: "Seka Vinci", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04238, longitude: 28.94925), title: "F-104 Savaş Uçağı", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04127, longitude: 28.94840), title: "Halat Restaurant", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04132, longitude: 28.94820), title: "Fenerbahçe Vapuru", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04195, longitude: 28.94906), title: "Aydın Çubukçu Galerisi", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04196, longitude: 28.94939), title: "Amral Teknesi", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04192, longitude: 28.94932), title: "Sayanora Filikası", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04221, longitude: 28.94951), title: "T02", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04208, longitude: 28.94973), title: "T03", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04198, longitude: 28.94960), title: "T06", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04148, longitude: 28.94958), title: "T11", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04136, longitude: 28.94943), title: "T12", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04128, longitude: 28.94931), title: "T13", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04119, longitude: 28.94921), title: "T14", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04124, longitude: 28.94899), title: "T15", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04180, longitude: 28.94950), title: "T17", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04164, longitude: 28.94920), title: "T17a", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04167, longitude: 28.94924), title: "T17b", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04170, longitude: 28.94928), title: "T17c", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04173, longitude: 28.94932), title: "T17d", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04176, longitude: 28.94936), title: "T17e", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04179, longitude: 28.94940), title: "T17f", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04182, longitude: 28.94944), title: "T17g", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04186, longitude: 28.94950), title: "T18", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04162, longitude: 28.94875), title: "T19a", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04167, longitude: 28.94880), title: "T19b", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04172, longitude: 28.94885), title: "T19c", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04177, longitude: 28.94890), title: "T19d", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04214, longitude: 28.94899), title: "T20", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04250, longitude: 28.94972), title: "Keşif Küresi", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04282, longitude: 28.94924), title: "Suzy’s Cade Du Levant", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04299, longitude: 28.94911), title: "Sergi Salonu", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04268, longitude: 28.94949), title: "L01", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04273, longitude: 28.94954), title: "L02", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04278, longitude: 28.94959), title: "L03", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04259, longitude: 28.94962), title: "L04", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04264, longitude: 28.94967), title: "L05", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04269, longitude: 28.94972), title: "L06", subtitle: nil),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04268, longitude: 28.94961), title: "L07", subtitle: nil),
    ]

    let firstFloorAnnotations = [
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04213, longitude: 28.94934), title: "T01", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04207, longitude: 28.94971), title: "T04", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04221, longitude: 28.94966), title: "T05", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04177, longitude: 28.94995), title: "T07", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04170, longitude: 28.94986), title: "T08", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04148, longitude: 28.94958), title: "T10", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04119, longitude: 28.94921), title: "T14", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04199, longitude: 28.94918), title: "T19e", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04176, longitude: 28.94892), title: "T19e", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04269, longitude: 28.94972), title: "L08", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04264, longitude: 28.94967), title: "L09", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04259, longitude: 28.94962), title: "L10", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04263, longitude: 28.94956), title: "L11", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04268, longitude: 28.94949), title: "L12", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04273, longitude: 28.94954), title: "L13", subtitle: "Upstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04278, longitude: 28.94959), title: "L14", subtitle: "Upstairs"),
    ]

    let basementLevelAnnotations = [
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04297, longitude: 28.94908), title: "T15", subtitle: "Downstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04292, longitude: 28.94914), title: "T16", subtitle: "Downstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04300, longitude: 28.94915), title: "T17", subtitle: "Downstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04291, longitude: 28.94929), title: "T18", subtitle: "Downstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04284, longitude: 28.94941), title: "T19", subtitle: "Downstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04281, longitude: 28.94927), title: "T19", subtitle: "Downstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04272, longitude: 28.94949), title: "T20", subtitle: "Downstairs"),
        MuseumSectionAnnotation(coordinate: CLLocationCoordinate2D(latitude: 41.04264, longitude: 28.94964), title: "T21", subtitle: "Downstairs"),
    ]

    var currentAnnotations: [MuseumSectionAnnotation] {
        switch currentFloor {
        case .groundLevel:
            return groundLevelAnnotations
        case .firstFloor:
            return firstFloorAnnotations
        case .basementLevel:
            return basementLevelAnnotations
        }
    }
    
    struct LegendView: View {
        @Environment(\.dismiss) var dismiss // Access the dismiss environment action
        
        var body: some View {
            NavigationView {
                List {
                    NavigationLink("MUSTAFA V. KOÇ BİNASI", destination: MustafaKocView())
                    NavigationLink("TERSHANE", destination: TershaneView())
                }
                .navigationTitle("Legend")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            dismiss() // Dismiss the sheet
                        }
                    }
                }
            }
        }
    }

    struct MustafaKocView: View {
        var body: some View {
            NavigationView {
                List {
                    NavigationLink("ALT KAT", destination: MustafaKocAlt())
                    NavigationLink("GİRİŞ KATI", destination: MustafaKocGiris())
                    NavigationLink("ÜST KAT", destination: MustafaKocUst())
                }
                .navigationTitle("MUSTAFA V. K0Ç")
            }
        }
    }

    struct TershaneView: View {
        var body: some View {
            NavigationView {
                List {
                    NavigationLink("GİRİŞ KATI", destination: TershaneGiris())
                    NavigationLink("ÜST KAT", destination: TershaneUst())
                    NavigationLink("AÇIK TEŞHİR ALANI", destination: TershaneAcik())
                }
                .navigationTitle("TERSHANE")
            }
        }
    }
    
    struct MustafaKocAlt: View {
        var body: some View {
            List {
                Text("L15 : Havacılık")
                Text("L16 : Restorasyon Atölyesi")
                Text("L17 : Lokomotif ve Otomobil Modelleri")
                Text("L18 : Oyuncaklar")
                Text("L19 : Denizcilik Modelleri")
                Text("L20 : Sinema Bölümü")
                Text("L21 : Matbaa Makineleri")
            }
            .navigationTitle("ALT KAT")
        }
    }
    
    struct MustafaKocGiris: View {
        var body: some View {
            List {
                Text("L01 : Buharlı Makine Modelleri")
                Text("L02 : Buharlı Gemi Makine Modelleri")
                Text("L03 : Sıcak Hava ve İçten Yanmalı Motor Modelleri")
                Text("L04 : Buharlı Makine Modelleri")
                Text("L05 : Buharlı Silindirler ve Çekici Makine Modelleri")
                Text("L06 : Buharlı Makine Modelleri")
                Text("L07 : Lokomotif Modelleri ve Kalender Vapuru Makinesi")
            }
            .navigationTitle("GİRİŞ KATI")
        }
    }
    
    struct MustafaKocUst: View {
        var body: some View {
            List {
                Text("L08 - L11 : Bilimsel Aletler")
                Text("L12 - L14 : İletişim Aletleri")
            }
            .navigationTitle("ÜST KAT")
        }
    }
    
    struct TershaneGiris: View {
        var body: some View {
            List {
                Text("T02 : Sualtı Bölümü")
                Text("T03 : Astronomi / Enerji / Fen Atölyeleri")
                Text("T06 : Erdoğan Gönül Galerisi | Otomobiller")
                Text("T11 : Dr. Bülent Bulgurlu Galerisi | Otomobiller")
                Text("T12 : Buhar Makineleri | Dizel Motorları")
                Text("T13 : Araser Zeytinyağı Fabrikası")
                Text("T14 : Marangozhane")
                Text("T15 : Gemi Makineleri")
                Text("T16 : Tarihi Kızak")
                Text("T17 : Nostaljik Dükkanlar")
                Text("T17a : Haliç Oyuncakçısı")
                Text("T17b : Gemi Donatımı")
                Text("T17c : Dakik Saat")
                Text("T17d : Dövme Demir")
                Text("T17e : Ismarlama Kundura")
                Text("T17f : Fecri Aletler")
                Text("T17g : Şifa Eczanesi")
                Text("T18 : Gemi Buhar Makinesi")
                Text("T19 : Denizcilik")
                Text("T19a : Balıkçı Barınağı")
                Text("T19b : Tekneler")
                Text("T19c : Kosta Usta Motor Tamir Atölyesi")
                Text("T19d : Ayvansaray Sandal Yapım Atölyesi")
                Text("T20 : Aydın Çubukçu Galerisi - Raylı Ulașım")
            }
            .navigationTitle("GİRİŞ KATI")
        }
    }
    
    struct TershaneUst: View {
        var body: some View {
            List {
                Text("T01 : Rahmi M. Koç Galerisi Atatürk Koleksiyonu")
                Text("T04 : Renkli Matematik Dünyası")
                Text("T05 : Anasıfı Eğitim Atölyesi")
                Text("T07 : Motosikletler")
                Text("T08 : Bebek Arabaları")
                Text("T09 : Bisikletler")
                Text("T10 : Kağnılar | At Arabaları | Kızaklar")
                Text("T14 : Torna Tezgahları")
                Text("T19e : Kayıklar | Dıştan Takma Motorlar")
            }
            .navigationTitle("ÜST KAT")
        }
    }
    
    struct TershaneAcik: View {
        var body: some View {
            List {
                Text("Anadol Otomobiller")
                Text("Yarış Otomobilleri")
                Text("İtfaiye Arabaları")
                Text("Traktörler")
                Text("Sovyet Otomobilleri")
                Text("Dört Çekerli Araçlar")
                Text("Uçaklar")
                Text("B-24 Harley's Harem")
                Text("Jet Provost")
                Text("Hamsa Jet")
                Text("Eğitim Uçağı")
                Text("Tarım Uçağı")
                Text("Atlıkarınca")
                Text("Hasköy Sütlüce Demiryolu İstasyonu")
                Text("Seka Vinci")
            }
            .navigationTitle("AÇIK TEŞHİR ALANI")
        }
    }

    var body: some View {
        ZStack {
            MapView(annotations: currentAnnotations, zoomLevel: $zoomLevel)
                .edgesIgnoringSafeArea(.all)

            VStack {
                // Floor Switcher Buttons
                HStack {
                    Button(action: { currentFloor = .basementLevel }) {
                        Text("Downstairs")
                            .padding()
                            .background(currentFloor == .basementLevel ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }

                    Button(action: { currentFloor = .groundLevel }) {
                        Text("Ground Level")
                            .padding()
                            .background(currentFloor == .groundLevel ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }

                    Button(action: { currentFloor = .firstFloor }) {
                        Text("Upstairs")
                            .padding()
                            .background(currentFloor == .firstFloor ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())

                Spacer()

                // Zoom Buttons
                HStack {
                    Button(action: {
                        zoomLevel = MKCoordinateSpan(
                            latitudeDelta: max(zoomLevel.latitudeDelta / 2, 0.0005),
                            longitudeDelta: max(zoomLevel.longitudeDelta / 2, 0.0005)
                        )
                    }) {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }

                    Button(action: {
                        zoomLevel = MKCoordinateSpan(
                            latitudeDelta: zoomLevel.latitudeDelta * 2,
                            longitudeDelta: zoomLevel.longitudeDelta * 2
                        )
                    }) {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding()
            }
            // Legend Button
                       VStack {
                           Spacer()
                           HStack {
                               Spacer()
                               Button(action: {
                                   showLegend = true
                               }) {
                                   Text("Legend")
                                       .padding()
                                       .background(Color.black.opacity(0.7))
                                       .foregroundColor(.white)
                                       .clipShape(Capsule())
                               }
                               .padding()
                           }
                       }
                   }
                   .sheet(isPresented: $showLegend) {
                       LegendView()
        }
    }
}

// SwiftUI Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ContentPage: View {
    let exhibits: [Exhibit] = [
        Exhibit(
            name: "Atatürk Bölümü",
            description: "Bu bölümde sergilenen objeler, Türkiye Cumhuriyeti’nin kurucusu ve ilk Cumhurbaşkanı Mustafa Kemal Atatürk’e (1881-1938) aittir. Koleksiyon, daha çok Kurtuluş Savaşı’nda önemli rol oynayan ve daha sonra Atatürk’ün yakınları ve çalışma arkadaşları arasına katılan Albay Halil Nuri Yurdakul tarafından bir araya getirilmiştir. Oğlu Prof. Dr. Yurdakul Yurdakul ve gelini Sayın Ayşe Acatay Yurdakul tarafından bağışlanmıştır.",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        ),
        Exhibit(
            name: "Demir Yolu Ulaşımı",
            description: "Müzenin raylı ulaşım kısmı iki bölümden oluşmaktadır. Aralarında Sultan Abdülaziz’in Saltanat Vagonu ve Kadıköy-Moda Tramvayı’nın da yer aldığı demir yolu araçları, ince işçilikli lokomotif ve tramvay modellerinin yanı sıra, demir yolları ile ilgili çeşitli fotoğraflar ve efemeralar sergilenmektedir.",
            coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        ),
        Exhibit(
            name: "Havacılık",
            description: "Wright Kardeşlerin planör modelinden, tüm zamanların en önemli uçaklarından olan Douglas DC-3 ve F 104S Starfighter avcı uçağına kadar havacılık tarihinin önemli örneklerinin yer aldığı koleksiyon Mustafa V. Koç Binası ve Açık Alan’da görülebilir.",
            coordinate: CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.3994)
        ),
        Exhibit(
            name: "Kara Yolu Ulaşımı",
            description: "Bu bölümde, kara yolu ulaşımının 1800’lerden günümüze kadar olan gelişimine yön veren; at arabaları, faytonlar, çocuk arabaları, bisikletler, motosikletler, tarım objeleri, klasik otomobiller, otomobil modelleri, itfaiye araçları ve buharlı kara yolu araçlarının nadir bulunan örnekleri yer almaktadır.",
            coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294)
        ),
        Exhibit(
            name: "Modeller ve Oyuncaklar",
            description: "1700’lerden günümüze kadar olan tarih aralığına ait, ince işçilikle yapılmış, çoğu türünün nadir örneklerinden olan ölçekli modeller, müze koleksiyonu içinde çok önemli bir yer tutmaktadır. Buharlı Makineler, Raylı Ulaşım, Denizcilik, Havacılık ve Karayolu Ulaşımı Bölümleri içinde, bu bölümlere ait önde gelen yapımcılara ait seçkin model koleksiyonları görülebilir. Müze koleksiyonunda yer alan minyatür objeler, çeşitli ülke ve dönemlere ait oyuncaklar da Modeller başlığı altında verilmiştir. Oyuncaklar ağırlıklı olarak Mustafa V. Koç Binası’nda sergilenmektedir. Ziyaretçilere büyülü bir dünyanın kapısını aralayan envai çeşit minyatür obje ve bebek evleri Tersane - Ana Giriş’te görülebilir.",
            coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294)
        ),Exhibit(
            name: "Yaşayan Geçmiş",
            description: "19. yüzyıla ait dükkân ve atölyelerin gerçeğe uygun olarak yeniden canlandırıldığı bölümlerde aynı zamanda koleksiyonun ilgi çekici pek çok parçası da sergilenmektedir. Tornahane, Zeytinyağı Fabrikası, Film Seti, Kaptan Köşkü, Balıkçı Barınağı, Kosta Usta Motor Tamir Atölyesi, Sandal Yapım Atölyesi, Fenni Aletler Dükkanı, Eczane, Kunduracı, Demirci, Saat Yapımcısı, Gemi Donatım ve Oyuncakçı, Mustafa V. Koç, Tersane Binası ve Açık Alan içinde bölüm koleksiyonlarını destekleyecek şekilde konumlandırılmıştır.",
            coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294)
        ),Exhibit(
            name: "Bilimsel Aletler",
            description: "14. yüzyıla ait gök küresi ile 19. yüzyıla ait transit teleskobun da bulunduğu, önemli gözlem ve ölçüm aletlerini kapsayan koleksiyon, bilim tarihine ışık tutmaktadır. Koleksiyonun tamamı, Mustafa V. Koç Binası’nda görülebilir.",
            coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294)
        ),Exhibit(
            name: "Denizcilik",
            description: "Rahmi M. Koç Müzesi, denizcilik objeleri ve modellerinden oluşan geniş bir koleksiyona sahiptir. Tersane’deki bu bölümde bir grup model, birçok gerçek boyutta tekne ve yat, kıçtan takma motorlardan oluşan değerli bir koleksiyon ve nadir rastlanan bir “Amphicar” yer almaktadır. Müze koleksiyonunun en beğenilen öğelerinden biri olan etkileyici Boğaziçi Gezinti Kayığı’na ek olarak küçük kayıklar, kanolar ve diğer küçük tekneler de bu bölümde sergilenmektedir.",
            coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294)
        ),Exhibit(
            name: "İletişim Araçları",
            description: "Bilimin endüstri ile birleşmesi sonucu gerçekleşen iletişim devrimi ile ortaya çıkan; telgraf, telefon, diktafon, gramafon, kamera ve televizyon gibi önemli iletişim aletlerinin çok nadir örneklerinin bir araya geldiği koleksiyon, Mustafa V. Koç Binası’nda görülebilir.",
            coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294)
        ),Exhibit(
            name: "Makineler",
            description: "Türkiye’de ve yurt dışında üretilmiş buharlı ve dizel motorların yer aldığı koleksiyon, endüstrinin gelişimine önemli bir ışık tutmaktadır. Mustafa V. Koç Binası’nda yer alan Kalender Gemisi’nin buharlı ana makinesi ve Tersane Binası’ndaki Marshall seyyar buhar makinesi, türlerinin önemli örnekleri arasında yer almaktadır.",
            coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294)
        ),Exhibit(
            name: "Kara Yolu Ulaşımı",
            description: "Bu bölümde, farklı içerikleri barındıran koleksiyonlar bulunmaktadır. Anamorfoz Rahmi M. Koç Portresi, Mehmet Memduh Önger Marklin Tren Koleksiyonu, Raoul Cabib Koleksiyonu ve daha nicesi bulunmaktadır.",
            coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294)
        ),Exhibit(
            name: "Fenerbahçe Vapuru",
            description: "Fenerbahçe Vapuru, eşi Dolmabahçe Vapuru ile birlikte 1952'de İskoçya Glasgow'da William Denny&Brothers Dumbarton tezgahlarında inşa edilmiştir. “Bahçe tipi” vapurların bir üyesi olan vapur, Şirket-i Hayriye'de (Bugünkü adıyla Türkiye Denizcilik İşletmeleri) 14 Mayıs 1953 tarihinde hizmete girmiştir. Uzun yıllar Sirkeci-Adalar-Yalova-Çınarcık arasında sefer yapan vapur, 22 Aralık 2008 tarihinde Veda Turu isimli son seferini gerçekleştirmiştir. Her biri 1.500 beygir gücünde 2 adet Sulzer dizel motoru bulunan, çift uskurlu ve saatte 18 mil hız yapabilen vapur, kocaman bacası ve özellikle ahşap aksamı ile göz doldurmaktadır. 2009 yılında Rahmi M. Koç Müzesi’ne gelişinden itibaren müze vapur olarak ziyarete açılan Fenerbahçe Vapuru, Yalvaç Ural Oyuncak Koleksiyonu’na ev sahipliği yapmaktadır. Bunun yanı sıra geçici sergilere ve müze eğitim çalışmalarına yer verilmektedir. Fenerbahçe Vapuru nostaljik kafesinde ise ziyaretçiler Haliç üzerinde keyifli anlar yaşamaktadır.Fenerbahçe Vapuru, İstanbul Büyükşehir Belediyesi tarafından süreli olarak verilmiştir.",
            coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294)
        ),
        // Add more exhibits as needed
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(exhibits, id: \.name) { exhibit in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(exhibit.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        
                        Text(exhibit.description)
                            .font(.body)
                            .foregroundColor(.black)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .navigationTitle("Exhibits")
    }
}

struct ContentPage_Previews: PreviewProvider {
    static var previews: some View {
        ContentPage()
    }
}


struct Exhibit {
    let name: String
    let description: String // This comes before coordinate in the initializer
    let coordinate: CLLocationCoordinate2D
}


struct PreferencesView: View {
    @Binding var preferences: [String: Bool]
    @State private var showSuggestedRooms = false // New state to control navigation
    
    var body: some View {
        NavigationView {
            Form {
                Toggle("Would you like to learn more about Atatürk?", isOn: binding(for: "Atatürk"))
                Toggle("Would you like to see the railway transports and trains?", isOn: binding(for: "Train"))
                Toggle("Are you interested in aircrafts?", isOn: binding(for: "Plane"))
                Toggle("Would you like to see the highway transports and heavy vehicles?", isOn: binding(for: "Car"))
                Toggle("Would you like to see the toys collection?", isOn: binding(for: "Toys"))
                Toggle("Would you like to have a periodical experience?", isOn: binding(for: "Period"))
                Toggle("Are you interested in scientific gadgets?", isOn: binding(for: "Science"))
                Toggle("Are you interested in sea transportations and vessels?", isOn: binding(for: "Ship"))
                Toggle("Are you interested in history of communication?", isOn: binding(for: "Comms"))
                Toggle("Would you like to see the motors collection?", isOn: binding(for: "Motor"))
                Toggle("Would you like to see the Fenerbahçe ferry?", isOn: binding(for: "Ferry"))
            }
            .navigationTitle("Preferences")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") {
                        showSuggestedRooms = true
                    }
                }
            }
            .sheet(isPresented: $showSuggestedRooms) {
                SuggestedRoomsView(preferences: preferences)
            }
        }
    }

    private func binding(for key: String) -> Binding<Bool> {
        Binding(
            get: { preferences[key] ?? false },
            set: { preferences[key] = $0 }
        )
    }
}

struct SuggestedRoomsView: View {
    let preferences: [String: Bool]
    
    // Map preferences to suggested rooms
    private var suggestedRooms: [String] {
        var rooms: [String] = []
        
        if preferences["Atatürk"] == true { rooms.append("T01") }
        if preferences["Train"] == true { rooms.append(contentsOf: ["L17", "L01", "L04", "L06", "L07", "T20"]) }
        if preferences["Plane"] == true { rooms.append(contentsOf: ["L15", "DC-3 yolcu uçağı", "Açık Teşhir alanı", "b-24 Liberatör", "F-104 savaş uçağı"]) }
        if preferences["Car"] == true { rooms.append(contentsOf: ["L17", "L05", "T06", "T11", "T07", "T09", "T10"]) }
        if preferences["Toys"] == true { rooms.append("L18") }
        if preferences["Period"] == true { rooms.append(contentsOf: ["L16", "L20", "T13", "T14", "T17(A-G)"]) }
        if preferences["Science"] == true { rooms.append(contentsOf: ["L08", "L09", "L10", "L11", "T03"]) }
        if preferences["Ship"] == true { rooms.append(contentsOf: ["L19", "L02", "L07", "T02", "T15", "T18", "T19(A-D)"]) }
        if preferences["Comms"] == true { rooms.append(contentsOf: ["L12", "L13", "L14", "L21"]) }
        if preferences["Motor"] == true { rooms.append(contentsOf: ["L03", "T12", "T19E"]) }
        if preferences["Ferry"] == true { rooms.append("Fenerbahçe Vapuru") }
        
        return rooms
    }
    
    var body: some View {
        NavigationView {
            List(suggestedRooms, id: \.self) { room in
                Text(room)
            }
            .navigationTitle("Suggested Rooms")
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
            
            if annotations.count >= 2 {
                calculateRoute()
            }
        }
        
        private func calculateRoute() {
            guard annotations.count >= 2 else { return }
            
            var routeRequests: [MKDirections.Request] = []
            
            // Create a request for each segment in the route
            for i in 0..<(annotations.count - 1) {
                let source = annotations[i].coordinate
                let destination = annotations[i + 1].coordinate
                
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
                request.transportType = .walking
                routeRequests.append(request)
            }
            
            // Calculate each route sequentially
            for request in routeRequests {
                let directions = MKDirections(request: request)
                directions.calculate { [weak self] response, error in
                    guard let self = self, let route = response?.routes.first else { return }
                    
                    // Add the route polyline to the map
                    DispatchQueue.main.async {
                        self.mapView.addOverlay(route.polyline)
                    }
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
