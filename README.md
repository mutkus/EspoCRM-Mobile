## EspoCRM iOS starter

Swift Package `EspoCRMKit` ile her kullanıcı kendi EspoCRM URL’ine bağlanabilir (ör. `http://crm.mutk.us/espocrm/` veya kendi domain’i). Bearer login veya API key destekler; temel CRUD helper’ları içerir.

### Kullanım (Xcode projesine ekle)
1. Xcode → Package dependency ekleyip bu klasörü ya da Git repo URL’sini gösterin.
2. SwiftUI tarafında tek bir client oluşturun:
```swift
import EspoCRMKit

let config = EspoCRMConfiguration(baseURL: URL(string: "http://crm.mutk.us/espocrm")!)
let client = EspoCRMClient(configuration: config)

@MainActor
func login() async {
    do {
        _ = try await client.login(userName: "admin", password: "secret")
        let accounts: EspoListResponse<EspoRecord> = try await client.list(entity: "Account")
        print(accounts.list.first?.attributes["name"])
    } catch {
        print(error.localizedDescription)
    }
}
```
- API key kullanacaksanız: `EspoCRMConfiguration(baseURL: url, apiKey: "KEY")` verin, `login` çağırmadan devam edin.
- Hızlı prototip için `EspoRecord` dinamik sözlük kullanır; tipli model için kendi `Decodable` struct’ınızı yazın.

### Sağlanan metodlar
- `login(userName:password:)` → `POST /api/v1/App/user/auth`, bearer token saklar.
- `list(entity:parameters:)` → `GET /api/v1/{entity}` (filtre/sıralama için `URLQueryItem` ekleyin).
- `fetch(entity:id:select:)` → `GET /api/v1/{entity}/{id}`.
- `create(entity:body:)` → `POST /api/v1/{entity}`.
- `update(entity:id:body:)` → `PATCH /api/v1/{entity}/{id}`.

### Notlar
- Örnek URL HTTP; App Transport Security için istisna tanımlayın veya HTTPS’e geçin.
- `EspoAuthSession` şu an bellekte; Keychain’de saklayarak oturumu geri yükleyin.
- Çoklu domain desteği için her bağlantı için ayrı `EspoCRMClient` örneği oluşturun.
