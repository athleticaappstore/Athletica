import Foundation

struct OFFResponse: Codable { let product: OFFProduct? }
struct OFFProduct: Codable { let productName: String?; let nutriments: OFFNutrients? }
struct OFFNutrients: Codable { let energyKcal100g: Double?; let proteins100g: Double?; let carbohydrates100g: Double?; let fat100g: Double?
    enum CodingKeys:String,CodingKey {case energyKcal100g="energy-kcal_100g";case proteins100g="proteins_100g";case carbohydrates100g="carbohydrates_100g";case fat100g="fat_100g"}
}

struct FoodLookup: Identifiable { let id=UUID(); let name:String; let calories:Int; let protein:Int; let carbs:Int; let fat:Int }

enum FoodAPI {
    static func lookup(barcode:String) async throws -> FoodLookup {
        let url=URL(string:"https://world.openfoodfacts.org/api/v2/product/\(barcode).json")!
        let (data,response)=try await URLSession.shared.data(from:url)
        guard let http=response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {throw URLError(.badServerResponse)}
        let result=try JSONDecoder().decode(OFFResponse.self,from:data)
        guard let p=result.product, let n=p.nutriments else {throw URLError(.cannotParseResponse)}
        return FoodLookup(name:p.productName?.isEmpty == false ? p.productName! : "Scanned food",calories:Int(n.energyKcal100g ?? 0),protein:Int(n.proteins100g ?? 0),carbs:Int(n.carbohydrates100g ?? 0),fat:Int(n.fat100g ?? 0))
    }
}
