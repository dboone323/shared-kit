//
//  QuantumRealityCommunication.swift
//  Quantum Singularity Era - Task 202
//
import Foundation

protocol QRCProtocol {
    associatedtype Channel
    func openChannel() async throws -> Channel
    func send(_ message: QRCMessage, on channel: Channel) async throws -> QRCResult
    func close(_ channel: Channel) async
}

struct QRCChannel: Sendable { let id: UUID; var reliability: Double; var bandwidth: Double }
struct QRCMessage: Sendable { let id: UUID; let payload: Data; let tags: [String]; let createdAt: Date }
struct QRCResult: Sendable { let messageId: UUID; let delivered: Bool; let latency: TimeInterval }

enum QRCError: Error { case channelClosed }

final class QuantumRealityCommunicationEngine: QRCProtocol {
    typealias Channel = QRCChannel
    private var channels: [UUID: QRCChannel] = [:]

    func openChannel() async throws -> QRCChannel {
        let ch = QRCChannel(id: UUID(), reliability: 0.98, bandwidth: 42.0)
        channels[ch.id] = ch
        return ch
    }

    func send(_ message: QRCMessage, on channel: QRCChannel) async throws -> QRCResult {
        guard channels[channel.id] != nil else { throw QRCError.channelClosed }
        let delivered = Bool.random()
        return QRCResult(messageId: message.id, delivered: delivered, latency: Double.random(in: 0.001 ... 0.02))
    }

    func close(_ channel: QRCChannel) async { channels.removeValue(forKey: channel.id) }
}

enum QRCFactory {
    static func engine() -> QuantumRealityCommunicationEngine { QuantumRealityCommunicationEngine() }
    static func message() -> QRCMessage { QRCMessage(id: UUID(), payload: Data([0xAA]), tags: ["sync"], createdAt: Date()) }
}

func demonstrateQuantumRealityCommunication() async {
    let engine = QRCFactory.engine()
    do {
        let channel = try await engine.openChannel()
        let result = try await engine.send(QRCFactory.message(), on: channel)
        await engine.close(channel)
        print("QRC demo -> delivered: \(result.delivered)")
    } catch { print("QRC demo error: \(error)") }
}
