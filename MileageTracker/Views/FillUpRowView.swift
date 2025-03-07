import SwiftUI

struct FillUpRowView: View {
    let fillUp: FuelFillUp
    @ObservedObject var store: MileageStore
    @State private var showingEditSheet = false
    
    var body: some View {
        Button(action: { showingEditSheet = true }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(fillUp.location)
                        .font(.headline)
                    Text("\(fillUp.volume, specifier: "%.1f")L • $\(fillUp.amount, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(fillUp.odometer, specifier: "%.0f") km")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                EditFillUpView(store: store, fillUp: fillUp)
            }
        }
    }
} 