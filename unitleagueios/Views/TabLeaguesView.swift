import SwiftUI

struct TabLeaguesView: View {
    @State private var showingJoin = false
    @State private var showingCreate = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Leagues")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Spacer().frame(height: 8)

                LeagueActionButton(title: "Join League", icon: "person.badge.plus", color: .green) {
                    showingJoin = true
                }

                LeagueActionButton(title: "Create League", icon: "plus.circle", color: .blue) {
                    showingCreate = true
                }
            }
            .padding(.horizontal, 32)
        }
        .sheet(isPresented: $showingJoin) {
            LeagueFormSheet(title: "Join League", confirmLabel: "Join")
        }
        .sheet(isPresented: $showingCreate) {
            LeagueFormSheet(title: "Create League", confirmLabel: "Create")
        }
    }
}

private struct LeagueActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

private struct LeagueFormSheet: View {
    let title: String
    let confirmLabel: String

    @Environment(\.dismiss) private var dismiss
    @State private var leagueNumber = 1
    @State private var leagueName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Form {
                    Section("League Number") {
                        Picker("League", selection: $leagueNumber) {
                            ForEach(1...6, id: \.self) { n in
                                Text("League \(n)").tag(n)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }

                    Section("League Name") {
                        TextField("Enter a name", text: $leagueName)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmLabel) {
                        dismiss()
                    }
                    .disabled(leagueName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .tint(.green)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    TabLeaguesView()
}
