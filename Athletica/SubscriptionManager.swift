import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let monthlyID = "com.example.athletica.premium.monthly"
    static let yearlyID = "com.example.athletica.premium.yearly"
    static let productIDs = [monthlyID, yearlyID]

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium = false
    @Published var isLoading = false
    @Published var message: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await result in Transaction.updates {
                await self.handle(result)
            }
        }
        Task { await load() }
    }

    deinit { updatesTask?.cancel() }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: Self.productIDs).sorted { $0.price < $1.price }
            await refreshEntitlement()
        } catch {
            message = "Products could not be loaded. Check your App Store Connect product IDs."
        }
    }

    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification): await handle(verification)
            case .userCancelled: break
            case .pending: message = "Your purchase is pending approval."
            @unknown default: break
            }
        } catch { message = error.localizedDescription }
    }

    func restore() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            message = isPremium ? "Your Premium access has been restored." : "No active Premium subscription was found."
        } catch { message = error.localizedDescription }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if Self.productIDs.contains(transaction.productID) {
            isPremium = transaction.revocationDate == nil && (transaction.expirationDate == nil || transaction.expirationDate! > Date())
        }
        await transaction.finish()
    }

    private func refreshEntitlement() async {
        for await result in Transaction.currentEntitlements {
            await handle(result)
        }
    }
}
