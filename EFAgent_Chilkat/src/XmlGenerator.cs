using System;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Schema;
using System.Xml.Linq;
using System.Text;

namespace EFAgent
{
    /// <summary>
    /// Generator și validator XML UBL pentru RO e-Factura
    /// </summary>
    public class XmlGenerator
    {
        public async Task<OperationResult> GenerateAndValidateAsync(CommandContext context)
        {
            try
            {
                // 1. Extrage date factură din baza de date
                var invoiceData = await FetchInvoiceDataAsync(context);
                if (invoiceData == null)
                {
                    return OperationResult.Error("generate", 
                        $"Factura cu ID {context.InvoiceId} nu a fost găsită");
                }

                // 2. Generează XML UBL
                var xmlPath = GenerateUblXml(invoiceData, context);
                
                // 3. Validează contra XSD
                var validationErrors = ValidateXml(xmlPath);
                
                if (validationErrors.Count > 0)
                {
                    return OperationResult.Error("generate", 
                        $"Validare XSD eșuată: {string.Join("; ", validationErrors)}")
                    {
                        Details = new { errors = validationErrors, xml_path = xmlPath }
                    };
                }

                return OperationResult.Success("generate", "XML generat și validat cu succes")
                {
                    Details = new { xml_path = xmlPath }
                };
            }
            catch (Exception ex)
            {
                return OperationResult.Error("generate", $"Excepție: {ex.Message}");
            }
        }

        private async Task<InvoiceData?> FetchInvoiceDataAsync(CommandContext context)
        {
            // Validate database and table names against whitelist
            var allowedTables = new[] { "Iesiri", "Export" };
            if (!allowedTables.Contains(context.TableName))
            {
                throw new ArgumentException($"Invalid table name: {context.TableName}");
            }

            // Validate database name (basic alphanumeric + underscore check)
            if (!System.Text.RegularExpressions.Regex.IsMatch(context.Database, @"^[a-zA-Z0-9_]+$"))
            {
                throw new ArgumentException($"Invalid database name: {context.Database}");
            }

            using var conn = new SqlConnection(context.ConnectionString);
            await conn.OpenAsync();

            // Use parameterized query with validated identifiers
            var query = $@"
                SELECT 
                    Nir, BT_11, BT_13, DataDoc,
                    -- Adaugă alte câmpuri necesare
                    Furnizor AS SellerName,
                    CIF_Furnizor AS SellerCIF,
                    Client AS BuyerName,
                    CIF_Client AS BuyerCIF,
                    Total AS TotalAmount,
                    Valuta AS Currency
                FROM [{context.Database}].[dbo].[{context.TableName}]
                WHERE Nir = @Nir";

            using var cmd = new SqlCommand(query, conn);
            cmd.Parameters.AddWithValue("@Nir", context.InvoiceId);

            using var reader = await cmd.ExecuteReaderAsync();
            if (!await reader.ReadAsync())
                return null;

            return new InvoiceData
            {
                Nir = reader["Nir"].ToString() ?? "",
                BT_11 = reader["BT_11"]?.ToString(),
                BT_13 = reader["BT_13"]?.ToString(),
                DataDoc = reader["DataDoc"] as DateTime?,
                SellerName = reader["SellerName"]?.ToString(),
                SellerCIF = reader["SellerCIF"]?.ToString(),
                BuyerName = reader["BuyerName"]?.ToString(),
                BuyerCIF = reader["BuyerCIF"]?.ToString(),
                TotalAmount = reader["TotalAmount"] as decimal?,
                Currency = reader["Currency"]?.ToString() ?? "RON"
            };
        }

        private string GenerateUblXml(InvoiceData invoice, CommandContext context)
        {
            // Creează XML UBL 2.1 conform specificațiilor RO e-Factura
            var xml = new XDocument(
                new XDeclaration("1.0", "UTF-8", null),
                new XElement(XName.Get("Invoice", "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"),
                    new XAttribute(XNamespace.Xmlns + "cbc", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"),
                    new XAttribute(XNamespace.Xmlns + "cac", "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"),
                    
                    // CustomizationID (profil RO e-Factura)
                    new XElement(XName.Get("CustomizationID", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"),
                        "urn:cen.eu:en16931:2017#compliant#urn:efactura.mfinante.ro:CIUS-RO:1.0.1"),
                    
                    // ID factură (BT-1)
                    new XElement(XName.Get("ID", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"),
                        invoice.BT_11 ?? invoice.Nir),
                    
                    // Data emitere (BT-2)
                    new XElement(XName.Get("IssueDate", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"),
                        invoice.DataDoc?.ToString("yyyy-MM-dd") ?? DateTime.Now.ToString("yyyy-MM-dd")),
                    
                    // Tip document (380 = Factură comercială)
                    new XElement(XName.Get("InvoiceTypeCode", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"),
                        "380"),
                    
                    // Valută
                    new XElement(XName.Get("DocumentCurrencyCode", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"),
                        invoice.Currency ?? "RON"),
                    
                    // Furnizor (AccountingSupplierParty)
                    new XElement(XName.Get("AccountingSupplierParty", "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"),
                        new XElement(XName.Get("Party", "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"),
                            new XElement(XName.Get("PartyIdentification", "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"),
                                new XElement(XName.Get("ID", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"),
                                    invoice.SellerCIF)),
                            new XElement(XName.Get("PartyName", "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"),
                                new XElement(XName.Get("Name", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"),
                                    invoice.SellerName))
                        )
                    ),
                    
                    // Client (AccountingCustomerParty)
                    new XElement(XName.Get("AccountingCustomerParty", "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"),
                        new XElement(XName.Get("Party", "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"),
                            new XElement(XName.Get("PartyIdentification", "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"),
                                new XElement(XName.Get("ID", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"),
                                    invoice.BuyerCIF)),
                            new XElement(XName.Get("PartyName", "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"),
                                new XElement(XName.Get("Name", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"),
                                    invoice.BuyerName))
                        )
                    ),
                    
                    // Total monetar
                    new XElement(XName.Get("LegalMonetaryTotal", "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"),
                        new XElement(XName.Get("PayableAmount", "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"),
                            new XAttribute("currencyID", invoice.Currency ?? "RON"),
                            invoice.TotalAmount?.ToString("F2") ?? "0.00"))
                    
                    // TODO: Adaugă InvoiceLines, TaxTotal, etc.
                )
            );

            // Salvează XML
            var outputDir = Path.Combine(Path.GetTempPath(), "EFAgent", "xml");
            Directory.CreateDirectory(outputDir);
            var xmlPath = Path.Combine(outputDir, $"{invoice.Nir}_{DateTime.Now:yyyyMMddHHmmss}.xml");
            
            xml.Save(xmlPath);
            return xmlPath;
        }

        private List<string> ValidateXml(string xmlPath)
        {
            var errors = new List<string>();

            try
            {
                // Încarcă schema XSD
                var schemaSet = new XmlSchemaSet();
                
                // TODO: Adaugă calea corectă către UBL-Invoice-2.1.xsd
                var xsdPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "schemas", "UBL-Invoice-2.1.xsd");
                
                if (!File.Exists(xsdPath))
                {
                    errors.Add($"Schema XSD nu a fost găsită: {xsdPath}");
                    return errors;
                }

                schemaSet.Add(null, xsdPath);

                // Validează XML
                var doc = XDocument.Load(xmlPath);
                doc.Validate(schemaSet, (sender, args) =>
                {
                    errors.Add($"{args.Severity}: {args.Message} (Line {args.Exception?.LineNumber})");
                });
            }
            catch (Exception ex)
            {
                errors.Add($"Eroare validare: {ex.Message}");
            }

            return errors;
        }
    }
}
