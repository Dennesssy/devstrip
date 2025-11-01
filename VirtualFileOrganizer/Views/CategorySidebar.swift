import SwiftUI

struct CategorySidebar: View {
    let categories: [FileCategory]
    @Binding var selectedCategory: FileCategory?
    
    var body: some View {
        List(FileCategory.allCases, id: \.self, selection: $selectedCategory) { category in
            CategoryRow(
                category: category,
                count: categories.firstIndex(of: category).map { _ in 1 } ?? 0,
                isSelected: selectedCategory == category
            )
        }
        .navigationTitle("Categories")
        .listStyle(.sidebar)
    }
}

struct CategoryRow: View {
    let category: FileCategory
    let count: Int
    let isSelected: Bool
    
    var body: some View {
        Label {
            HStack {
                Text(category.rawValue)
                Spacer()
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        } icon: {
            Image(systemName: category.iconName)
                .foregroundColor(category.color)
                .frame(width: 20)
        }
    }
}

#Preview {
    CategorySidebar(
        categories: [.developmentTools, .aiAssistants, .configurations],
        selectedCategory: .constant(nil)
    )
}
