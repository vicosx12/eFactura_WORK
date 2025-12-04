using System;
using System.IO;
using System.Threading.Tasks;
using System.Text;
using Newtonsoft.Json;

namespace EFAgent
{
    /// <summary>
    /// Upload factură către ANAF folosind Chilkat - VERSIUNE PRODUCȚIE
    /// </summary>
    public class InvoiceUploader
    {
        private readonly AppSettings _settings;
        private readonly string _configPath;

        public InvoiceUploader()
        {
            _configPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "config", "settings.json");
            _settings = LoadSettings();
        }

        private AppSettings LoadSettings()
        {
            if (!File.Exists(_configPath))
            {
                throw new FileNotFoundException($"Fișierul de configurare nu a fost găsit: {_configPath}");
            }

            var json = File.ReadAllText(_configPath);
            return JsonConvert.DeserializeObject<AppSettings>(json) ?? new AppSettings();
        }

        public async Task<OperationResult> UploadAsync(CommandContext context)
        {
            try
            {
                // 1. Obține access token OAuth2
                var token = await GetAccessTokenAsync(context);
                if (string.IsNullOrEmpty(token))
                {
                    return OperationResult.Error("upload", "Nu s-a putut obține token OAuth2");
                }

                // 2. Încarcă XML-ul generat
                var xmlPath = FindGeneratedXml(context);
                if (string.IsNullOrEmpty(xmlPath) || !File.Exists(xmlPath))
                {
                    return OperationResult.Error("upload", "XML-ul nu a fost găsit. Rulează 'generate' mai întâi.");
                }

                var xmlContent = await File.ReadAllTextAsync(xmlPath);

                // 3. Upload către ANAF folosind Chilkat HTTP
                var uploadResponse = await UploadToAnafAsync(context, xmlContent, token);

                if (uploadResponse == null)
                {
                    return OperationResult.Error("upload", "Eroare la comunicarea cu ANAF");
                }

                var result = OperationResult.Success("upload", uploadResponse.Message ?? "Factură transmisă cu succes")
                {
                    HttpStatus = 200,
                    AnafStatus = uploadResponse.Status,
                    IdSolicitare = uploadResponse.UploadIndex ?? uploadResponse.IndexIncarcare,
                    IdDescarcare = uploadResponse.IdDescarcare
                };

                return result;
            }
            catch (Exception ex)
            {
                return OperationResult.Error("upload", $"Excepție: {ex.Message}");
            }
        }

        private string FindGeneratedXml(CommandContext context)
        {
            var outputDir = Path.Combine(Path.GetTempPath(), "EFAgent", "xml");
            if (!Directory.Exists(outputDir))
                return "";

            var files = Directory.GetFiles(outputDir, $"{context.InvoiceId}_*.xml");
            if (files.Length == 0)
                return "";

            // Returnează cel mai recent
            Array.Sort(files);
            return files[^1];
        }

        private async Task<string> GetAccessTokenAsync(CommandContext context)
        {
            try
            {
                // Verifică token existent
                var tokenPath = Path.Combine(_settings.OAuth2.TokenStore, $"token_{context.Environment}.json");
                if (File.Exists(tokenPath))
                {
                    var tokenData = await File.ReadAllTextAsync(tokenPath);
                    var oauth2Response = JsonConvert.DeserializeObject<OAuth2Response>(tokenData);
                    
                    if (oauth2Response != null && !oauth2Response.IsExpired(_settings.OAuth2.RefreshBeforeExpiry))
                    {
                        return oauth2Response.AccessToken;
                    }
                }

                // Obține token nou folosind Chilkat OAuth2
                /* PRODUCȚIE: Uncomment și configurează Chilkat
                var oauth2 = new Chilkat.OAuth2();
                oauth2.TokenEndpoint = _settings.Endpoints.GetOAuth2Url(context.Environment);
                oauth2.ClientId = _settings.OAuth2.ClientId;
                oauth2.ClientSecret = _settings.OAuth2.ClientSecret;
                
                var success = oauth2.UseClientCredentials();
                if (!success)
                {
                    throw new Exception($"OAuth2 failed: {oauth2.LastErrorText}");
                }
                
                var newToken = new OAuth2Response
                {
                    AccessToken = oauth2.AccessToken,
                    TokenType = "Bearer",
                    ExpiresIn = oauth2.ExpireNumSeconds,
                    IssuedAt = DateTime.UtcNow
                };
                
                // Salvează token
                Directory.CreateDirectory(_settings.OAuth2.TokenStore);
                await File.WriteAllTextAsync(tokenPath, JsonConvert.SerializeObject(newToken));
                
                return newToken.AccessToken;
                */

                // Pentru deployment fără Chilkat DLL, folosește fallback
                throw new Exception("Chilkat library nu este disponibilă. Instalează Chilkat DLL și decomentează codul OAuth2.");
            }
            catch (Exception ex)
            {
                throw new Exception($"Eroare obținere token OAuth2: {ex.Message}", ex);
            }
        }

        private async Task<AnafUploadResponse> UploadToAnafAsync(CommandContext context, string xmlContent, string token)
        {
            try
            {
                var baseUrl = _settings.Endpoints.GetBaseUrl(context.Environment);
                var uploadUrl = baseUrl + "upload";

                /* PRODUCȚIE: Uncomment și configurează Chilkat
                var http = new Chilkat.Http();
                http.AuthToken = token;
                http.Accept = "application/json";
                http.ConnectTimeout = 30;
                http.ReadTimeout = 60;
                
                // Construiește request
                var req = new Chilkat.HttpRequest();
                req.HttpVerb = "POST";
                req.Path = "/upload";
                req.ContentType = "application/xml; charset=utf-8";
                req.AddHeader("Accept", "application/json");
                req.LoadBodyFromString(xmlContent, "utf-8");
                
                // Trimite request
                var domain = new Uri(baseUrl).Host;
                var resp = http.SynchronousRequest(domain, 443, true, req);
                
                if (resp == null)
                {
                    throw new Exception($"Upload failed: {http.LastErrorText}");
                }
                
                var responseBody = resp.BodyStr;
                
                if (resp.StatusCode != 200)
                {
                    throw new Exception($"HTTP {resp.StatusCode}: {responseBody}");
                }
                
                return JsonConvert.DeserializeObject<AnafUploadResponse>(responseBody);
                */

                // Pentru deployment fără Chilkat DLL
                await Task.Delay(100); // Simulare delay network
                throw new Exception("Chilkat library nu este disponibilă. Instalează Chilkat DLL și decomentează codul HTTP.");
            }
            catch (Exception ex)
            {
                throw new Exception($"Eroare upload ANAF: {ex.Message}", ex);
            }
        }
    }

    /// <summary>
    /// Verificare status factură la ANAF - VERSIUNE PRODUCȚIE
    /// </summary>
    public class StatusChecker
    {
        private readonly AppSettings _settings;

        public StatusChecker()
        {
            var configPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "config", "settings.json");
            var json = File.ReadAllText(configPath);
            _settings = JsonConvert.DeserializeObject<AppSettings>(json) ?? new AppSettings();
        }

        public async Task<OperationResult> CheckStatusAsync(CommandContext context)
        {
            try
            {
                if (string.IsNullOrEmpty(context.IdDescarcare))
                {
                    return OperationResult.Error("status", "Id_Descarcare lipsește");
                }

                var token = await GetAccessTokenAsync(context);
                if (string.IsNullOrEmpty(token))
                {
                    return OperationResult.Error("status", "Nu s-a putut obține token OAuth2");
                }

                var statusResponse = await CheckStatusAtAnafAsync(context, token);

                var result = OperationResult.Success("status", statusResponse.Message ?? "Status verificat")
                {
                    HttpStatus = 200,
                    AnafStatus = statusResponse.Status,
                    IdDescarcare = statusResponse.IdDescarcare,
                    Recipisa = statusResponse.Recipisa
                };

                return result;
            }
            catch (Exception ex)
            {
                return OperationResult.Error("status", $"Excepție: {ex.Message}");
            }
        }

        private async Task<string> GetAccessTokenAsync(CommandContext context)
        {
            var tokenPath = Path.Combine(_settings.OAuth2.TokenStore, $"token_{context.Environment}.json");
            if (File.Exists(tokenPath))
            {
                var tokenData = await File.ReadAllTextAsync(tokenPath);
                var oauth2Response = JsonConvert.DeserializeObject<OAuth2Response>(tokenData);
                
                if (oauth2Response != null && !oauth2Response.IsExpired(_settings.OAuth2.RefreshBeforeExpiry))
                {
                    return oauth2Response.AccessToken;
                }
            }

            throw new Exception("Token expirat sau inexistent. Rulează 'upload' pentru a obține token nou.");
        }

        private async Task<AnafStatusResponse> CheckStatusAtAnafAsync(CommandContext context, string token)
        {
            try
            {
                var baseUrl = _settings.Endpoints.GetBaseUrl(context.Environment);
                var statusUrl = $"{baseUrl}stareMesaj?id_descarcare={context.IdDescarcare}";

                /* PRODUCȚIE: Uncomment și configurează Chilkat
                var http = new Chilkat.Http();
                http.AuthToken = token;
                http.Accept = "application/json";
                
                var responseBody = http.QuickGetStr(statusUrl);
                
                if (http.LastStatus != 200)
                {
                    throw new Exception($"HTTP {http.LastStatus}: {responseBody}");
                }
                
                return JsonConvert.DeserializeObject<AnafStatusResponse>(responseBody);
                */

                await Task.Delay(100);
                throw new Exception("Chilkat library nu este disponibilă. Instalează Chilkat DLL și decomentează codul HTTP.");
            }
            catch (Exception ex)
            {
                throw new Exception($"Eroare verificare status: {ex.Message}", ex);
            }
        }
    }

    /// <summary>
    /// Descărcare ZIP cu recipisa de la ANAF - VERSIUNE PRODUCȚIE
    /// </summary>
    public class ZipDownloader
    {
        private readonly AppSettings _settings;

        public ZipDownloader()
        {
            var configPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "config", "settings.json");
            var json = File.ReadAllText(configPath);
            _settings = JsonConvert.DeserializeObject<AppSettings>(json) ?? new AppSettings();
        }

        public async Task<OperationResult> DownloadAsync(CommandContext context)
        {
            try
            {
                if (string.IsNullOrEmpty(context.IdDescarcare))
                {
                    return OperationResult.Error("download", "Id_Descarcare lipsește");
                }

                var token = await GetAccessTokenAsync(context);
                if (string.IsNullOrEmpty(token))
                {
                    return OperationResult.Error("download", "Nu s-a putut obține token OAuth2");
                }

                var zipBase64 = await DownloadZipFromAnafAsync(context, token);

                var result = OperationResult.Success("download", "ZIP descărcat cu succes")
                {
                    HttpStatus = 200,
                    ZipBase64 = zipBase64,
                    IdDescarcare = context.IdDescarcare
                };

                return result;
            }
            catch (Exception ex)
            {
                return OperationResult.Error("download", $"Excepție: {ex.Message}");
            }
        }

        private async Task<string> GetAccessTokenAsync(CommandContext context)
        {
            var tokenPath = Path.Combine(_settings.OAuth2.TokenStore, $"token_{context.Environment}.json");
            if (File.Exists(tokenPath))
            {
                var tokenData = await File.ReadAllTextAsync(tokenPath);
                var oauth2Response = JsonConvert.DeserializeObject<OAuth2Response>(tokenData);
                
                if (oauth2Response != null && !oauth2Response.IsExpired(_settings.OAuth2.RefreshBeforeExpiry))
                {
                    return oauth2Response.AccessToken;
                }
            }

            throw new Exception("Token expirat sau inexistent. Rulează 'upload' pentru a obține token nou.");
        }

        private async Task<string> DownloadZipFromAnafAsync(CommandContext context, string token)
        {
            try
            {
                var baseUrl = _settings.Endpoints.GetBaseUrl(context.Environment);
                var downloadUrl = $"{baseUrl}descarcare?id={context.IdDescarcare}";

                /* PRODUCȚIE: Uncomment și configurează Chilkat
                var http = new Chilkat.Http();
                http.AuthToken = token;
                
                var zipData = http.QuickGetBd(downloadUrl);
                
                if (zipData == null)
                {
                    throw new Exception($"Download failed: {http.LastErrorText}");
                }
                
                return zipData.GetEncoded("base64");
                */

                await Task.Delay(100);
                throw new Exception("Chilkat library nu este disponibilă. Instalează Chilkat DLL și decomentează codul HTTP.");
            }
            catch (Exception ex)
            {
                throw new Exception($"Eroare descărcare ZIP: {ex.Message}", ex);
            }
        }
    }
}
