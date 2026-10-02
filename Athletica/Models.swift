import Foundation
import SwiftUI

struct FoodEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var meal: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var date: Date
    init(id: UUID = UUID(), name: String, meal: String, calories: Int, protein: Int, carbs: Int, fat: Int, date: Date = .now) {
        self.id=id; self.name=name; self.meal=meal; self.calories=calories; self.protein=protein; self.carbs=carbs; self.fat=fat; self.date=date
    }
}

struct WorkoutEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var type: String
    var duration: Int
    var calories: Int
    var date: Date
    var notes: String
    init(id: UUID = UUID(), name: String, type: String, duration: Int, calories: Int, date: Date = .now, notes: String = "") {
        self.id=id; self.name=name; self.type=type; self.duration=duration; self.calories=calories; self.date=date; self.notes=notes
    }
}

struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var sets: Int
    var reps: Int
    var weight: Double
    init(id: UUID = UUID(), name: String, sets: Int=3, reps: Int=10, weight: Double=0) { self.id=id; self.name=name; self.sets=sets; self.reps=reps; self.weight=weight }
}

struct DailyRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var weight: Double
    var steps: Int
    init(id: UUID = UUID(), date: Date = .now, weight: Double=75, steps: Int=0) { self.id=id; self.date=date; self.weight=weight; self.steps=steps }
}

@MainActor final class AppStore: ObservableObject {
    @Published var foods:[FoodEntry]=[] { didSet { save() } }
    @Published var workouts:[WorkoutEntry]=[] { didSet { save() } }
    @Published var exercises:[Exercise]=[] { didSet { save() } }
    @Published var records:[DailyRecord]=[] { didSet { save() } }
    @Published var water:Double=0 { didSet { save() } }
    @Published var calorieGoal=2200 { didSet { save() } }
    @Published var proteinGoal=150 { didSet { save() } }
    @Published var carbGoal=250 { didSet { save() } }
    @Published var fatGoal=70 { didSet { save() } }
    @Published var waterGoal=2.5 { didSet { save() } }
    @Published var stepGoal=10000 { didSet { save() } }
    @Published var onboardingComplete=false { didSet { save() } }
    @Published var healthKitEnabled=false { didSet { save() } }
    @Published var healthSteps=0 { didSet { save() } }
    @Published var healthActiveCalories=0 { didSet { save() } }
    private let key="athletica.store.v3"; private var loading=false
    init(){ load(); if foods.isEmpty && workouts.isEmpty && !onboardingComplete { } }
    var todayFoods:[FoodEntry]{ foods.filter{Calendar.current.isDateInToday($0.date)} }
    var todayWorkouts:[WorkoutEntry]{ workouts.filter{Calendar.current.isDateInToday($0.date)} }
    var calories:Int{todayFoods.reduce(0){$0+$1.calories}}
    var protein:Int{todayFoods.reduce(0){$0+$1.protein}}
    var carbs:Int{todayFoods.reduce(0){$0+$1.carbs}}
    var fat:Int{todayFoods.reduce(0){$0+$1.fat}}
    var workoutCalories:Int{todayWorkouts.reduce(0){$0+$1.calories}}
    var workoutMinutes:Int{todayWorkouts.reduce(0){$0+$1.duration}}
    var caloriesRemaining:Int{max(calorieGoal-calories,0)}
    func addFood(_ f:FoodEntry){foods.insert(f,at:0)}
    func addWorkout(_ w:WorkoutEntry){workouts.insert(w,at:0)}
    func addExercise(_ e:Exercise){exercises.append(e)}
    func addWater(_ amount:Double){water=min(water+amount,waterGoal+2)}
    func resetWater(){water=0}
    func resetAll(){foods=[];workouts=[];exercises=[];records=[];water=0;healthSteps=0;healthActiveCalories=0}
    private struct Snapshot:Codable {var foods:[FoodEntry];var workouts:[WorkoutEntry];var exercises:[Exercise];var records:[DailyRecord];var water:Double;var calorieGoal:Int;var proteinGoal:Int;var carbGoal:Int;var fatGoal:Int;var waterGoal:Double;var stepGoal:Int;var onboardingComplete:Bool;var healthKitEnabled:Bool;var healthSteps:Int;var healthActiveCalories:Int}
    private func save(){guard !loading else{return};let s=Snapshot(foods:foods,workouts:workouts,exercises:exercises,records:records,water:water,calorieGoal:calorieGoal,proteinGoal:proteinGoal,carbGoal:carbGoal,fatGoal:fatGoal,waterGoal:waterGoal,stepGoal:stepGoal,onboardingComplete:onboardingComplete,healthKitEnabled:healthKitEnabled,healthSteps:healthSteps,healthActiveCalories:healthActiveCalories);if let d=try? JSONEncoder().encode(s){UserDefaults.standard.set(d,forKey:key)}}
    private func load(){guard let d=UserDefaults.standard.data(forKey:key),let s=try? JSONDecoder().decode(Snapshot.self,from:d) else{return};loading=true;foods=s.foods;workouts=s.workouts;exercises=s.exercises;records=s.records;water=s.water;calorieGoal=s.calorieGoal;proteinGoal=s.proteinGoal;carbGoal=s.carbGoal;fatGoal=s.fatGoal;waterGoal=s.waterGoal;stepGoal=s.stepGoal;onboardingComplete=s.onboardingComplete;healthKitEnabled=s.healthKitEnabled;healthSteps=s.healthSteps;healthActiveCalories=s.healthActiveCalories;loading=false}
}

struct WorkoutType:Identifiable,Hashable {let id=UUID();let name:String;let icon:String;let color:Color;let subtitle:String
    static let all=[WorkoutType(name:"Strength",icon:"dumbbell.fill",color:.mint,subtitle:"Build strength and muscle"),WorkoutType(name:"Running",icon:"figure.run",color:.orange,subtitle:"Distance and endurance"),WorkoutType(name:"Cycling",icon:"figure.outdoor.cycle",color:.blue,subtitle:"Ride and build fitness"),WorkoutType(name:"HIIT",icon:"figure.highintensity.intervaltraining",color:.pink,subtitle:"Short, intense sessions"),WorkoutType(name:"Swimming",icon:"figure.pool.swim",color:.cyan,subtitle:"Laps and endurance"),WorkoutType(name:"Sport",icon:"sportscourt.fill",color:.purple,subtitle:"Football, tennis and more")]
}

struct QuickFood:Identifiable {let id=UUID();let name:String;let icon:String;let entry:FoodEntry
 static let all=[QuickFood(name:"Eggs + Toast",icon:"sunrise.fill",entry:FoodEntry(name:"Eggs + Toast",meal:"Breakfast",calories:390,protein:22,carbs:36,fat:18)),QuickFood(name:"Chicken Rice Bowl",icon:"fork.knife",entry:FoodEntry(name:"Chicken Rice Bowl",meal:"Lunch",calories:560,protein:45,carbs:62,fat:12)),QuickFood(name:"Protein Shake",icon:"figure.strengthtraining.traditional",entry:FoodEntry(name:"Protein Shake",meal:"Snack",calories:180,protein:30,carbs:8,fat:3)),QuickFood(name:"Greek Yogurt",icon:"takeoutbag.and.cup.and.straw",entry:FoodEntry(name:"Greek Yogurt",meal:"Snack",calories:150,protein:16,carbs:12,fat:4))]
}
