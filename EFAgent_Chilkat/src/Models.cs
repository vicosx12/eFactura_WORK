using System;
using Newtonsoft.Json;

namespace EFAgent
{
    /// <summary>
    /// Context comun pentru toate operațiile
    /// </summary>
    public class CommandContext
    {
        public string Database { get; set; } = "";
        public string TableName { get; set; } = "";
        public string InvoiceId { get; set; } = "";
        public string ConnectionString { get; set; } = "";
        public string Environment { get; set; } = "prod";
        public string LogLevel { get; set; } = "INFO";
        public bool OutputJson { get; set; } = true;
        public string? IdDescarcare { get; set; }
    }

    /// <summary>
    /// Rezultat operație standardizat
    /// </summary>
    public class OperationResult
    {
        [JsonProperty("ok")]
        public bool IsSuccess { get; set; }

        [JsonProperty("step")]
        public string Step { get; set; } = "";

        [JsonProperty("http_status")]
        public int? HttpStatus { get; set; }

        [JsonProperty("anaf_status")]
        public string? AnafStatus { get; set; }

        [JsonProperty("id_solicitare")]
        public string? IdSolicitare { get; set; }

        [JsonProperty("id_descarcare")]
        public string? IdDescarcare { get; set; }

        [JsonProperty("recipisa")]
        public string? Recipisa { get; set; }

        [JsonProperty("message")]
        public string Message { get; set; } = "";

        [JsonProperty("zip_base64")]
        public string? ZipBase64 { get; set; }

        [JsonProperty("details")]
        public object? Details { get; set; }

        public static OperationResult Success(string step, string message)
        {
            return new OperationResult
            {
                IsSuccess = true,
                Step = step,
                Message = message
            };
        }

        public static OperationResult Error(string step, string message, int? httpStatus = null)
        {
            return new OperationResult
            {
                IsSuccess = false,
                Step = step,
                Message = message,
                HttpStatus = httpStatus
            };
        }
    }

    /// <summary>
    /// Date factură extrase din baza de date
    /// </summary>
    public class InvoiceData
    {
        public string Nir { get; set; } = "";
        public string? BT_11 { get; set; }  // Număr factură
        public string? BT_13 { get; set; }  // Data emitere
        public DateTime? DataDoc { get; set; }
        
        // Date suplimentare din tabele
        public string? SellerCIF { get; set; }
        public string? SellerName { get; set; }
        public string? BuyerCIF { get; set; }
        public string? BuyerName { get; set; }
        public decimal? TotalAmount { get; set; }
        public string? Currency { get; set; }
    }

    /// <summary>
    /// Configurare OAuth2
    /// </summary>
    public class OAuth2Config
    {
        public string ClientId { get; set; } = "";
        public string ClientSecret { get; set; } = "";
        public string TokenUrl { get; set; } = "";
        public string TokenStore { get; set; } = "";
        public int RefreshBeforeExpiry { get; set; } = 300; // 5 minute
    }

    /// <summary>
    /// Setări aplicație
    /// </summary>
    public class AppSettings
    {
        public OAuth2Config OAuth2 { get; set; } = new OAuth2Config();
        public EndpointsConfig Endpoints { get; set; } = new EndpointsConfig();
        public string XsdSchemaPath { get; set; } = "";
        public int MaxRetries { get; set; } = 3;
        public int RetryDelaySeconds { get; set; } = 30;
    }

    /// <summary>
    /// Configurare endpoint-uri ANAF
    /// </summary>
    public class EndpointsConfig
    {
        public string Prod { get; set; } = "https://api.anaf.ro/prod/FCTEL/rest/";
        public string Test { get; set; } = "https://api.anaf.ro/test/FCTEL/rest/";
        public string OAuth2Prod { get; set; } = "https://logincert.anaf.ro/anaf-oauth2/v1/token";
        public string OAuth2Test { get; set; } = "https://logincert.anaf.ro/anaf-oauth2/v1/token";

        public string GetBaseUrl(string environment)
        {
            return environment.ToLower() == "prod" ? Prod : Test;
        }

        public string GetOAuth2Url(string environment)
        {
            return environment.ToLower() == "prod" ? OAuth2Prod : OAuth2Test;
        }
    }

    /// <summary>
    /// Răspuns OAuth2
    /// </summary>
    public class OAuth2Response
    {
        [JsonProperty("access_token")]
        public string AccessToken { get; set; } = "";

        [JsonProperty("token_type")]
        public string TokenType { get; set; } = "";

        [JsonProperty("expires_in")]
        public int ExpiresIn { get; set; }

        [JsonProperty("refresh_token")]
        public string? RefreshToken { get; set; }

        public DateTime IssuedAt { get; set; } = DateTime.UtcNow;

        public bool IsExpired(int bufferSeconds = 300)
        {
            var expiryTime = IssuedAt.AddSeconds(ExpiresIn - bufferSeconds);
            return DateTime.UtcNow >= expiryTime;
        }
    }

    /// <summary>
    /// Răspuns ANAF Upload
    /// </summary>
    public class AnafUploadResponse
    {
        [JsonProperty("index_incarcare")]
        public string? IndexIncarcare { get; set; }

        [JsonProperty("upload_index")]
        public string? UploadIndex { get; set; }

        [JsonProperty("id_descarcare")]
        public string? IdDescarcare { get; set; }

        [JsonProperty("status")]
        public string? Status { get; set; }

        [JsonProperty("message")]
        public string? Message { get; set; }
    }

    /// <summary>
    /// Răspuns ANAF Status
    /// </summary>
    public class AnafStatusResponse
    {
        [JsonProperty("status")]
        public string? Status { get; set; }

        [JsonProperty("id_descarcare")]
        public string? IdDescarcare { get; set; }

        [JsonProperty("recipisa")]
        public string? Recipisa { get; set; }

        [JsonProperty("message")]
        public string? Message { get; set; }
    }
}
