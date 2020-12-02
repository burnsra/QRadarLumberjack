import Foundation
import CocoaAsyncSocket
import CocoaLumberjack

public class QRadarLumberjack: DDAbstractLogger, GCDAsyncSocketDelegate, GCDAsyncUdpSocketDelegate {
    private let host: String?
    private let port: UInt16
    private let mode: String?

    private lazy var tcpSocket: GCDAsyncSocket? = {
        return GCDAsyncSocket(delegate: self, delegateQueue: .main)
    }()

    private lazy var udpSocket: GCDAsyncUdpSocket? = {
        return GCDAsyncUdpSocket(delegate: self, delegateQueue: .main)
    }()

    var dateFormatter: DateFormatter
    var programName: String = ""

    private func checkTcpSocket() {
        guard tcpSocket == nil else { return }

        guard port != 0 else { return }
        guard let host = host else { return }

        tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: .main)

        do {
            try tcpSocket?.connect(toHost: host, onPort: port)
        } catch let e {
            print("[QRadarLumberjack] Error connecting QRadarLumberjack (\(e.localizedDescription))")
        }

    }

    private func checkUdpSocket() {
        guard udpSocket == nil else { return }

        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: .main)
    }

    private func disconnectSocket() {
        tcpSocket?.disconnect()
        tcpSocket = nil

        udpSocket?.close()
        udpSocket = nil
    }

    private func formatMessage(_ logMessage: DDLogMessage) -> String {
        let msg = logMessage.message.trimmingCharacters(in: .newlines)
        let timestamp = dateFormatter.string(from: logMessage.timestamp)
        return "\(timestamp) \(Host.current().localizedName) \(programName) \(msg)"
    }

    @objc(logMessage:)
    public override func log(message logMessage: DDLogMessage) {
        guard port != 0 else { return }
        guard let host = host else { return }

        let msg = formatMessage(logMessage)

        switch (mode) {
            case "tcp":
                checkTcpSocket()
                tcpSocket?.write(msg.data(using: .utf8)!, withTimeout: -1, tag: 1)
            default:
                checkUdpSocket()
                udpSocket?.send(msg.data(using: .utf8)!, toHost: host, port: port, withTimeout: -1, tag: 1)
        }
    }

    public init(host: String, port: Int = 514, mode: String) {
        self.host = host
        self.port = UInt16(port)
        self.mode = mode

        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d HH:mm:ss"

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as! String
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        programName = "\(appName)-\(version)-\(build)"
        super.init()
    }
}
