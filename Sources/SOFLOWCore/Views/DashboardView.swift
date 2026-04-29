// DashboardView.swift
// Live ride dashboard — equivalent to the Android MainActivity once a
// scooter is connected. Shows the parsed MPStateData (via MPStateParser)
// and refreshes every notify frame the scooter sends.

import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject private var ble: BLEManager

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let s = ble.lastState {
                    speedTile(s)
                    batteryTile(s)
                    distanceTile(s)
                    statusTile(s)
                } else {
                    placeholder
                }
            }
            .padding()
        }
        .navigationTitle("Live Dashboard")
        .onAppear {
            ble.send { BleDataOperateManage.query() }
        }
    }

    // MARK: - Tiles

    private func speedTile(_ s: MPStateData) -> some View {
        tileBackground {
            VStack(spacing: 8) {
                Text("\(s.speed)")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                Text(s.unit ? "mph" : "km/h").foregroundColor(.secondary)
                HStack(spacing: 16) {
                    Pill("Mode \(s.speedMode)", color: .blue)
                    if s.lampStatus { Pill("Lights", color: .yellow) }
                    if s.lockStatus { Pill("Locked", color: .red) }
                }
            }
        }
    }

    private func batteryTile(_ s: MPStateData) -> some View {
        tileBackground {
            HStack {
                Image(systemName: batteryIcon(s.remainingCharge))
                    .font(.system(size: 36))
                    .foregroundColor(batteryColor(s.remainingCharge))
                VStack(alignment: .leading) {
                    Text("\(s.remainingCharge) %")
                        .font(.title2.bold())
                    Text("\(s.batteryVoltage) mV  •  \(s.batteryCurrent) mA")
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }

    private func distanceTile(_ s: MPStateData) -> some View {
        tileBackground {
            HStack(spacing: 24) {
                statBlock(label: "Trip", value: "\(s.distanceSingle)", unit: s.unit ? "mi" : "km")
                statBlock(label: "Total", value: "\(s.distanceAll)", unit: s.unit ? "mi" : "km")
                statBlock(label: "Time",  value: formatTime(s.singleRideTime), unit: "")
            }
        }
    }

    private func statusTile(_ s: MPStateData) -> some View {
        tileBackground {
            VStack(alignment: .leading, spacing: 4) {
                Text("Status").font(.headline)
                row("CPU L/R",     "\(s.cpuLeft) / \(s.cpuRight)")
                row("Display L/R", "\(s.displayLeft) / \(s.displayRight)")
                row("Comm L/R",    "\(s.communicationLeft) / \(s.communicationRight)")
                row("Dark mode",   "\(s.darkMode)")
                if s.faultBrake || s.faultController || s.faultMotor {
                    Text("⚠️ One or more faults — check the Faults screen.")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
    }

    private var placeholder: some View {
        tileBackground {
            VStack {
                ProgressView()
                Text("Waiting for scooter to send a state frame…")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }.padding()
        }
    }

    // MARK: - Bits

    private func tileBackground<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
    }

    private func statBlock(label: String, value: String, unit: String) -> some View {
        VStack {
            Text(value).font(.title3.bold()).monospacedDigit()
            Text("\(label)\(unit.isEmpty ? "" : " (\(unit))")")
                .font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).monospacedDigit()
        }.font(.caption)
    }

    private func batteryIcon(_ pct: Int) -> String {
        switch pct {
        case 0..<10:  return "battery.0"
        case 10..<25: return "battery.25"
        case 25..<50: return "battery.50"
        case 50..<75: return "battery.75"
        default:      return "battery.100"
        }
    }

    private func batteryColor(_ pct: Int) -> Color {
        switch pct {
        case 0..<10:  return .red
        case 10..<25: return .orange
        case 25..<50: return .yellow
        default:      return .green
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return h > 0 ? "\(h)h\(m)m" : "\(m)m"
    }
}

private struct Pill: View {
    let text: String
    let color: Color
    init(_ text: String, color: Color) { self.text = text; self.color = color }
    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(color.opacity(0.18))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}
