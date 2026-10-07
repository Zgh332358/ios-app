import Foundation

@main
struct ConfigurationTests {
    static func main() throws {
        var assertions = 0
        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            precondition(condition(), message)
            assertions += 1
        }
        func valid(_ value: String) -> Bool { WebAppConfiguration.validatedURL(value) != nil }

        expect(WebAppConfiguration.destination(endpoint: nil, bundledEndpoint: nil) == .unconfigured, "No implicit upstream host")
        expect(WebAppConfiguration.destination(endpoint: " \n", bundledEndpoint: " ") == .unconfigured, "Whitespace is unconfigured")
        let bundle = "https://bundle.example.com/app"
        expect(WebAppConfiguration.destination(endpoint: nil, bundledEndpoint: bundle) == .page(URL(string: bundle)!), "Bundle fallback")
        expect(WebAppConfiguration.destination(endpoint: " \n", bundledEndpoint: bundle) == .page(URL(string: bundle)!), "Blank override uses bundle")
        let saved = "https://own.example.com:8443/app?q=1#usage"
        expect(WebAppConfiguration.destination(endpoint: " \(saved)\n", bundledEndpoint: bundle) == .page(URL(string: saved)!), "Saved URL wins and trims")
        expect(WebAppConfiguration.destination(endpoint: "not a URL", bundledEndpoint: bundle) == .invalid, "Invalid saved URL must not fall back")
        for value in ["https://own.example.com", "http://localhost:8797", "http://127.0.0.1:8797", "http://[::1]:8797"] {
            expect(valid(value), "Expected usable web host: \(value)")
        }
        for value in ["", "relative/path", "//own.example.com", "https:///path", "file:///tmp/index.html", "javascript:alert(1)", "http://own.example.com", "http://localhost.evil.example.com", "https://user:secret@own.example.com", "https://user@own.example.com", "https://own.example.com:0", "https://own.example.com:65536"] {
            expect(!valid(value), "Expected invalid web host: \(value)")
        }
        expect(WebAppConfiguration.origin(of: URL(string: saved)!) == "https://own.example.com:8443", "Bridge origin excludes path/query/fragment")
        let storage = InMemoryStorage()
        // Historical discovery caches must never choose a website or leak old API/model fields.
        storage.set(Data("{\"endpoints\":{\"api\":\"https://historical.invalid\",\"ws\":\"wss://historical.invalid\"}}".utf8), forKey: "endpoint_config")
        let service = ConfigurationService(storage: storage, bundledEndpoint: nil)
        expect(service.getWebDestination() == .unconfigured, "Ignore old DNS cache")
        expect(service.getConfig()["configured"] as? Bool == false, "Bridge unconfigured")
        expect(service.getConfig()["apiEndpoint"] as? String == "", "Bridge never uses old cached origin")
        storage.set(try JSONEncoder().encode(AppSettings(endpoint: saved)), forKey: WebAppConfiguration.settingsKey)
        expect(service.getWebDestination() == .page(URL(string: saved)!), "Read newly saved setting without restarting singleton")
        let bridge = service.getConfig()
        expect(bridge["apiEndpoint"] as? String == "https://own.example.com:8443", "Bridge exposes selected origin")
        expect(bridge["webURL"] as? String == saved, "Web path preserved")
        expect(bridge["wsEndpoint"] == nil && bridge["defaultModel"] == nil && bridge["apiKey"] == nil, "No unsupported native model, websocket or key")
        storage.set(try JSONEncoder().encode(AppSettings(endpoint: nil)), forKey: WebAppConfiguration.settingsKey)
        expect(service.getWebDestination() == .unconfigured, "Clearing URL drops old destination")
        expect(service.getConfig()["apiEndpoint"] as? String == "", "Clearing URL drops old bridge endpoint")
        storage.set(Data("{\"enableDNSSEC\":true,\"dnsServer\":\"Domestic\",\"autoDiscovery\":true,\"endpoint\":\"https://migrated.example.com\"}".utf8), forKey: WebAppConfiguration.settingsKey)
        expect(service.getWebDestination() == .page(URL(string: "https://migrated.example.com")!), "Old settings schema still reads explicit endpoint")
        print("PASS: \(assertions) Foundation configuration assertions")
    }
}
