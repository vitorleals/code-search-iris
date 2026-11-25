/// Message dictionary (i18n) for the CodeSearch UI.
///
/// Each supported language is an XData block named after its language code,
/// holding <m k="key">text</m> entries. Placeholders use the form %name% and
/// are filled in by the client (see CodeSearch.Page:msg).
///
/// To add a language:
///   1. Copy the "en" XData block, rename it to the new code (e.g. "fr") and
///      translate the texts (keep the keys and the %placeholders% intact).
///   2. Add the code to the LANGUAGES parameter and recompile.
///   3. Add its native name to the LANGUAGENAMES parameter.
///
/// English ("en") is the fallback language: any key missing from another
/// language is read from "en".
Class CodeSearch.Messages Extends %RegisteredObject
{

/// Supported language codes (CSV). The first one is the default/fallback.
Parameter LANGUAGES = "en,es,pt";

/// Native display name of each language, in the same order as LANGUAGES.
Parameter LANGUAGENAMES = "English,Español,Português";

/// Returns every language as one JSON object (language code -> messages).
/// The page embeds it so the language can be switched without a round trip.
ClassMethod AllJSON() As %String
{
	Set tAll = {}
	Set tList = $ListFromString(..#LANGUAGES, ",")
	Set tPtr = 0
	While $ListNext(tList, tPtr, tLang) {
		Do tAll.%Set(tLang, ..LoadLanguage(tLang))
	}
	Quit tAll.%ToJSON()
}

/// Reads the XData block of one language into a dynamic object
/// (message key -> text).
ClassMethod LoadLanguage(pLang As %String) As %DynamicObject [ Private ]
{
	Set tObj = {}
	Set tXData = ##class(%Dictionary.CompiledXData).%OpenId($ClassName() _ "||" _ pLang)
	If '$IsObject(tXData) Quit tObj

	// One entry per line: <m k="key">text</m>. The text may use the XML
	// escapes &lt; &gt; &amp;.
	Set tStream = tXData.Data
	Do tStream.Rewind()
	While 'tStream.AtEnd {
		Set tLine = $ZStrip(tStream.ReadLine(), "<>W")
		If ($Extract(tLine, 1, 6) '= "<m k=""") || ($Extract(tLine, *-3, *) '= "</m>") Continue

		Set tKey = $Piece(tLine, """", 2)
		Set tText = $Extract(tLine, $Find(tLine, ">"), *-4)
		Set tText = $Replace($Replace($Replace(tText, "&lt;", "<"), "&gt;", ">"), "&amp;", "&")
		If (tKey '= "") {
			Do tObj.%Set(tKey, tText)
		}
	}
	Quit tObj
}

/// Returns the supported languages as a JSON array of code/name pairs.
ClassMethod LanguagesJSON() As %String
{
	Set tArr = []
	Set tCodes = $ListFromString(..#LANGUAGES, ",")
	Set tNames = $ListFromString(..#LANGUAGENAMES, ",")
	For i = 1:1:$ListLength(tCodes) {
		Do tArr.%Push({"code": ($List(tCodes, i)), "name": ($List(tNames, i))})
	}
	Quit tArr.%ToJSON()
}

XData en
{
<messages>
<m k="tagline">Code search across all namespaces</m>
<m k="termLabel">Text to search</m>
<m k="termPlaceholder">Type at least 3 characters and press Enter</m>
<m k="search">Search</m>
<m k="cancel">Cancel</m>
<m k="clear">Clear</m>
<m k="clearTitle">Clears the text and the results</m>
<m k="wholeWord">Whole word</m>
<m k="matchCase">Match case</m>
<m k="namespaces">Namespaces</m>
<m k="nsFilterPlaceholder">Filter namespaces</m>
<m k="nsSelectAll">Select all</m>
<m k="nsClear">Clear</m>
<m k="extensions">Extensions</m>
<m k="maskLabel">Name mask (optional)</m>
<m k="maskPlaceholder">e.g.: app*.cls,*.mac,my.test.*.mac</m>
<m k="maskHint">If filled in, it replaces the checked extensions.</m>
<m k="language">Language</m>
<m k="nsAll">All namespaces (%total%)</m>
<m k="nsNone">No namespace available</m>
<m k="nsNoneSelected">None selected</m>
<m k="nsNOfM">%n% of %total% selected</m>
<m k="nsCount">%n% of %total%</m>
<m k="errNoNs">Select at least one namespace.</m>
<m k="errNoExtOrMask">Select at least one extension or enter a mask.</m>
<m k="starting">Starting the search...</m>
<m k="startFailed">Could not start the search.</m>
<m k="serverError">Error contacting the server: %detail%</m>
<m k="nonJson">The server response is not JSON (%detail%)</m>
<m k="statusFailed">Failed to query the search progress.</m>
<m k="searchError">Search error.</m>
<m k="cancelling">Cancelling...</m>
<m k="progSearching">Searching</m>
<m k="progCancelling">Cancelling...</m>
<m k="progIn">in %ns%</m>
<m k="progNs">(%done% of %total% namespaces completed)</m>
<m k="progStats">- %items% item(s) checked, %matches% match(es), %secs% s</m>
<m k="progEsc">(Esc to cancel)</m>
<m k="resultSummary">%matches% match(es) in %items% item(s), %namespaces% namespace(s) searched, %secs% s.</m>
<m k="warnCancelled">Search cancelled: showing only the results found so far.</m>
<m k="warnMaxResults">Results truncated: maximum number of matches reached. Refine the search (more specific term, fewer namespaces/extensions).</m>
<m k="warnMaxSeconds">Results truncated: maximum search time reached. Refine the search (more specific term, fewer namespaces/extensions).</m>
<m k="warnNsErrors">No access or errors in namespaces: %names%.</m>
<m k="emptyTitle">No matches found for “%term%”.</m>
<m k="emptyHint">Try a different term, uncheck “Whole word” / “Match case”, or include more extensions and namespaces.</m>
<m k="filterPlaceholder">Filter results...</m>
<m k="expandAll">Expand all</m>
<m k="collapseAll">Collapse all</m>
<m k="copyName">Copy name</m>
<m k="copied">Copied: %text%</m>
<m k="filterCount">%shown% of %total% match(es) shown</m>
<m k="err.minTerm">The search term must be at least %min% characters long.</m>
<m k="err.noExt">Select at least one file extension to search.</m>
<m k="err.startJob">Could not start the background search process.</m>
<m k="err.notFound">Search not found or expired.</m>
<m k="err.stillRunning">The search is still in progress.</m>
<m k="err.stale">The search process stopped responding.</m>
<m k="err.searchFailed">Search failed: %detail%</m>
</messages>
}

XData es
{
<messages>
<m k="tagline">Búsqueda de código en todos los namespaces</m>
<m k="termLabel">Texto a buscar</m>
<m k="termPlaceholder">Escriba al menos 3 caracteres y pulse Enter</m>
<m k="search">Buscar</m>
<m k="cancel">Cancelar</m>
<m k="clear">Limpiar</m>
<m k="clearTitle">Limpia el texto y los resultados</m>
<m k="wholeWord">Palabra completa</m>
<m k="matchCase">Distinguir mayúsc./minúsc.</m>
<m k="namespaces">Namespaces</m>
<m k="nsFilterPlaceholder">Filtrar namespaces</m>
<m k="nsSelectAll">Seleccionar todos</m>
<m k="nsClear">Limpiar</m>
<m k="extensions">Extensiones</m>
<m k="maskLabel">Máscara de nombre (opcional)</m>
<m k="maskPlaceholder">ej.: app*.cls,*.mac,my.test.*.mac</m>
<m k="maskHint">Si se rellena, reemplaza las extensiones marcadas.</m>
<m k="language">Idioma</m>
<m k="nsAll">Todos los namespaces (%total%)</m>
<m k="nsNone">Ningún namespace disponible</m>
<m k="nsNoneSelected">Ninguno seleccionado</m>
<m k="nsNOfM">%n% de %total% seleccionados</m>
<m k="nsCount">%n% de %total%</m>
<m k="errNoNs">Seleccione al menos un namespace.</m>
<m k="errNoExtOrMask">Seleccione al menos una extensión o indique una máscara.</m>
<m k="starting">Iniciando la búsqueda...</m>
<m k="startFailed">No se pudo iniciar la búsqueda.</m>
<m k="serverError">Error al contactar con el servidor: %detail%</m>
<m k="nonJson">La respuesta del servidor no es JSON (%detail%)</m>
<m k="statusFailed">Error al consultar el progreso de la búsqueda.</m>
<m k="searchError">Error en la búsqueda.</m>
<m k="cancelling">Cancelando...</m>
<m k="progSearching">Buscando</m>
<m k="progCancelling">Cancelando...</m>
<m k="progIn">en %ns%</m>
<m k="progNs">(%done% de %total% namespaces completados)</m>
<m k="progStats">- %items% elemento(s) verificado(s), %matches% coincidencia(s), %secs% s</m>
<m k="progEsc">(Esc para cancelar)</m>
<m k="resultSummary">%matches% coincidencia(s) en %items% elemento(s), %namespaces% namespace(s) buscado(s), %secs% s.</m>
<m k="warnCancelled">Búsqueda cancelada: se muestran solo los resultados encontrados hasta el momento.</m>
<m k="warnMaxResults">Resultado truncado: se alcanzó el máximo de coincidencias. Refine la búsqueda (término más específico, menos namespaces/extensiones).</m>
<m k="warnMaxSeconds">Resultado truncado: se alcanzó el tiempo máximo de búsqueda. Refine la búsqueda (término más específico, menos namespaces/extensiones).</m>
<m k="warnNsErrors">Sin acceso o con errores en los namespaces: %names%.</m>
<m k="emptyTitle">No se encontraron coincidencias para “%term%”.</m>
<m k="emptyHint">Pruebe con otro término, desmarque “Palabra completa” / “Distinguir mayúsc./minúsc.” o incluya más extensiones y namespaces.</m>
<m k="filterPlaceholder">Filtrar resultados...</m>
<m k="expandAll">Expandir todo</m>
<m k="collapseAll">Contraer todo</m>
<m k="copyName">Copiar nombre</m>
<m k="copied">Copiado: %text%</m>
<m k="filterCount">%shown% de %total% coincidencia(s) mostrada(s)</m>
<m k="err.minTerm">El término de búsqueda debe tener al menos %min% caracteres.</m>
<m k="err.noExt">Seleccione al menos una extensión de archivo para buscar.</m>
<m k="err.startJob">No se pudo iniciar el proceso de búsqueda en segundo plano.</m>
<m k="err.notFound">Búsqueda no encontrada o expirada.</m>
<m k="err.stillRunning">La búsqueda todavía está en curso.</m>
<m k="err.stale">El proceso de búsqueda dejó de responder.</m>
<m k="err.searchFailed">Falló la búsqueda: %detail%</m>
</messages>
}

XData pt
{
<messages>
<m k="tagline">Pesquisa de código em todos os namespaces</m>
<m k="termLabel">Texto a pesquisar</m>
<m k="termPlaceholder">Digite ao menos 3 caracteres e tecle Enter</m>
<m k="search">Pesquisar</m>
<m k="cancel">Cancelar</m>
<m k="clear">Limpar</m>
<m k="clearTitle">Limpa o texto e os resultados</m>
<m k="wholeWord">Palavra inteira</m>
<m k="matchCase">Diferenciar maiúsc./minúsc.</m>
<m k="namespaces">Namespaces</m>
<m k="nsFilterPlaceholder">Filtrar namespaces</m>
<m k="nsSelectAll">Selecionar todos</m>
<m k="nsClear">Limpar</m>
<m k="extensions">Extensões</m>
<m k="maskLabel">Máscara de nome (opcional)</m>
<m k="maskPlaceholder">ex: app*.cls,*.mac,my.test.*.mac</m>
<m k="maskHint">Se preenchida, substitui as extensões marcadas.</m>
<m k="language">Idioma</m>
<m k="nsAll">Todos os namespaces (%total%)</m>
<m k="nsNone">Nenhum namespace disponível</m>
<m k="nsNoneSelected">Nenhum selecionado</m>
<m k="nsNOfM">%n% de %total% selecionados</m>
<m k="nsCount">%n% de %total%</m>
<m k="errNoNs">Selecione ao menos um namespace.</m>
<m k="errNoExtOrMask">Selecione ao menos uma extensão ou informe uma máscara.</m>
<m k="starting">Iniciando a busca...</m>
<m k="startFailed">Não foi possível iniciar a busca.</m>
<m k="serverError">Erro ao contatar o servidor: %detail%</m>
<m k="nonJson">Resposta do servidor não é JSON (%detail%)</m>
<m k="statusFailed">Falha ao consultar o andamento da busca.</m>
<m k="searchError">Erro na busca.</m>
<m k="cancelling">Cancelando...</m>
<m k="progSearching">Buscando</m>
<m k="progCancelling">Cancelando...</m>
<m k="progIn">em %ns%</m>
<m k="progNs">(%done% de %total% namespaces concluídos)</m>
<m k="progStats">- %items% item(ns) verificado(s), %matches% ocorrência(s), %secs% s</m>
<m k="progEsc">(Esc para cancelar)</m>
<m k="resultSummary">%matches% ocorrência(s) em %items% item(ns), %namespaces% namespace(s) pesquisado(s), %secs% s.</m>
<m k="warnCancelled">Busca cancelada: exibindo apenas os resultados encontrados até o momento.</m>
<m k="warnMaxResults">Resultado truncado: limite máximo de ocorrências atingido. Refine a busca (termo mais específico, menos namespaces/extensões).</m>
<m k="warnMaxSeconds">Resultado truncado: tempo máximo de busca atingido. Refine a busca (termo mais específico, menos namespaces/extensões).</m>
<m k="warnNsErrors">Sem acesso ou erro nos namespaces: %names%.</m>
<m k="emptyTitle">Nenhuma ocorrência encontrada para “%term%”.</m>
<m k="emptyHint">Tente um termo diferente, desmarque “Palavra inteira” / “Diferenciar maiúsc./minúsc.” ou inclua mais extensões e namespaces.</m>
<m k="filterPlaceholder">Filtrar resultados...</m>
<m k="expandAll">Expandir tudo</m>
<m k="collapseAll">Recolher tudo</m>
<m k="copyName">Copiar nome</m>
<m k="copied">Copiado: %text%</m>
<m k="filterCount">%shown% de %total% ocorrência(s) exibida(s)</m>
<m k="err.minTerm">Termo de busca deve ter pelo menos %min% caracteres.</m>
<m k="err.noExt">Selecione ao menos uma extensão de arquivo para pesquisar.</m>
<m k="err.startJob">Não foi possível iniciar o processo de busca em segundo plano.</m>
<m k="err.notFound">Busca não encontrada ou expirada.</m>
<m k="err.stillRunning">A busca ainda está em andamento.</m>
<m k="err.stale">O processo de busca parou de responder.</m>
<m k="err.searchFailed">Falha na busca: %detail%</m>
</messages>
}

}
