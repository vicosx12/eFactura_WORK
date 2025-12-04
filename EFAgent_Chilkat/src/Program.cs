using System;
using System.CommandLine;
using System.CommandLine.Invocation;
using System.IO;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace EFAgent
{
    /// <summary>
    /// Program principal pentru EFAgent - utilitar Chilkat pentru RO e-Factura
    /// </summary>
    class Program
    {
        static async Task<int> Main(string[] args)
        {
            // Root command
            var rootCommand = new RootCommand("EFAgent - RO e-Factura Automation Utility cu Chilkat")
            {
                CreateGenerateCommand(),
                CreateUploadCommand(),
                CreateStatusCommand(),
                CreateDownloadCommand()
            };

            // Global options
            rootCommand.AddGlobalOption(new Option<string>(
                aliases: new[] { "--log-level", "-l" },
                getDefaultValue: () => "INFO",
                description: "Nivel logging: DEBUG, INFO, WARN, ERROR"));

            rootCommand.AddGlobalOption(new Option<bool>(
                aliases: new[] { "--out-json", "-j" },
                getDefaultValue: () => true,
                description: "Output în format JSON"));

            return await rootCommand.InvokeAsync(args);
        }

        /// <summary>
        /// Comandă: generate - Generare XML UBL și validare
        /// </summary>
        static Command CreateGenerateCommand()
        {
            var command = new Command("generate", "Generează XML UBL din factură și validează contra XSD");
            
            command.AddOption(new Option<string>("--db", "Numele bazei de date") { IsRequired = true });
            command.AddOption(new Option<string>("--table", "Numele tabelei (Iesiri sau Export)") { IsRequired = true });
            command.AddOption(new Option<string>("--id", "ID-ul facturii") { IsRequired = true });
            command.AddOption(new Option<string>("--connString", "Connection string SQL Server") { IsRequired = true });
            command.AddOption(new Option<string>("--env", () => "prod", "Mediu: prod sau test"));

            command.Handler = CommandHandler.Create<string, string, string, string, string, string, bool>(
                async (db, table, id, connString, env, logLevel, outJson) =>
                {
                    var context = new CommandContext
                    {
                        Database = db,
                        TableName = table,
                        InvoiceId = id,
                        ConnectionString = connString,
                        Environment = env,
                        LogLevel = logLevel,
                        OutputJson = outJson
                    };

                    var generator = new XmlGenerator();
                    var result = await generator.GenerateAndValidateAsync(context);
                    
                    OutputResult(result, outJson);
                    return result.IsSuccess ? 0 : 1;
                });

            return command;
        }

        /// <summary>
        /// Comandă: upload - Upload factură către ANAF
        /// </summary>
        static Command CreateUploadCommand()
        {
            var command = new Command("upload", "Transmite factură către ANAF RO e-Factura");
            
            command.AddOption(new Option<string>("--db", "Numele bazei de date") { IsRequired = true });
            command.AddOption(new Option<string>("--table", "Numele tabelei (Iesiri sau Export)") { IsRequired = true });
            command.AddOption(new Option<string>("--id", "ID-ul facturii") { IsRequired = true });
            command.AddOption(new Option<string>("--connString", "Connection string SQL Server") { IsRequired = true });
            command.AddOption(new Option<string>("--env", () => "prod", "Mediu: prod sau test"));

            command.Handler = CommandHandler.Create<string, string, string, string, string, string, bool>(
                async (db, table, id, connString, env, logLevel, outJson) =>
                {
                    var context = new CommandContext
                    {
                        Database = db,
                        TableName = table,
                        InvoiceId = id,
                        ConnectionString = connString,
                        Environment = env,
                        LogLevel = logLevel,
                        OutputJson = outJson
                    };

                    var uploader = new InvoiceUploader();
                    var result = await uploader.UploadAsync(context);
                    
                    OutputResult(result, outJson);
                    return result.IsSuccess ? 0 : 1;
                });

            return command;
        }

        /// <summary>
        /// Comandă: status - Verifică status factură
        /// </summary>
        static Command CreateStatusCommand()
        {
            var command = new Command("status", "Verifică status factură la ANAF");
            
            command.AddOption(new Option<string>("--db", "Numele bazei de date") { IsRequired = true });
            command.AddOption(new Option<string>("--table", "Numele tabelei (Iesiri sau Export)") { IsRequired = true });
            command.AddOption(new Option<string>("--id", "ID-ul facturii") { IsRequired = true });
            command.AddOption(new Option<string>("--id_descarcare", "ID descărcare ANAF") { IsRequired = true });
            command.AddOption(new Option<string>("--env", () => "prod", "Mediu: prod sau test"));

            command.Handler = CommandHandler.Create<string, string, string, string, string, string, bool>(
                async (db, table, id, id_descarcare, env, logLevel, outJson) =>
                {
                    var context = new CommandContext
                    {
                        Database = db,
                        TableName = table,
                        InvoiceId = id,
                        IdDescarcare = id_descarcare,
                        Environment = env,
                        LogLevel = logLevel,
                        OutputJson = outJson
                    };

                    var checker = new StatusChecker();
                    var result = await checker.CheckStatusAsync(context);
                    
                    OutputResult(result, outJson);
                    return result.IsSuccess ? 0 : 1;
                });

            return command;
        }

        /// <summary>
        /// Comandă: download - Descarcă ZIP cu recipisa
        /// </summary>
        static Command CreateDownloadCommand()
        {
            var command = new Command("download", "Descarcă ZIP cu recipisa de la ANAF");
            
            command.AddOption(new Option<string>("--db", "Numele bazei de date") { IsRequired = true });
            command.AddOption(new Option<string>("--table", "Numele tabelei (Iesiri sau Export)") { IsRequired = true });
            command.AddOption(new Option<string>("--id", "ID-ul facturii") { IsRequired = true });
            command.AddOption(new Option<string>("--id_descarcare", "ID descărcare ANAF") { IsRequired = true });
            command.AddOption(new Option<string>("--env", () => "prod", "Mediu: prod sau test"));

            command.Handler = CommandHandler.Create<string, string, string, string, string, string, bool>(
                async (db, table, id, id_descarcare, env, logLevel, outJson) =>
                {
                    var context = new CommandContext
                    {
                        Database = db,
                        TableName = table,
                        InvoiceId = id,
                        IdDescarcare = id_descarcare,
                        Environment = env,
                        LogLevel = logLevel,
                        OutputJson = outJson
                    };

                    var downloader = new ZipDownloader();
                    var result = await downloader.DownloadAsync(context);
                    
                    OutputResult(result, outJson);
                    return result.IsSuccess ? 0 : 1;
                });

            return command;
        }

        /// <summary>
        /// Output rezultat (JSON sau text)
        /// </summary>
        static void OutputResult(OperationResult result, bool outputJson)
        {
            if (outputJson)
            {
                var json = JsonConvert.SerializeObject(result, Formatting.None);
                Console.WriteLine(json);
            }
            else
            {
                Console.WriteLine($"Status: {(result.IsSuccess ? "OK" : "ERROR")}");
                Console.WriteLine($"Message: {result.Message}");
                if (result.HttpStatus.HasValue)
                    Console.WriteLine($"HTTP Status: {result.HttpStatus}");
                if (!string.IsNullOrEmpty(result.AnafStatus))
                    Console.WriteLine($"ANAF Status: {result.AnafStatus}");
            }
        }
    }
}
