import Foundation
import HealthKit
import Combine

final class HealthKitManager: ObservableObject {

    @Published var steps: Int = 0
    @Published var activeCalories: Double = 0
    @Published var authorized: Bool = false

    private let healthStore = HKHealthStore()

    func requestAccess() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }

        guard
            let stepType = HKObjectType.quantityType(forIdentifier: .stepCount),
            let calorieType = HKObjectType.quantityType(
                forIdentifier: .activeEnergyBurned
            )
        else {
            return
        }

        do {
            try await healthStore.requestAuthorization(
                toShare: [],
                read: [stepType, calorieType]
            )

            await MainActor.run {
                self.authorized = true
            }

            await refresh()
        } catch {
            await MainActor.run {
                self.authorized = false
            }

            print("HealthKit authorization failed: \(error)")
        }
    }

    func requestAuthorization() async {
        await requestAccess()
    }

    func refresh() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }

        let end = Date()
        let start = Calendar.current.startOfDay(for: end)

        if let stepType = HKObjectType.quantityType(
            forIdentifier: .stepCount
        ) {
            let value = await sample(
                stepType,
                start: start,
                end: end,
                unit: .count()
            )

            await MainActor.run {
                self.steps = Int(value)
            }
        }

        if let calorieType = HKObjectType.quantityType(
            forIdentifier: .activeEnergyBurned
        ) {
            let value = await sample(
                calorieType,
                start: start,
                end: end,
                unit: .kilocalorie()
            )

            await MainActor.run {
                self.activeCalories = value
            }
        }
    }

    private func sample(
        _ type: HKQuantityType,
        start: Date,
        end: Date,
        unit: HKUnit
    ) async -> Double {

        await withCheckedContinuation { continuation in

            let predicate = HKQuery.predicateForSamples(
                withStart: start,
                end: end,
                options: .strictStartDate
            )

            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in

                if let error = error {
                    print("HealthKit query failed: \(error)")
                    continuation.resume(returning: 0)
                    return
                }

                let value = statistics?
                    .sumQuantity()?
                    .doubleValue(for: unit) ?? 0

                continuation.resume(returning: value)
            }

            self.healthStore.execute(query)
        }
    }
}
