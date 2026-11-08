import Foundation

/// 読み込む VRM のファイルを確かめる（VRM か、大きすぎないか、アバターとして使ってよいか）
enum VRMFileInspector {
    /// 会話の画面で落ちないよう、ファイルの大きさに上限を付ける
    static let maxFileSize = 50 * 1024 * 1024

    enum InspectionError: Error, Equatable {
        case tooLarge
        case notVRM
    }

    /// アバターとして使ってよい人
    enum AvatarPermission: Equatable {
        /// 誰でも
        case everyone
        /// 作者か、許可された人だけ
        case limited
        /// 書いていない
        case unknown
    }

    struct Result: Equatable {
        /// VRM 0.x か 1.0
        let version: String
        let title: String?
        let avatarPermission: AvatarPermission
    }

    static func inspect(_ data: Data) throws -> Result {
        guard data.count <= maxFileSize else { throw InspectionError.tooLarge }
        guard let json = glbJSON(data) else { throw InspectionError.notVRM }
        let extensions = json["extensions"] as? [String: Any] ?? [:]

        // VRM 1.0: VRMC_vrm.meta.avatarPermission (onlyAuthor / onlySeparatelyLicensedPerson / everyone)
        if let vrm = extensions["VRMC_vrm"] as? [String: Any] {
            let meta = vrm["meta"] as? [String: Any] ?? [:]
            let permission: AvatarPermission
            switch meta["avatarPermission"] as? String {
            case "everyone": permission = .everyone
            case "onlyAuthor", "onlySeparatelyLicensedPerson": permission = .limited
            default: permission = .unknown
            }
            return Result(version: "1.0", title: meta["name"] as? String, avatarPermission: permission)
        }
        // VRM 0.x: VRM.meta.allowedUserName (OnlyAuthor / ExplicitlyLicensedPerson / Everyone)
        if let vrm = extensions["VRM"] as? [String: Any] {
            let meta = vrm["meta"] as? [String: Any] ?? [:]
            let permission: AvatarPermission
            switch meta["allowedUserName"] as? String {
            case "Everyone": permission = .everyone
            case "OnlyAuthor", "ExplicitlyLicensedPerson": permission = .limited
            default: permission = .unknown
            }
            return Result(version: "0.x", title: meta["title"] as? String, avatarPermission: permission)
        }
        throw InspectionError.notVRM
    }

    /// GLB（glTF のバイナリ）の JSON の部分を読む
    private static func glbJSON(_ data: Data) -> [String: Any]? {
        guard data.count >= 20 else { return nil }
        func uint32(_ offset: Int) -> UInt32 {
            data.subdata(in: offset..<(offset + 4)).withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }.littleEndian
        }
        // "glTF" と、最初のチャンクが "JSON"
        guard uint32(0) == 0x4654_6C67, uint32(16) == 0x4E4F_534A else { return nil }
        let length = Int(uint32(12))
        guard length > 0, 20 + length <= data.count else { return nil }
        return (try? JSONSerialization.jsonObject(with: data.subdata(in: 20..<(20 + length)))) as? [String: Any]
    }
}
