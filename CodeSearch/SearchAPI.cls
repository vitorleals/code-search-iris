/// Lightweight HTTP endpoint, without UI, used by `CodeSearch.Page` via fetch().
///
/// The search runs in the background (see `CodeSearch.Engine:StartSearch`), so
/// no request stays open for long - which avoids the Web Gateway timeout
/// (HTTP 504) on long searches. Actions (`action` parameter):
///
///   start  (default)  starts the search with the search parameters and returns {ok, jobId}
///   status            returns the progress of job `id`
///   result            returns the final JSON of the search for job `id`
///   cancel            requests cancellation of job `id`
///
/// Failure responses carry {ok:0, error, errorCode, errorParams}: `error` is
/// English text and `errorCode`/`errorParams` let the page translate it (see
/// `CodeSearch.Messages`).
///
/// It is just another URL inside the same, already configured CSP Web
/// Application (same authentication, no need to enable REST).
Class CodeSearch.SearchAPI Extends %CSP.Page
{

ClassMethod OnPage() As %Status
{
	Set %response.ContentType = "application/json"
	Do %response.SetHeader("Cache-Control", "no-cache")

	Set tAction = $ZConvert(%request.Get("action", "start"), "L")
	Set tId = %request.Get("id", "")

	If (tAction = "status") {
		Write ##class(CodeSearch.Engine).GetStatus(tId)
	} ElseIf (tAction = "result") {
		Write ##class(CodeSearch.Engine).GetResult(tId)
	} ElseIf (tAction = "cancel") {
		Write ##class(CodeSearch.Engine).CancelJob(tId)
	} Else {
		Set tTerm = %request.Get("term", "")
		Set tNamespaces = %request.Get("namespaces", "*")
		Set tExtCls = +%request.Get("extCls", 0)
		Set tExtMac = +%request.Get("extMac", 0)
		Set tExtInt = +%request.Get("extInt", 0)
		Set tExtInc = +%request.Get("extInc", 0)
		Set tExtBas = +%request.Get("extBas", 0)
		Set tExtraMask = %request.Get("extraMask", "")
		Set tWholeWord = +%request.Get("wholeWord", 0)
		Set tCaseSensitive = +%request.Get("caseSensitive", 0)

		Write ##class(CodeSearch.Engine).StartSearch(tTerm, tNamespaces, tExtCls, tExtMac, tExtInt, tExtInc, tExtBas, tExtraMask, tWholeWord, tCaseSensitive)
	}
	Quit $$$OK
}

}
