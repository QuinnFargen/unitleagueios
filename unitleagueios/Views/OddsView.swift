//
//  OddsView.swift
//  unitleagueios
//
//  Created by Quinn Fargen on 11/16/25.
//


import SwiftUI

struct BettingGameView: View {
    var body: some View {
        VStack(spacing: 24) {
            // ---- HEADER ROW ----
            HStack {
               Spacer()
               Text("SPR")
                    .padding(.trailing, 55)
               Text("TOT")
                    .padding(.trailing, 60)
               Text("ML")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.gray)
            .padding(.top, 4)
            .padding(.horizontal, 8)

            GameRowView(
                time: "7:07 PM",
                team1: Team(name: "Yankees", record: "4-4, 3rd AL East", abbr: "NY"),
                team2: Team(name: "Blue Jays", record: "5-3, 2nd AL East", abbr: "TOR"),
                bets: [
                    BetOption(title: "+2.5", odds: "-110"),
                    BetOption(title: "-2.5", odds: "-110", isSelected: true)
                ],
                totals: [
                    BetOption(title: "O 9.5", odds: "-110"),
                    BetOption(title: "U 9.5", odds: "-110")
                ],
                money: [
                    BetOption(title: "+180", odds: "NY"),
                    BetOption(title: "-240", odds: "TOR")
                ]
            )

            GameRowView(
                time: "7:35 PM",
                team1: Team(name: "Rays", record: "3-5, 4th AL East", abbr: "TB"),
                team2: Team(name: "Red Sox", record: "2-6, 5th AL East", abbr: "BOS"),
                bets: [
                    BetOption(title: "-1.5", odds: "-105"),
                    BetOption(title: "+1.5", odds: "-125")
                ],
                totals: [
                    BetOption(title: "O 10.5", odds: "-110"),
                    BetOption(title: "U 10.5", odds: "-110")
                ],
                money: [
                    BetOption(title: "-175", odds: "TB", isSelected: true),
                    BetOption(title: "+150", odds: "BOS")
                ]
            )
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: Models

struct Team {
    var name: String
    var record: String
    var abbr: String
}

struct BetOption {
    var title: String
    var odds: String?
    var isSelected: Bool = false
}

// MARK: Components

struct GameRowView: View {
    var time: String
    var team1: Team
    var team2: Team

    var bets: [BetOption]
    var totals: [BetOption]
    var money: [BetOption]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text(time)
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 14, weight: .medium))
                Spacer()
//                Text("See All Bets")
//                    .foregroundColor(.blue)
//                    .font(.system(size: 14, weight: .medium))
            }
            HStack{
                VStack{
                    TeamRow(team: team1)
                    TeamRow(team: team2)
                }
                
                HStack(spacing: 12) {
                    BetColumn(options: bets)
                    BetColumn(options: totals)
                    BetColumn(options: money)
                }
            }
        }
    }
}

struct TeamRow: View {
    var team: Team
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
//                Text(team.abbr)
//                    .foregroundColor(.white.opacity(0.7))
//                    .font(.system(size: 12))
                Text(team.name)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
                Text(team.record)
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
            }
            Spacer()
        }
    }
}

struct BetColumn: View {
    var options: [BetOption]
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<options.count, id: \.self) { i in
                let option = options[i]
                VStack {
                    Text(option.title)
                        .font(.system(size: 16, weight: .semibold))
                    if let odds = option.odds {
                        Text(odds)
                            .font(.system(size: 13))
                    }
                }
                .frame(width: 70, height: 50)
                .background(option.isSelected ? Color.green : Color.white.opacity(0.08))
                .cornerRadius(10)
                .foregroundColor(option.isSelected ? .white : .white)
            }
        }
    }
}

//struct BettingGameView_Previews: PreviewProvider {
//    static var previews: some View {
//        BettingGameView()
//            .preferredColorScheme(.dark)
//    }
//}


#Preview {
    BettingGameView()
        .preferredColorScheme(.dark)
}
