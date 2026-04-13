//
//  HomeView.swift
//  unitleagueios
//
//  Created by Quinn Fargen on 11/7/25.
//


import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(gradient: Gradient(colors: [.black, .gray]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Unit League")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    // Stats Summary
                    HStack(spacing: 16) {
                        SummaryCard(title: "Units", value: "+13.5")
                        SummaryCard(title: "Win %", value: "58%")
                        SummaryCard(title: "Record", value: "34-24")
                    }

                    // Featured Bets / Matchups
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Matchups")
                            .font(.headline)
                            .foregroundColor(.white)

                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 14) {
                                ForEach(0..<4) { _ in
                                    MatchCard()
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct SummaryCard: View {
    var title: String
    var value: String

    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(width: 90, height: 70)
        .background(Color(.darkGray))
        .cornerRadius(12)
    }
}

struct MatchCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Lakers @ Warriors")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("Tonight 7:00PM")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("+2.5")
                .font(.headline)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.darkGray))
        .cornerRadius(14)
    }
}



//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView()
//            .preferredColorScheme(.dark)
//    }
//}

#Preview {
    HomeView()
}
