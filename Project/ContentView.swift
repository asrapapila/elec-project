//
//  ContentView.swift
//  Project
//
//  Created by Talin Harun on 10.12.2024.
//


import SwiftUI
import MapKit

struct InitialView: View {
    @State private var preferences: [String: Bool] = [
        "Ship": false,
        "Dinosaur": false,
        "Art": false
    ]

    var body: some View {
        VStack {
            Text("CULTURATI")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.purple)
                .padding(.bottom, 70)

            Text("Choose an Option")
                .font(.headline)
                .padding(.top, 20)

            NavigationLink(destination: ContentView(preferences: $preferences)) {
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

struct ContentView: View {
    @Binding var preferences: [String: Bool]
    @State private var mapView = MKMapView()
    @State private var annotations: [MKPointAnnotation] = []
    @State private var overlays: [MKOverlay] = []

    var exhibits: [Exhibit] = [
        Exhibit(name: "Ship", description: "Explore maritime history.", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)),
        Exhibit(name: "Dinosaur", description: "Learn about prehistoric creatures.", coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)),
        Exhibit(name: "Art", description: "Discover modern and classical art.", coordinate: CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.3994))
    ]

    var filteredExhibits: [Exhibit] {
        exhibits.filter { preferences[$0.name] ?? false }
    }

    var body: some View {
        ZStack {
            MapViewRepresentable(mapView: $mapView, annotations: $annotations, overlays: $overlays)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    setupMap()
                    addFilteredAnnotations()
                    addMockCrowdedness()
                }
            VStack {
                Text("Your selected exhibits have been pinned on the map.")
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

    private func setupMap() {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
    }

    private func addFilteredAnnotations() {
        for exhibit in filteredExhibits {
            let randomOffset = Double.random(in: -0.005...0.005)
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(
                latitude: exhibit.coordinate.latitude + randomOffset,
                longitude: exhibit.coordinate.longitude + randomOffset
            )
            annotation.title = exhibit.name
            annotations.append(annotation)
        }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(preferences: .constant([
            "Ship": true,
            "Dinosaur": false,
            "Art": true
        ]))
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

    var body: some View {
        Form {
            Toggle("Would you like to see the Ship Exhibition?", isOn: binding(for: "Ship"))
            Toggle("Would you like to see the Dinosaur Exhibition?", isOn: binding(for: "Dinosaur"))
            Toggle("Would you like to see the Art Gallery?", isOn: binding(for: "Art"))
        }
        .navigationTitle("Preferences")
    }

    private func binding(for key: String) -> Binding<Bool> {
        Binding(
            get: { preferences[key] ?? false },
            set: { preferences[key] = $0 }
        )
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



