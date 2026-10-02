import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var health: HealthKitManager
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                HomeView(tab: $tab)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                FuelView()
            }
            .tabItem {
                Label("Fuel", systemImage: "fork.knife")
            }
            .tag(1)

            NavigationStack {
                TrainView()
            }
            .tabItem {
                Label("Train", systemImage: "figure.strengthtraining.traditional")
            }
            .tag(2)

            NavigationStack {
                ProgressViewScreen()
            }
            .tabItem {
                Label("Progress", systemImage: "chart.xyaxis.line")
            }
            .tag(3)
        }
        .tint(.mint)
        .preferredColorScheme(.dark)
        .sheet(
            isPresented: Binding(
                get: { !store.onboardingComplete },
                set: {
                    if !$0 {
                        store.onboardingComplete = true
                    }
                }
            )
        ) {
            OnboardingView()
        }
    }
}

// MARK: - Home

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var health: HealthKitManager
    @Binding var tab: Int
    @State private var settings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(
                            Date.now,
                            format: .dateTime
                                .weekday(.wide)
                                .month(.abbreviated)
                                .day()
                        )
                        .foregroundStyle(.secondary)

                        Text("Train. Fuel. Recover.")
                            .font(.largeTitle.bold())
                    }

                    Spacer()

                    Button {
                        settings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                }

                HStack {
                    MetricCard(
                        title: "Calories",
                        value: "\(store.calories)",
                        detail: "/ \(store.calorieGoal) kcal",
                        icon: "flame.fill"
                    )

                    MetricCard(
                        title: "Protein",
                        value: "\(store.protein)g",
                        detail: "/ \(store.proteinGoal)g",
                        icon: "bolt.fill"
                    )
                }

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Today's fuel")
                                .font(.headline)

                            Spacer()

                            Text("\(store.caloriesRemaining) kcal left")
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(
                            value: min(
                                Double(store.calories) /
                                Double(max(store.calorieGoal, 1)),
                                1
                            )
                        )
                        .tint(.orange)

                        HStack {
                            MacroMini(
                                label: "P",
                                value: store.protein,
                                goal: store.proteinGoal,
                                color: .mint
                            )

                            MacroMini(
                                label: "C",
                                value: store.carbs,
                                goal: store.carbGoal,
                                color: .blue
                            )

                            MacroMini(
                                label: "F",
                                value: store.fat,
                                goal: store.fatGoal,
                                color: .orange
                            )
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Activity")
                                .font(.headline)

                            Spacer()

                            Text("Health data")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            ActivityMetric(
                                icon: "figure.walk",
                                value: "\(health.steps)",
                                label: "steps"
                            )

                            ActivityMetric(
                                icon: "flame.fill",
                                value: "\(health.activeCalories)",
                                label: "active kcal"
                            )

                            ActivityMetric(
                                icon: "figure.run",
                                value: "\(store.workoutMinutes)m",
                                label: "training"
                            )
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Hydration")
                                .font(.headline)

                            Spacer()

                            Text(
                                String(
                                    format: "%.1f / %.1f L",
                                    store.water,
                                    store.waterGoal
                                )
                            )
                            .foregroundStyle(.secondary)
                        }

                        ProgressView(
                            value: min(
                                store.water / max(store.waterGoal, 0.1),
                                1
                            )
                        )
                        .tint(.cyan)

                        HStack {
                            Button("+250 ml") {
                                store.addWater(0.25)
                            }
                            .buttonStyle(.bordered)

                            Button("+500 ml") {
                                store.addWater(0.5)
                            }
                            .buttonStyle(.bordered)

                            Spacer()
                        }
                    }
                }

                SectionTitle(title: "Today’s training")

                if let workout = store.todayWorkouts.first {
                    WorkoutRow(workout: workout)
                } else {
                    EmptyCard(
                        title: "No workout logged",
                        action: "Log workout"
                    ) {
                        tab = 2
                    }
                }

                SectionTitle(title: "Today’s meals")

                if store.todayFoods.isEmpty {
                    EmptyCard(
                        title: "Nothing logged yet",
                        action: "Add food"
                    ) {
                        tab = 1
                    }
                } else {
                    ForEach(store.todayFoods.prefix(3)) { food in
                        FoodRow(food: food)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Athletica")
        .task {
            await health.requestAccess()
            store.healthSteps = health.steps
            store.healthActiveCalories = health.activeCalories
        }
        .sheet(isPresented: $settings) {
            SettingsView()
        }
    }
}

// MARK: - Fuel

struct FuelView: View {
    @EnvironmentObject var store: AppStore

    @State private var add = false
    @State private var scan = false
    @State private var lookup: FoodLookup?
    @State private var error = ""

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    CircularProgress(
                        progress: min(
                            Double(store.calories) /
                            Double(max(store.calorieGoal, 1)),
                            1
                        )
                    )

                    Text("\(store.calories) / \(store.calorieGoal) kcal")
                        .font(.headline)

                    Text("\(store.caloriesRemaining) kcal remaining")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

                MacroBar(
                    label: "Protein",
                    value: store.protein,
                    goal: store.proteinGoal,
                    color: .mint
                )

                MacroBar(
                    label: "Carbs",
                    value: store.carbs,
                    goal: store.carbGoal,
                    color: .blue
                )

                MacroBar(
                    label: "Fat",
                    value: store.fat,
                    goal: store.fatGoal,
                    color: .orange
                )
            }

            Section("Quick add") {
                ForEach(QuickFood.all) { food in
                    Button {
                        store.addFood(food.entry)
                    } label: {
                        HStack {
                            Image(systemName: food.icon)
                                .foregroundStyle(.mint)

                            VStack(alignment: .leading) {
                                Text(food.name)
                                    .foregroundStyle(.primary)

                                Text(
                                    "\(food.entry.calories) kcal • P \(food.entry.protein)g"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }

            Section("Hydration") {
                HStack {
                    Text(String(format: "%.1f L", store.water))

                    Spacer()

                    Button("+250 ml") {
                        store.addWater(0.25)
                    }

                    Button("Reset") {
                        store.resetWater()
                    }
                }
            }

            Section("Today's meals") {
                ForEach(store.todayFoods) { food in
                    FoodRow(food: food)
                }
                .onDelete { indexes in
                    let ids = indexes.map {
                        store.todayFoods[$0].id
                    }

                    store.foods.removeAll {
                        ids.contains($0.id)
                    }
                }
            }
        }
        .navigationTitle("Fuel & Calories")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    scan = true
                } label: {
                    Image(systemName: "barcode.viewfinder")
                }

                Button {
                    add = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $add) {
            AddFoodView()
        }
        .sheet(isPresented: $scan) {
            BarcodeScannerView { code in
                scan = false

                Task {
                    do {
                        lookup = try await FoodAPI.lookup(barcode: code)
                    } catch {
                        self.error = "Food not found. Add it manually."
                    }
                }
            }
        }
        .sheet(item: $lookup) { food in
            ScannedFoodView(food: food)
        }
        .alert(
            "Barcode lookup",
            isPresented: Binding(
                get: { !error.isEmpty },
                set: {
                    if !$0 {
                        error = ""
                    }
                }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(error)
        }
    }
}

// MARK: - Training

struct TrainView: View {
    @EnvironmentObject var store: AppStore

    @State private var add = false
    @State private var builder = false

    var body: some View {
        List {
            Section {
                HStack {
                    StatPill(
                        value: "\(store.workoutMinutes)",
                        label: "min"
                    )

                    StatPill(
                        value: "\(store.todayWorkouts.count)",
                        label: "sessions"
                    )

                    StatPill(
                        value: "\(store.workoutCalories)",
                        label: "kcal"
                    )
                }
                .padding(.vertical, 6)
            }

            Section("Choose sport / training") {
                ForEach(WorkoutType.all) { type in
                    Button {
                        add = true
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                                .font(.title3)
                                .foregroundStyle(type.color)

                            VStack(alignment: .leading) {
                                Text(type.name)
                                    .foregroundStyle(.primary)

                                Text(type.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Workout history") {
                ForEach(
                    store.workouts.sorted {
                        $0.date > $1.date
                    }
                ) { workout in
                    WorkoutRow(workout: workout)
                }
                .onDelete { indexes in
                    store.workouts.remove(atOffsets: indexes)
                }
            }
        }
        .navigationTitle("Train & Sport")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    builder = true
                } label: {
                    Image(systemName: "list.bullet.rectangle")
                }

                Button {
                    add = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $add) {
            AddWorkoutView()
        }
        .sheet(isPresented: $builder) {
            WorkoutBuilderView()
        }
    }
}

// MARK: - Progress

struct ProgressViewScreen: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Your progress")
                    .font(.largeTitle.bold())

                HStack {
                    StatPill(
                        value: "\(store.todayWorkouts.count)",
                        label: "sessions"
                    )

                    StatPill(
                        value: "\(store.workoutMinutes)",
                        label: "minutes"
                    )

                    StatPill(
                        value: "\(store.calories)",
                        label: "kcal"
                    )
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Training this week")
                            .font(.headline)

                        HStack(
                            alignment: .bottom,
                            spacing: 8
                        ) {
                            ForEach(0..<7, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.mint)
                                    .frame(maxWidth: .infinity)
                                    .frame(
                                        height: [
                                            35,
                                            65,
                                            90,
                                            55,
                                            105,
                                            45,
                                            80
                                        ][index]
                                    )
                            }
                        }
                        .frame(height: 110, alignment: .bottom)

                        Text("M   T   W   T   F   S   S")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Nutrition goals")
                            .font(.headline)

                        GoalLine(
                            label: "Calories",
                            value: store.calories,
                            goal: store.calorieGoal,
                            color: .orange
                        )

                        GoalLine(
                            label: "Protein",
                            value: store.protein,
                            goal: store.proteinGoal,
                            color: .mint
                        )

                        GoalLine(
                            label: "Water",
                            value: Int(store.water * 10),
                            goal: Int(store.waterGoal * 10),
                            color: .cyan
                        )
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today")
                            .font(.headline)

                        Label(
                            "\(store.workoutMinutes) minutes training",
                            systemImage: "figure.run"
                        )

                        Label(
                            "\(store.workoutCalories) active calories logged",
                            systemImage: "flame.fill"
                        )

                        Label(
                            "\(store.protein)g protein",
                            systemImage: "bolt.fill"
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Progress")
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: AppStore

    @State var calories = "2200"
    @State var protein = "150"

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.mint)

                Text("Athletica")
                    .font(.largeTitle.bold())

                Text("Your gym, sport and nutrition in one app.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Form {
                    Section("Daily nutrition goal") {
                        TextField(
                            "Calories",
                            text: $calories
                        )
                        .keyboardType(.numberPad)

                        TextField(
                            "Protein (g)",
                            text: $protein
                        )
                        .keyboardType(.numberPad)
                    }
                }

                Button("Start Athletica") {
                    store.calorieGoal = Int(calories) ?? 2200
                    store.proteinGoal = Int(protein) ?? 150
                    store.onboardingComplete = true
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            }
            .padding()
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var health: HealthKitManager
    @EnvironmentObject var subscriptions: SubscriptionManager

    @State private var showPremium = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Athletica Premium") {
                    HStack {
                        Image(
                            systemName: subscriptions.isPremium
                                ? "checkmark.seal.fill"
                                : "sparkles"
                        )
                        .foregroundStyle(.mint)

                        VStack(alignment: .leading) {
                            Text(
                                subscriptions.isPremium
                                    ? "Premium Active"
                                    : "Try Premium Free"
                            )
                            .font(.headline)

                            Text(
                                subscriptions.isPremium
                                    ? "You have full Premium access."
                                    : "Unlock advanced training and nutrition tools."
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    if !subscriptions.isPremium {
                        Button("Start 7-Day Free Trial") {
                            showPremium = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.mint)
                    } else {
                        Button("Manage Subscription") {
                            showPremium = true
                        }
                    }

                    Button("Restore Purchases") {
                        Task {
                            await subscriptions.restore()
                        }
                    }
                }

                Section("Nutrition") {
                    Stepper(
                        "Calories: \(store.calorieGoal)",
                        value: $store.calorieGoal,
                        in: 1200...5000,
                        step: 50
                    )

                    Stepper(
                        "Protein: \(store.proteinGoal) g",
                        value: $store.proteinGoal,
                        in: 40...300,
                        step: 5
                    )

                    Stepper(
                        "Carbs: \(store.carbGoal) g",
                        value: $store.carbGoal,
                        in: 50...600,
                        step: 10
                    )

                    Stepper(
                        "Fat: \(store.fatGoal) g",
                        value: $store.fatGoal,
                        in: 20...200,
                        step: 5
                    )
                }

                Section("Activity") {
                    Stepper(
                        String(
                            format: "Water: %.1f L",
                            store.waterGoal
                        ),
                        value: $store.waterGoal,
                        in: 1...6,
                        step: 0.1
                    )

                    Stepper(
                        "Steps: \(store.stepGoal)",
                        value: $store.stepGoal,
                        in: 3000...30000,
                        step: 500
                    )
                }

                Section("Apple Health") {
                    Button(
                        health.authorized
                            ? "Refresh Health Data"
                            : "Connect Apple Health"
                    ) {
                        Task {
                            await health.requestAccess()
                            store.healthSteps = health.steps
                            store.healthActiveCalories =
                                health.activeCalories
                        }
                    }

                    Text(
                        "Steps and active calories are read from HealthKit after you grant permission."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Section {
                    Button("Reset all data", role: .destructive) {
                        store.resetAll()
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
            .sheet(isPresented: $showPremium) {
                PremiumView()
            }
        }
    }
}

// MARK: - Premium

struct PremiumView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var subscriptions: SubscriptionManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Athletica Premium")
                            .font(.largeTitle.bold())

                        Text("Train smarter. Fuel better. Track everything.")
                            .foregroundStyle(.secondary)
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(
                                "Unlimited workout plans",
                                systemImage: "figure.strengthtraining.traditional"
                            )

                            Label(
                                "Advanced nutrition insights",
                                systemImage: "chart.pie.fill"
                            )

                            Label(
                                "Progress trends & goals",
                                systemImage: "chart.line.uptrend.xyaxis"
                            )

                            Label(
                                "Premium coaching features",
                                systemImage: "sparkles"
                            )
                        }
                    }

                    Text(
                        "Start with a 7-day free trial. The trial and introductory offer must be configured for these products in App Store Connect before release."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                    if subscriptions.products.isEmpty {
                        ProgressView("Loading plans...")
                    } else {
                        ForEach(
                            subscriptions.products,
                            id: \.id
                        ) { product in
                            Button {
                                Task {
                                    await subscriptions.purchase(product)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(product.displayName)
                                            .font(.headline)

                                        Text(
                                            product.displayPrice +
                                            (
                                                product.id ==
                                                SubscriptionManager.monthlyID
                                                ? " / month"
                                                : " / year"
                                            )
                                        )
                                        .font(.subheadline)

                                        if let offer =
                                            product.subscription?.introductoryOffer {
                                            Text(
                                                offer.period.unit == .day
                                                    ? "Intro offer available"
                                                    : "Introductory offer available"
                                            )
                                            .font(.caption)
                                            .foregroundStyle(.mint)
                                        }
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                }
                                .padding()
                                .background(
                                    .white.opacity(0.07),
                                    in: RoundedRectangle(
                                        cornerRadius: 16
                                    )
                                )
                            }
                        }
                    }

                    Button("Restore Purchases") {
                        Task {
                            await subscriptions.restore()
                        }
                    }
                    .buttonStyle(.bordered)

                    if let message = subscriptions.message {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(
                        "Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in your Apple Account subscription settings."
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Premium")
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Add Food

struct AddFoodView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: AppStore

    @State var name = ""
    @State var meal = "Lunch"
    @State var calories = ""
    @State var protein = ""
    @State var carbs = ""
    @State var fat = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(
                    "Food / meal",
                    text: $name
                )

                Picker(
                    "Meal",
                    selection: $meal
                ) {
                    ForEach(
                        [
                            "Breakfast",
                            "Lunch",
                            "Dinner",
                            "Snack"
                        ],
                        id: \.self
                    ) {
                        Text($0)
                    }
                }

                TextField(
                    "Calories",
                    text: $calories
                )
                .keyboardType(.numberPad)

                TextField(
                    "Protein (g)",
                    text: $protein
                )
                .keyboardType(.numberPad)

                TextField(
                    "Carbs (g)",
                    text: $carbs
                )
                .keyboardType(.numberPad)

                TextField(
                    "Fat (g)",
                    text: $fat
                )
                .keyboardType(.numberPad)
            }
            .navigationTitle("Add Food")
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Add") {
                        store.addFood(
                            FoodEntry(
                                name: name.isEmpty ? "Meal" : name,
                                meal: meal,
                                calories: Int(calories) ?? 0,
                                protein: Int(protein) ?? 0,
                                carbs: Int(carbs) ?? 0,
                                fat: Int(fat) ?? 0
                            )
                        )

                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Add Workout

struct AddWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: AppStore

    @State var type = "Strength"
    @State var name = ""
    @State var duration = "45"
    @State var calories = "300"

    var body: some View {
        NavigationStack {
            Form {
                Picker(
                    "Type",
                    selection: $type
                ) {
                    ForEach(
                        WorkoutType.all.map { $0.name },
                        id: \.self
                    ) {
                        Text($0)
                    }
                }

                TextField(
                    "Workout name",
                    text: $name
                )

                TextField(
                    "Duration (min)",
                    text: $duration
                )
                .keyboardType(.numberPad)

                TextField(
                    "Calories burned",
                    text: $calories
                )
                .keyboardType(.numberPad)
            }
            .navigationTitle("Log Workout")
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Save") {
                        store.addWorkout(
                            WorkoutEntry(
                                name: name.isEmpty ? type : name,
                                type: type,
                                duration: Int(duration) ?? 0,
                                calories: Int(calories) ?? 0
                            )
                        )

                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Workout Builder

struct WorkoutBuilderView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: AppStore

    @State var name = "Strength Session"
    @State var exercise = "Bench Press"
    @State var sets = 3
    @State var reps = 10
    @State var weight = "60"

    var body: some View {
        NavigationStack {
            Form {
                TextField(
                    "Workout name",
                    text: $name
                )

                Section("Exercise") {
                    TextField(
                        "Exercise",
                        text: $exercise
                    )

                    Stepper(
                        "Sets: \(sets)",
                        value: $sets,
                        in: 1...10
                    )

                    Stepper(
                        "Reps: \(reps)",
                        value: $reps,
                        in: 1...50
                    )

                    TextField(
                        "Weight (kg)",
                        text: $weight
                    )
                    .keyboardType(.decimalPad)

                    Button("Add exercise") {
                        store.addExercise(
                            Exercise(
                                name: exercise,
                                sets: sets,
                                reps: reps,
                                weight: Double(weight) ?? 0
                            )
                        )
                    }
                }

                Section("Saved exercises") {
                    ForEach(store.exercises) { exercise in
                        HStack {
                            Text(exercise.name)

                            Spacer()

                            Text(
                                "\(exercise.sets) × \(exercise.reps) @ \(Int(exercise.weight))kg"
                            )
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Workout Builder")
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Scanned Food

struct ScannedFoodView: View {
    let food: FoodLookup

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: AppStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Found food") {
                    Text(food.name)
                        .font(.headline)

                    LabeledContent(
                        "Calories",
                        "\(food.calories) kcal / 100g"
                    )

                    LabeledContent(
                        "Protein",
                        "\(food.protein)g"
                    )

                    LabeledContent(
                        "Carbs",
                        "\(food.carbs)g"
                    )

                    LabeledContent(
                        "Fat",
                        "\(food.fat)g"
                    )
                }

                Section {
                    Button("Add to today's food") {
                        store.addFood(
                            FoodEntry(
                                name: food.name,
                                meal: "Snack",
                                calories: food.calories,
                                protein: food.protein,
                                carbs: food.carbs,
                                fat: food.fat
                            )
                        )

                        dismiss()
                    }
                }
            }
            .navigationTitle("Barcode Result")
        }
    }
}

// MARK: - Reusable Components

struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(
                .white.opacity(0.07),
                in: RoundedRectangle(cornerRadius: 18)
            )
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let detail: String
    let icon: String

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(.mint)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.title2.bold())

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct MacroMini: View {
    let label: String
    let value: Int
    let goal: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(color)

            Text("\(value)/\(goal)g")
                .font(.caption2)
        }
    }
}

struct MacroBar: View {
    let label: String
    let value: Int
    let goal: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)

                Spacer()

                Text("\(value)/\(goal)g")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            ProgressView(
                value: min(
                    Double(value) / Double(max(goal, 1)),
                    1
                )
            )
            .tint(color)
        }
    }
}

struct CircularProgress: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    .white.opacity(0.1),
                    lineWidth: 14
                )

            Circle()
                .trim(
                    from: 0,
                    to: progress
                )
                .stroke(
                    .orange,
                    style: StrokeStyle(
                        lineWidth: 14,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.title.bold())
        }
        .frame(
            width: 130,
            height: 130
        )
    }
}

struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack {
            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            .white.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 12)
        )
    }
}

struct ActivityMetric: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .foregroundStyle(.mint)

            Text(value)
                .bold()

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct SectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.top, 4)
    }
}

struct EmptyCard: View {
    let title: String
    let action: String
    let onTap: () -> Void

    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)

                    Text("Keep your streak moving.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(
                    action,
                    action: onTap
                )
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            }
        }
    }
}

struct WorkoutRow: View {
    let workout: WorkoutEntry

    var body: some View {
        HStack {
            Image(
                systemName:
                    WorkoutType.all.first {
                        $0.name == workout.type
                    }?.icon ?? "figure.run"
            )
            .foregroundStyle(.mint)
            .frame(width: 30)

            VStack(alignment: .leading) {
                Text(workout.name)
                    .font(.headline)

                Text(
                    "\(workout.type) • \(workout.duration) min • \(workout.calories) kcal"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct FoodRow: View {
    let food: FoodEntry

    var body: some View {
        HStack {
            Image(systemName: "fork.knife")
                .foregroundStyle(.mint)
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(food.name)

                Text(food.meal)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(food.calories) kcal")
                    .bold()

                Text(
                    "P \(food.protein) • C \(food.carbs) • F \(food.fat)"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }
}

struct GoalLine: View {
    let label: String
    let value: Int
    let goal: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)

                Spacer()

                Text("\(value)/\(goal)")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            ProgressView(
                value: min(
                    Double(value) / Double(max(goal, 1)),
                    1
                )
            )
            .tint(color)
        }
    }
}
