import Foundation

public final class CodexAppServerClient: @unchecked Sendable {
    public enum ClientError: Error, LocalizedError {
        case codexExecutableNotFound
        case processLaunchFailed(String)
        case processNotRunning
        case malformedResponse
        case serverError(code: Int, message: String)
        case timedOut

        public var errorDescription: String? {
            switch self {
            case .codexExecutableNotFound:
                return "Could not find the codex executable."
            case .processLaunchFailed(let message):
                return "Could not start codex app-server: \(message)"
            case .processNotRunning:
                return "Codex app-server is not running."
            case .malformedResponse:
                return "Codex app-server returned an unsupported response."
            case .serverError(_, let message):
                return message
            case .timedOut:
                return "Codex app-server request timed out."
            }
        }
    }

    private struct RPCRequest<Params: Encodable>: Encodable {
        let jsonrpc = "2.0"
        let id: Int
        let method: String
        let params: Params
    }

    private struct RPCNotification<Params: Encodable>: Encodable {
        let jsonrpc = "2.0"
        let method: String
        let params: Params?
    }

    private struct RPCResponse: Decodable {
        let id: Int?
        let result: JSONValue?
        let error: RPCError?
    }

    private struct RPCError: Decodable {
        let code: Int
        let message: String
    }

    private struct InitializeParams: Encodable {
        let clientInfo: ClientInfo
        let capabilities: Capabilities
    }

    private struct ClientInfo: Encodable {
        let name: String
        let title: String
        let version: String
    }

    private struct Capabilities: Encodable {
        let experimentalApi: Bool
        let optOutNotificationMethods: [String]?
    }

    private struct LoginParams: Encodable {
        let type: String
        let codexStreamlinedLogin: Bool
    }

    public struct LoginResponse: Decodable, Equatable {
        public let type: String
        public let authUrl: String?
        public let loginId: String?
        public let verificationUrl: String?
        public let userCode: String?
    }

    private struct NullParams: Encodable {
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }

    private struct PendingRequest {
        let complete: (Result<Data, Error>) -> Void
    }

    private let queue = DispatchQueue(label: "UsageMenuBar.CodexAppServerClient")
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let executableOverride: String?
    private var process: Process?
    private var inputHandle: FileHandle?
    private var outputBuffer = Data()
    private var nextRequestId = 1
    private var pending: [Int: PendingRequest] = [:]
    private var initialized = false

    public init(executableOverride: String? = nil) {
        self.executableOverride = executableOverride
    }

    public func readRateLimits() async throws -> GetAccountRateLimitsResponse {
        try await ensureInitialized()
        return try await send(method: "account/rateLimits/read", params: NullParams(), as: GetAccountRateLimitsResponse.self)
    }

    public func startChatGPTLogin() async throws -> LoginResponse {
        try await ensureInitialized()
        let params = LoginParams(type: "chatgpt", codexStreamlinedLogin: true)
        return try await send(method: "account/login/start", params: params, as: LoginResponse.self)
    }

    public func stop() {
        queue.sync {
            process?.terminate()
            process = nil
            inputHandle = nil
            outputBuffer.removeAll()
            initialized = false
            let requests = pending
            pending.removeAll()
            requests.values.forEach { $0.complete(.failure(ClientError.processNotRunning)) }
        }
    }

    private func ensureInitialized() async throws {
        let needsInitialization = queue.sync { !initialized }
        guard needsInitialization else {
            return
        }

        try startIfNeeded()
        let params = InitializeParams(
            clientInfo: ClientInfo(name: "UsageMenuBar", title: "UsageMenuBar", version: "0.1.0"),
            capabilities: Capabilities(experimentalApi: true, optOutNotificationMethods: nil)
        )
        _ = try await send(method: "initialize", params: params, as: JSONValue.self)
        try sendNotification(method: "initialized", params: Optional<NullParams>.none)
        queue.sync {
            initialized = true
        }
    }

    private func startIfNeeded() throws {
        try queue.sync {
            if process?.isRunning == true {
                return
            }

            let executable = try findCodexExecutable()
            let process = Process()
            let input = Pipe()
            let output = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = ["app-server", "--listen", "stdio://"]
            process.standardInput = input
            process.standardOutput = output
            process.standardError = output

            output.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                self?.queue.async {
                    self?.handleOutput(data)
                }
            }

            do {
                try process.run()
            } catch {
                throw ClientError.processLaunchFailed(error.localizedDescription)
            }

            self.process = process
            self.inputHandle = input.fileHandleForWriting
        }
    }

    private func send<Response: Decodable, Params: Encodable>(
        method: String,
        params: Params,
        as responseType: Response.Type
    ) async throws -> Response {
        let data = try await sendRaw(method: method, params: params)
        return try decoder.decode(Response.self, from: data)
    }

    private func sendRaw<Params: Encodable>(method: String, params: Params) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                guard self.process?.isRunning == true, let inputHandle = self.inputHandle else {
                    continuation.resume(throwing: ClientError.processNotRunning)
                    return
                }

                let id = self.nextRequestId
                self.nextRequestId += 1
                self.pending[id] = PendingRequest { result in
                    continuation.resume(with: result)
                }

                do {
                    let request = RPCRequest(id: id, method: method, params: params)
                    var data = try self.encoder.encode(request)
                    data.append(0x0A)
                    try inputHandle.write(contentsOf: data)
                } catch {
                    self.pending.removeValue(forKey: id)
                    continuation.resume(throwing: error)
                    return
                }

                self.queue.asyncAfter(deadline: .now() + 12) {
                    guard let pending = self.pending.removeValue(forKey: id) else {
                        return
                    }
                    pending.complete(.failure(ClientError.timedOut))
                }
            }
        }
    }

    private func sendNotification<Params: Encodable>(method: String, params: Params?) throws {
        try queue.sync {
            guard let inputHandle else {
                throw ClientError.processNotRunning
            }

            let notification = RPCNotification(method: method, params: params)
            var data = try encoder.encode(notification)
            data.append(0x0A)
            try inputHandle.write(contentsOf: data)
        }
    }

    private func handleOutput(_ data: Data) {
        outputBuffer.append(data)

        while let newlineIndex = outputBuffer.firstIndex(of: 0x0A) {
            let line = outputBuffer[..<newlineIndex]
            outputBuffer.removeSubrange(...newlineIndex)
            handleLine(Data(line))
        }
    }

    private func handleLine(_ data: Data) {
        guard !data.isEmpty else {
            return
        }

        guard let response = try? decoder.decode(RPCResponse.self, from: data), let id = response.id else {
            return
        }

        guard let pending = pending.removeValue(forKey: id) else {
            return
        }

        if let error = response.error {
            pending.complete(.failure(ClientError.serverError(code: error.code, message: error.message)))
            return
        }

        guard let result = response.result else {
            pending.complete(.failure(ClientError.malformedResponse))
            return
        }

        do {
            let data = try encoder.encode(result)
            pending.complete(.success(data))
        } catch {
            pending.complete(.failure(error))
        }
    }

    private func findCodexExecutable() throws -> String {
        if let executableOverride {
            return executableOverride
        }

        if let envPath = ProcessInfo.processInfo.environment["CODEX_PATH"], FileManager.default.isExecutableFile(atPath: envPath) {
            return envPath
        }

        let candidates = [
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
            "/usr/bin/codex"
        ]

        if let candidate = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return candidate
        }

        throw ClientError.codexExecutableNotFound
    }
}
