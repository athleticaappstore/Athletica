import Foundation
import HealthKit

@MainActor final class HealthKitManager: ObservableObject {
    @Published var authorized=false
    @Published var steps=0
    @Published var activeCalories=0
    private let store=HKHealthStore()
    var available:Bool { HKHealthStore.isHealthDataAvailable() }
    func requestAccess() async {
        guard available else { return }
        let read:Set<HKObjectType>=[HKObjectType.quantityType(forIdentifier:.stepCount)!,HKObjectType.quantityType(forIdentifier:.activeEnergyBurned)!]
        do { try await store.requestAuthorization(toShare: [], read: read); authorized=true; await refresh() } catch { authorized=false }
    }
    func refresh() async {
        guard available else{return}
        let start=Calendar.current.startOfDay(for:.now); let end=Date()
        if let t=HKObjectType.quantityType(forIdentifier:.stepCount), let q=try? await sample(t,start,end,unit: .count()){steps=Int(q)}
        if let t=HKObjectType.quantityType(forIdentifier:.activeEnergyBurned), let q=try? await sample(t,start,end,unit: .kilocalorie()){activeCalories=Int(q)}
    }
    private func sample(_ type:HKQuantityType,start:Date,end:Date,unit:HKUnit) async throws -> Double {
        try await withCheckedThrowingContinuation { cont in
            let pred=HKQuery.predicateForSamples(withStart:start,end:end,options:.strictStartDate)
            let q=HKStatisticsQuery(quantityType:type,quantitySamplePredicate:pred,options:.cumulativeSum){_,stats,error in
                if let error {cont.resume(throwing:error);return};cont.resume(returning:stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            };store.execute(q)
        }
    }
}
