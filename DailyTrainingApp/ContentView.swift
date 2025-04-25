import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: TrainingViewModel
    @State private var showingAddPlan = false
    @State private var newPlanName = ""
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: TrainingViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.trainingPlans, id: \.id) { plan in
                    NavigationLink(destination: PlanDetailView(plan: plan, viewModel: viewModel)) {
                        VStack(alignment: .leading) {
                            Text(plan.name ?? "未命名计划")
                                .font(.headline)
                            
                            if let date = plan.createdAt {
                                Text("创建于: \(dateFormatter.string(from: date))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let sections = plan.sections?.allObjects as? [TrainingSection], !sections.isEmpty {
                                HStack {
                                    ForEach(sections.sorted(by: { $0.order < $1.order }), id: \.id) { section in
                                        if let type = section.type, let sectionType = TrainingSectionType(rawValue: type) {
                                            Circle()
                                                .fill(sectionType.color)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .onDelete(perform: deletePlans)
            }
            .navigationTitle("训练计划")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPlan = true }) {
                        Label("添加计划", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPlan) {
                AddPlanView(isPresented: $showingAddPlan, viewModel: viewModel)
            }
            .onAppear {
                // 首次启动时创建示例数据
                viewModel.createSampleData()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func deletePlans(offsets: IndexSet) {
        withAnimation {
            offsets.map { viewModel.trainingPlans[$0] }.forEach(viewModel.deletePlan)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

struct AddPlanView: View {
    @Binding var isPresented: Bool
    @State private var planName = ""
    var viewModel: TrainingViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("计划信息")) {
                    TextField("计划名称", text: $planName)
                }
                
                Section {
                    Button("创建计划") {
                        if !planName.isEmpty {
                            viewModel.createTrainingPlan(name: planName)
                            isPresented = false
                        }
                    }
                    .disabled(planName.isEmpty)
                }
            }
            .navigationTitle("新训练计划")
            .navigationBarItems(trailing: Button("取消") {
                isPresented = false
            })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 