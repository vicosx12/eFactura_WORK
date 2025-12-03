******************************************************************************************
*  CLASS: IInvoiceRepository
*
*  AUTHOR: Refactored OOP Architecture
*
*  DESCRIPTION:
*     Interfata abstracta pentru Repository pattern.
*     Defineste contractul pentru accesul la datele facturilor.
*
*  DESIGN PATTERN: Repository Pattern (Interface)
*
******************************************************************************************

Define Class IInvoiceRepository As Custom
	
	*-- Numele repository-ului
	cName = "IInvoiceRepository"
	
	*-- Tip de date: Iesiri, Export, Docum
	cDataType = ""
	
	*---------------------------------------------------------------------------
	* Functie: GetById
	* Descriere: Obtine o factura dupa ID
	* Parametri: 
	*   tnId - ID-ul facturii
	* Returneaza: Object - Obiectul factura sau .Null.
	*---------------------------------------------------------------------------
	Function GetById(tnId)
		Error "Metoda abstracta GetById trebuie implementata"
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetByNumber
	* Descriere: Obtine o factura dupa numar
	* Parametri: 
	*   tcNumar - Numarul facturii
	*   tdData - Data facturii (optional)
	* Returneaza: Object - Obiectul factura sau .Null.
	*---------------------------------------------------------------------------
	Function GetByNumber(tcNumar, tdData)
		Error "Metoda abstracta GetByNumber trebuie implementata"
	EndFunc
	
	*---------------------------------------------------------------------------
	* Procedura: Save
	* Descriere: Salveaza o factura
	* Parametri: 
	*   toInvoice - Obiectul factura
	*---------------------------------------------------------------------------
	Procedure Save(toInvoice)
		Error "Metoda abstracta Save trebuie implementata"
	EndProc
	
	*---------------------------------------------------------------------------
	* Procedura: UpdateStatus
	* Descriere: Actualizeaza statusul unei facturi
	* Parametri: 
	*   tnId - ID-ul facturii
	*   tcStatus - Noul status
	*   tcIdSolicitare - ID-ul solicitarii ANAF
	*---------------------------------------------------------------------------
	Procedure UpdateStatus(tnId, tcStatus, tcIdSolicitare)
		Error "Metoda abstracta UpdateStatus trebuie implementata"
	EndProc
	
	*---------------------------------------------------------------------------
	* Functie: GetUnprocessed
	* Descriere: Obtine facturile neprocesate
	* Parametri: 
	*   tdStartDate - Data de inceput
	*   tdEndDate - Data de sfarsit
	* Returneaza: Cursor - Cursor cu facturile
	*---------------------------------------------------------------------------
	Function GetUnprocessed(tdStartDate, tdEndDate)
		Error "Metoda abstracta GetUnprocessed trebuie implementata"
	EndFunc
	
	*---------------------------------------------------------------------------
	* Functie: GetForEFactura
	* Descriere: Obtine datele necesare pentru generarea e-Factura
	* Parametri: 
	*   tnIdUnic - ID-ul unic al facturii
	* Returneaza: Cursor - crsEFactura
	*---------------------------------------------------------------------------
	Function GetForEFactura(tnIdUnic)
		Error "Metoda abstracta GetForEFactura trebuie implementata"
	EndFunc
	
EndDefine
