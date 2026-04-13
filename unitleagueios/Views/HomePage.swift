//
//  HomePage.swift
//  unitleagueios
//
//  Created by Quinn Fargen on 3/23/26.
//

import SwiftUI

struct HomePageView: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.black, Color.blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                HStack(spacing: 20) {
                    Image(systemName: "house")
                    Image(systemName: "airplane.ticket")
                    Image(systemName: "figure.golf")
                    Image(systemName: "brain.head.profile")
//                    GlassButton(title: "Home")
//                    GlassButton(title: "Ticket")
//                    GlassButton(title: "League")
//                    GlassButton(title: "Profile")
                }
                .padding()
                .background(
                    Color.white.opacity(0.05)
                        .blur(radius: 10)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                )
                .padding(.bottom, 30)
            }
        }
    }
}

struct GlassButton: View {
    var title: String

    var body: some View {
        Button(action: {
            // TODO: Add navigation
        }) {
            VStack(spacing: 8) {
                // Placeholder icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(width: 70, height: 70)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial) // glass effect

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
            )
        }
    }
}

#Preview {
    HomePageView()
}
