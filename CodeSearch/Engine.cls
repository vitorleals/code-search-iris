Class CodeSearch.Engine Extends %RegisteredObject
{

/// Maximum number of matches returned by a single search. When it is reached
/// the search is stopped and the result is flagged as truncated.
Parameter MAXRESULTS As %Integer = 500;

/// Maximum time (in seconds) a search may run before it is stopped and
/// flagged as truncated.
Parameter MAXSECONDS As %Integer = 600;

/// Minimum length of the search term, to avoid overly generic searches.
Parameter MINTERMLEN As %Integer = 3;

/// Number of context characters shown before/after the matched term when
/// building the snippet of each match.
Parameter SNIPPETCONTEXTCHARS As %Integer = 80;

/// Returns a JSON array with the names of all namespaces configured on this
/// server, e.g.: ["%SYS","MYAPP","USER"].
///
/// Uses %SYS.Namespace:ListAll (NOT %SYS.Namespace:List, which is a class
/// query, not a ByRef classmethod) to fill an array subscripted by namespace
/// name. Implicit namespaces (subscript in the "system^directory" format)
/// are ignored - only the "regular", explicitly configured namespaces matter.
ClassMethod GetNamespaces() As %String
{
	Set tArr = []
	Try {
		Kill tList
		Set tSC = ##class(%SYS.Namespace).ListAll(.tList)
		If $$$ISOK(tSC) {
			Set tName = $Order(tList(""))
			While (tName '= "") {
				If (tName '[ "^") {
					Do tArr.%Push(tName)
				}
				Set tName = $Order(tList(tName))
			}
		}
	} Catch {
		// If listing fails, return the empty array already built.
	}
	Quit tArr.%ToJSON()
}

/// Builds a failure response: {ok:0, error, errorCode, errorParams}.
///
/// `error` is always English text (a readable fallback for API consumers).
/// `errorCode` and `errorParams` let the UI show the message in the user's
/// language: the page looks up the key "err.<errorCode>" in
/// CodeSearch.Messages and fills in the {placeholders} from `errorParams`.
ClassMethod Fail(pCode As %String, pMessage As %String, pParams As %DynamicObject = "") As %String [ Private ]
{
	Set tResult = {}
	Set tResult.ok = 0
	Set tResult.error = pMessage
	Set tResult.errorCode = pCode
	If $IsObject(pParams) {
		Set tResult.errorParams = pParams
	}
	Quit tResult.%ToJSON()
}

/// Main entry point of the search. Walks the target namespaces, looking for
/// the term `pTerm` in classes/routines whose extension matches the filter
/// built from the checkboxes + free-form mask.
///
/// pNamespaces: "*" (or empty) for all namespaces, or a CSV of specific
/// names (e.g.: "USER,MYAPP").
///
/// pWholeWord: only counts a match when the term appears as a whole word
/// (delimited by non-alphanumeric characters / "_").
/// pCaseSensitive: by default the search ignores case; when on, it requires
/// the same case typed in "Text to search".
///
/// Returns a JSON string:
///   {ok, error, errorCode, errorParams, truncated, truncateReason,
///    totalMatches, itemsScanned, namespacesScanned:[...],
///    namespaceErrors:[{namespace,error}, ...], elapsedMs,
///    rows:[{namespace,item,type,line,snippet}, ...]}
ClassMethod Search(pTerm As %String = "", pNamespaces As %String = "*", pExtCls As %Boolean = 1, pExtMac As %Boolean = 1, pExtInt As %Boolean = 0, pExtInc As %Boolean = 0, pExtBas As %Boolean = 0, pExtraMask As %String = "", pWholeWord As %Boolean = 0, pCaseSensitive As %Boolean = 0) As %String
{
	Set tStart = $ZH
	Set tResult = {}
	Set tTerm = $ZStrip(pTerm, "<>W")

	If ($Length(tTerm) < ..#MINTERMLEN) {
		Quit ..Fail("minTerm", "The search term must be at least " _ ..#MINTERMLEN _ " characters long.", {"min": (..#MINTERMLEN)})
	}

	Set tRawMask = ..SanitizeMask(pExtraMask)
	Set tSpec = ..BuildExtensionSpec(pExtCls, pExtMac, pExtInt, pExtInc, pExtBas, tRawMask)
	If (tSpec = "") {
		Quit ..Fail("noExt", "Select at least one file extension to search.")
	}

	// The namespace list is always revalidated on the server, never blindly
	// trusting what the client sent (it may be stale, or the user may no
	// longer have access to a namespace that was listed earlier).
	Kill tAllNs
	Try {
		Do ##class(%SYS.Namespace).ListAll(.tAllNs)
	} Catch {
	}

	Kill tTargets
	If (pNamespaces = "") || (pNamespaces = "*") {
		Set tName = $Order(tAllNs(""))
		While (tName '= "") {
			If (tName '[ "^") {
				Set tTargets(tName) = ""
			}
			Set tName = $Order(tAllNs(tName))
		}
	} Else {
		Set tList = $ListFromString(pNamespaces, ",")
		Set tPtr = 0
		While $ListNext(tList, tPtr, tOne) {
			Set tOne = $ZStrip(tOne, "<>W")
			If (tOne '= "") && $Data(tAllNs(tOne)) {
				Set tTargets(tOne) = ""
			}
		}
	}

	Set tRows = []
	Set tNamespaceErrors = []
	Set tNamespacesScanned = []
	Set tCount = 0
	Set tItemsScanned = 0
	Set tDeadline = $ZH + ..#MAXSECONDS
	Set tStop = 0
	Set tReason = ""

	// Total number of target namespaces, for the progress bar (only has an
	// effect when the search runs in the background via RunJob).
	Set tNsTotal = 0
	Set tNs = $Order(tTargets(""))
	While (tNs '= "") {
		Set tNsTotal = tNsTotal + 1
		Set tNs = $Order(tTargets(tNs))
	}
	Do ..SetProgress("nsTotal", tNsTotal)
	Set tNsDone = 0

	Set tNs = $Order(tTargets(""))
	While (tNs '= "") && ('tStop) {
		Do ..SetProgress("ns", tNs)
		Try {
			New $Namespace
			Set $Namespace = tNs
			Do ..ScanNamespace(tNs, tSpec, tRawMask, tTerm, .tRows, .tCount, ..#MAXRESULTS, tDeadline, .tItemsScanned, .tStop, .tReason, pWholeWord, pCaseSensitive)
			Do tNamespacesScanned.%Push(tNs)
		} Catch ex {
			Do tNamespaceErrors.%Push({"namespace": (tNs), "error": (ex.DisplayString())})
		}
		Set tNsDone = tNsDone + 1
		Do ..SetProgress("nsDone", tNsDone)
		Set tNs = $Order(tTargets(tNs))
	}

	Set tResult.ok = 1
	Set tResult.truncated = tStop
	Set tResult.truncateReason = tReason
	Set tResult.totalMatches = tCount
	Set tResult.itemsScanned = tItemsScanned
	Set tResult.namespacesScanned = tNamespacesScanned
	Set tResult.namespaceErrors = tNamespaceErrors
	Set tResult.elapsedMs = (($ZH - tStart) * 1000) \ 1
	Set tResult.rows = tRows
	Quit tResult.%ToJSON()
}

/// Time (s) without a sign of life from the search process, after which the
/// job is considered dead and the status becomes "error".
Parameter STALESECONDS As %Integer = 180;

/// Time (s) a finished job is kept before being deleted.
Parameter JOBTTLSECONDS As %Integer = 3600;

/// Starts a background search (Job process) and immediately returns
/// {ok, jobId}. Progress is queried with GetStatus and the final result, in
/// the same format as Search, with GetResult. It exists because a long search
/// inside a single HTTP request is cut off by the Web Gateway timeout
/// (HTTP 504).
///
/// The job state lives in the ^CodeSearchJob global of the namespace where
/// this class is installed (the same one as the Web Application).
ClassMethod StartSearch(pTerm As %String = "", pNamespaces As %String = "*", pExtCls As %Boolean = 1, pExtMac As %Boolean = 1, pExtInt As %Boolean = 0, pExtInc As %Boolean = 0, pExtBas As %Boolean = 0, pExtraMask As %String = "", pWholeWord As %Boolean = 0, pCaseSensitive As %Boolean = 0) As %String
{
	Set tResult = {}
	If ($Length($ZStrip(pTerm, "<>W")) < ..#MINTERMLEN) {
		Quit ..Fail("minTerm", "The search term must be at least " _ ..#MINTERMLEN _ " characters long.", {"min": (..#MINTERMLEN)})
	}

	Do ..PurgeOldJobs()

	Set tHome = ..Home()
	Set tId = $Increment(^|tHome|CodeSearchSeq) _ "-" _ ($Random(900000) + 100000)
	Do ..JobSet(tId, "user", $Username)
	Do ..JobSet(tId, "status", "queued")
	Do ..JobSet(tId, "updated", ..Now())

	Job ##class(CodeSearch.Engine).RunJob(tId, pTerm, pNamespaces, pExtCls, pExtMac, pExtInt, pExtInc, pExtBas, pExtraMask, pWholeWord, pCaseSensitive):($Namespace):5
	If '$Test {
		Kill ^|tHome|CodeSearchJob(tId)
		Quit ..Fail("startJob", "Could not start the background search process.")
	}

	Set tResult.ok = 1
	Set tResult.jobId = tId
	Quit tResult.%ToJSON()
}

/// Body of the background process: runs Search and stores the final JSON (or
/// the error message) in the job state. Must not be called directly - use
/// StartSearch.
ClassMethod RunJob(pId As %String, pTerm As %String, pNamespaces As %String, pExtCls As %Boolean, pExtMac As %Boolean, pExtInt As %Boolean, pExtInc As %Boolean, pExtBas As %Boolean, pExtraMask As %String, pWholeWord As %Boolean, pCaseSensitive As %Boolean)
{
	// Process context (process-private global, which survives the namespace
	// switches done by Search): the job id and the "home" namespace of the state.
	Set ^||CS("job") = pId
	Set ^||CS("home") = $Namespace
	Try {
		Do ..JobSet(pId, "status", "running")
		Do ..JobSet(pId, "updated", ..Now())
		Set tJSON = ..Search(pTerm, pNamespaces, pExtCls, pExtMac, pExtInt, pExtInc, pExtBas, pExtraMask, pWholeWord, pCaseSensitive)
	} Catch ex {
		Set tJSON = ..Fail("searchFailed", "Search failed: " _ ex.DisplayString(), {"detail": (ex.DisplayString())})
	}
	Do ..JobSet(pId, "result", tJSON)
	Do ..JobSet(pId, "updated", ..Now())
	Do ..JobSet(pId, "status", "done")
	Kill ^||CS
}

/// Returns the job progress: {ok, status, nsTotal, nsDone, ns, items,
/// matches}. status: queued | running | done | error.
ClassMethod GetStatus(pId As %String = "") As %String
{
	Set tResult = {}
	If '..OwnsJob(pId) {
		Quit ..Fail("notFound", "Search not found or expired.")
	}

	Set tStatus = ..JobGet(pId, "status")
	If ((tStatus = "queued") || (tStatus = "running")) && ((..Now() - +..JobGet(pId, "updated")) > ..#STALESECONDS) {
		Quit ..Fail("stale", "The search process stopped responding.")
	}

	Set tResult.ok = 1
	Set tResult.status = tStatus
	Set tResult.nsTotal = +..JobGet(pId, "nsTotal")
	Set tResult.nsDone = +..JobGet(pId, "nsDone")
	Set tResult.ns = ..JobGet(pId, "ns")
	Set tResult.items = +..JobGet(pId, "items")
	Set tResult.matches = +..JobGet(pId, "matches")
	Quit tResult.%ToJSON()
}

/// Returns the final JSON of the search (same format as Search) once the job
/// has finished.
ClassMethod GetResult(pId As %String = "") As %String
{
	If '..OwnsJob(pId) {
		Quit ..Fail("notFound", "Search not found or expired.")
	}
	If (..JobGet(pId, "status") '= "done") {
		Quit ..Fail("stillRunning", "The search is still in progress.")
	}
	Quit ..JobGet(pId, "result")
}

/// Requests cancellation of the job. The search process stops at the next
/// item and the partial result stays available in GetResult (truncateReason
/// "cancelled").
ClassMethod CancelJob(pId As %String = "") As %String
{
	If '..OwnsJob(pId) {
		Quit ..Fail("notFound", "Search not found or expired.")
	}
	Do ..JobSet(pId, "cancel", 1)
	Quit {"ok": 1}.%ToJSON()
}

/// Deletes old jobs (finished more than JOBTTLSECONDS ago, or without a sign
/// of life for longer than that), so the state global does not grow without
/// bound.
ClassMethod PurgeOldJobs() [ Private ]
{
	Set tHome = ..Home()
	Set tNow = ..Now()
	Set tId = $Order(^|tHome|CodeSearchJob(""))
	While (tId '= "") {
		Set tNext = $Order(^|tHome|CodeSearchJob(tId))
		If ((tNow - +$Get(^|tHome|CodeSearchJob(tId, "updated"))) > ..#JOBTTLSECONDS) {
			Kill ^|tHome|CodeSearchJob(tId)
		}
		Set tId = tNext
	}
}

/// Namespace where the job state is stored (that of the class/Web
/// Application). Inside the search process it comes from the process-private
/// context, because the scan switches $Namespace.
ClassMethod Home() As %String [ Private ]
{
	Quit $Get(^||CS("home"), $Namespace)
}

/// Seconds since 1840-12-31 (UTC), used as the "sign of life" timestamp.
ClassMethod Now() As %Integer [ Private ]
{
	Set tTS = $ZTimeStamp
	Quit (($Piece(tTS, ",", 1) * 86400) + $Piece(tTS, ",", 2)) \ 1
}

ClassMethod JobSet(pId As %String, pKey As %String, pValue As %String) [ Private ]
{
	Set tHome = ..Home()
	Set ^|tHome|CodeSearchJob(pId, pKey) = pValue
}

ClassMethod JobGet(pId As %String, pKey As %String) As %String [ Private ]
{
	Set tHome = ..Home()
	Quit $Get(^|tHome|CodeSearchJob(pId, pKey))
}

/// The job exists and belongs to the logged-in user.
ClassMethod OwnsJob(pId As %String) As %Boolean [ Private ]
{
	If (pId = "") Quit 0
	Set tHome = ..Home()
	If '$Data(^|tHome|CodeSearchJob(pId)) Quit 0
	Quit (..JobGet(pId, "user") = $Username)
}

/// Publishes a progress value of the current job (no effect outside a job,
/// i.e. when Search is called synchronously).
ClassMethod SetProgress(pKey As %String, pValue As %String) [ Private ]
{
	Set tJob = $Get(^||CS("job"))
	If (tJob = "") Quit
	Do ..JobSet(tJob, pKey, pValue)
	Do ..JobSet(tJob, "updated", ..Now())
}

/// Publishes items checked/matches, at most every ~0.4 s.
ClassMethod Tick(pItems As %Integer, pMatches As %Integer) [ Private ]
{
	Set tJob = $Get(^||CS("job"))
	If (tJob = "") Quit
	Set tNow = $ZH
	If ((tNow - $Get(^||CS("tick"), 0)) < 0.4) Quit
	Set ^||CS("tick") = tNow
	Do ..JobSet(tJob, "items", pItems)
	Do ..JobSet(tJob, "matches", pMatches)
	Do ..JobSet(tJob, "updated", ..Now())
}

/// Did the user request cancellation of the current job?
ClassMethod IsCancelled() As %Boolean [ Private ]
{
	Set tJob = $Get(^||CS("job"))
	If (tJob = "") Quit 0
	Quit +..JobGet(tJob, "cancel")
}

/// Sanitizes the free-form mask typed by the user, keeping only
/// letters/digits/"*"/"."/","/"_" - it is never used in SQL concatenation.
ClassMethod SanitizeMask(pExtraMask As %String = "") As %String [ Private ]
{
	Set tExtra = $ZStrip(pExtraMask, "<>W")
	If (tExtra = "") Quit ""

	Set tAllowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789*.,_"
	Set tClean = ""
	For i=1:1:$Length(tExtra) {
		Set c = $Extract(tExtra, i)
		If $Find(tAllowedChars, c) {
			Set tClean = tClean _ c
		}
	}
	Quit tClean
}

/// Combines the extensions checked via checkbox with the already sanitized
/// free-form mask, producing a spec in the format accepted by
/// %Library.RoutineMgr:StudioOpenDialog (e.g.: "*.cls,*.mac,*.dtl").
///
/// Since StudioOpenDialog treats comma-separated items as OR, a free-form
/// mask could never *restrict* the checked boxes - it could only widen the
/// result (e.g.: ".cls" checked + mask "app*.cls" would become
/// "*.cls,app*.cls", and "*.cls" alone already brings everything). So, when
/// the mask is filled in, it takes full control of the filter and the
/// checkboxes are ignored here.
///
/// The spec returned by this method only serves StudioOpenDialog to
/// enumerate by EXTENSION (e.g.: "*.cls,*.mac") - when there is a mask, the
/// name itself (e.g.: the "app*" in "app*.cls") is checked afterwards, in
/// memory, by ItemMatchesAnyPattern/WildcardMatch, because StudioOpenDialog's
/// name matching is case-sensitive while the rest of the tool (and the
/// user's expectation) is case-insensitive.
ClassMethod BuildExtensionSpec(pExtCls As %Boolean = 0, pExtMac As %Boolean = 0, pExtInt As %Boolean = 0, pExtInc As %Boolean = 0, pExtBas As %Boolean = 0, pRawMask As %String = "") As %String [ Private ]
{
	If (pRawMask '= "") {
		Quit ..BuildEnumerationSpecFromMask(pRawMask)
	}

	Set tParts = ""
	If pExtCls Set tParts = tParts _ ",*.cls"
	If pExtMac Set tParts = tParts _ ",*.mac"
	If pExtInt Set tParts = tParts _ ",*.int"
	If pExtInc Set tParts = tParts _ ",*.inc"
	If pExtBas Set tParts = tParts _ ",*.bas"

	If (tParts = "") Quit ""
	Quit $Extract(tParts, 2, *)
}

/// From an already sanitized mask (e.g.: "app*.cls,*.mac"), builds a "broad"
/// spec with only the extensions (e.g.: "*.cls,*.mac") for StudioOpenDialog
/// to enumerate. A pattern without "." (undefined extension) becomes "*.*",
/// covering any extension for that pattern. The fine filtering by full name
/// is done afterwards, item by item, via ItemMatchesAnyPattern.
ClassMethod BuildEnumerationSpecFromMask(pRawMask As %String = "") As %String [ Private ]
{
	Set tList = $ListFromString(pRawMask, ",")
	Set tPtr = 0
	Kill tSeenExt
	Set tExts = ""
	While $ListNext(tList, tPtr, tPattern) {
		Set tPattern = $ZStrip(tPattern, "<>W")
		If (tPattern = "") Continue

		Set tLastDot = 0
		Set tDotPos = $Find(tPattern, ".")
		While (tDotPos '= 0) {
			Set tLastDot = tDotPos - 1
			Set tDotPos = $Find(tPattern, ".", tDotPos + 1)
		}

		If (tLastDot = 0) {
			Set tExt = "*"
		} Else {
			Set tExt = $Extract(tPattern, tLastDot + 1, *)
			If (tExt = "") Set tExt = "*"
		}

		If '$Data(tSeenExt(tExt)) {
			Set tSeenExt(tExt) = ""
			Set tExts = tExts _ ",*." _ tExt
		}
	}

	If (tExts = "") Quit ""
	Quit $Extract(tExts, 2, *)
}

/// Checks whether `pItemName` (full item name, e.g.: "App.Something.cls")
/// matches any of the comma-separated patterns in `pPatternCsv` (e.g.:
/// "app*.cls,*.mac"), always case-insensitively.
ClassMethod ItemMatchesAnyPattern(pItemName As %String, pPatternCsv As %String) As %Boolean [ Private ]
{
	If (pPatternCsv = "") Quit 1

	Set tList = $ListFromString(pPatternCsv, ",")
	Set tPtr = 0
	Set tMatched = 0
	While $ListNext(tList, tPtr, tPattern) && ('tMatched) {
		Set tPattern = $ZStrip(tPattern, "<>W")
		If (tPattern '= "") && (..WildcardMatch(pItemName, tPattern)) {
			Set tMatched = 1
		}
	}
	Quit tMatched
}

/// Classic wildcard matching (only "*", no "?"), always case-insensitive -
/// used for the item name against the free-form mask.
ClassMethod WildcardMatch(pText As %String, pPattern As %String) As %Boolean [ Private ]
{
	Set tText = $ZConvert(pText, "U")
	Set tPattern = $ZConvert(pPattern, "U")
	Set tTLen = $Length(tText)
	Set tPLen = $Length(tPattern)

	Set tTi = 1, tPi = 1
	Set tStarIdx = 0, tMatchIdx = 0
	Set tFailed = 0
	While (tTi <= tTLen) && ('tFailed) {
		If (tPi <= tPLen) && ($Extract(tPattern, tPi) = "*") {
			Set tStarIdx = tPi
			Set tMatchIdx = tTi
			Set tPi = tPi + 1
		} ElseIf (tPi <= tPLen) && ($Extract(tPattern, tPi) = $Extract(tText, tTi)) {
			Set tTi = tTi + 1
			Set tPi = tPi + 1
		} ElseIf (tStarIdx '= 0) {
			Set tMatchIdx = tMatchIdx + 1
			Set tTi = tMatchIdx
			Set tPi = tStarIdx + 1
		} Else {
			Set tFailed = 1
		}
	}
	If tFailed Quit 0

	While (tPi <= tPLen) && ($Extract(tPattern, tPi) = "*") {
		Set tPi = tPi + 1
	}
	Quit (tPi > tPLen)
}

/// Scans a single namespace (it must already be current in the process, via
/// the NEW $NAMESPACE/SET $NAMESPACE done by the caller): lists the items
/// matching `pSpec` via StudioOpenDialog, filters by name against
/// `pRawMask` (when filled in) and calls ScanItem for each one left.
ClassMethod ScanNamespace(pNamespace As %String, pSpec As %String, pRawMask As %String, pTerm As %String, ByRef pRows As %DynamicArray, ByRef pCount As %Integer, pMax As %Integer, pDeadline As %Integer, ByRef pItemsScanned As %Integer, ByRef pStop As %Boolean, ByRef pReason As %String, pWholeWord As %Boolean = 0, pCaseSensitive As %Boolean = 0) As %Status [ Private ]
{
	Set tStmt = ##class(%SQL.Statement).%New()
	Set tSC = tStmt.%Prepare("SELECT Name FROM %Library.RoutineMgr_StudioOpenDialog(?,1,1,0,1,0,0)")
	If $$$ISERR(tSC) Quit tSC

	Set tRS = tStmt.%Execute(pSpec)
	If (tRS.%SQLCODE < 0) {
		Quit $$$ERROR($$$GeneralError, "Failed to list items in " _ pNamespace _ ": " _ tRS.%Message)
	}

	While tRS.%Next() {
		If ($ZH > pDeadline) {
			Set pStop = 1
			Set pReason = "maxSeconds"
			Quit
		}
		If ..IsCancelled() {
			Set pStop = 1
			Set pReason = "cancelled"
			Quit
		}
		Set tItem = tRS.%Get("Name")

		If (pRawMask '= "") && ('..ItemMatchesAnyPattern(tItem, pRawMask)) {
			Continue
		}

		Set pItemsScanned = pItemsScanned + 1
		Do ..ScanItem(pNamespace, tItem, pTerm, .pRows, .pCount, pMax, .pStop, pWholeWord, pCaseSensitive)
		Do ..Tick(pItemsScanned, pCount)
		If pStop {
			Set pReason = "maxResults"
			Quit
		}
	}
	Quit $$$OK
}

/// Opens the source of a single item (class or routine) and scans it line by
/// line looking for `pTerm`. Each match becomes a row in pRows. Errors when
/// opening an individual item (e.g.: item removed between listing and
/// opening) are silently ignored, without interrupting the namespace scan.
ClassMethod ScanItem(pNamespace As %String, pItem As %String, pTerm As %String, ByRef pRows As %DynamicArray, ByRef pCount As %Integer, pMax As %Integer, ByRef pStop As %Boolean, pWholeWord As %Boolean = 0, pCaseSensitive As %Boolean = 0) As %Status [ Private ]
{
	Set tType = $ZConvert($Piece(pItem, ".", *), "L")

	Try {
		If (tType = "cls") {
			Do ..ScanClassItem(pNamespace, pItem, pTerm, tType, .pRows, .pCount, pMax, .pStop, pWholeWord, pCaseSensitive)
		} Else {
			Do ..ScanRoutineItem(pNamespace, pItem, pTerm, tType, .pRows, .pCount, pMax, .pStop, pWholeWord, pCaseSensitive)
		}
	} Catch {
		// the item could not be opened/read - ignore it and move on to the next one
	}
	Quit $$$OK
}

/// Routines (.mac/.int/.inc/.bas): %Routine is itself a character stream -
/// it can be read line by line directly via %OpenId, without touching the
/// file system.
ClassMethod ScanRoutineItem(pNamespace As %String, pItem As %String, pTerm As %String, pType As %String, ByRef pRows As %DynamicArray, ByRef pCount As %Integer, pMax As %Integer, ByRef pStop As %Boolean, pWholeWord As %Boolean = 0, pCaseSensitive As %Boolean = 0) [ Private ]
{
	Set tRtn = ##class(%Routine).%OpenId(pItem)
	If '$IsObject(tRtn) Quit

	Do tRtn.Rewind()
	Set tLine = 0
	While 'tRtn.AtEnd {
		Set tText = tRtn.ReadLine()
		Set tLine = tLine + 1
		If (..FindMatchEnd(tText, pTerm, pCaseSensitive, pWholeWord) > 0) {
			Do ..AddRow(pNamespace, pItem, pType, tLine, tText, pTerm, .pRows, .pCount, pWholeWord, pCaseSensitive)
			If (pCount >= pMax) {
				Set pStop = 1
				Quit
			}
		}
	}
}

/// Classes (.cls): $system.OBJ.ExportUDL writes the UDL source to a file
/// (there is no overload that returns an in-memory stream), so we export to a
/// temporary file, read it line by line and delete the file afterwards.
ClassMethod ScanClassItem(pNamespace As %String, pItem As %String, pTerm As %String, pType As %String, ByRef pRows As %DynamicArray, ByRef pCount As %Integer, pMax As %Integer, ByRef pStop As %Boolean, pWholeWord As %Boolean = 0, pCaseSensitive As %Boolean = 0) [ Private ]
{
	Set tTempFile = ##class(%File).TempFilename("txt")
	Set tErrLog = ""
	Set tSC = $system.OBJ.ExportUDL(pItem, tTempFile, "", .tErrLog)
	If $$$ISERR(tSC) {
		Do ##class(%File).Delete(tTempFile)
		Quit
	}

	Try {
		Set tFileStream = ##class(%Stream.FileCharacter).%New()
		Set tSC = tFileStream.LinkToFile(tTempFile)
		If $$$ISERR(tSC) Quit

		Set tLine = 0
		While 'tFileStream.AtEnd {
			Set tText = tFileStream.ReadLine()
			Set tLine = tLine + 1
			If (..FindMatchEnd(tText, pTerm, pCaseSensitive, pWholeWord) > 0) {
				Do ..AddRow(pNamespace, pItem, pType, tLine, tText, pTerm, .pRows, .pCount, pWholeWord, pCaseSensitive)
				If (pCount >= pMax) {
					Set pStop = 1
					Quit
				}
			}
		}
	} Catch {
	}

	Do ##class(%File).Delete(tTempFile)
}

/// Builds and adds a result row (one match) to the pRows array.
ClassMethod AddRow(pNamespace As %String, pItem As %String, pType As %String, pLine As %Integer, pText As %String, pTerm As %String, ByRef pRows As %DynamicArray, ByRef pCount As %Integer, pWholeWord As %Boolean = 0, pCaseSensitive As %Boolean = 0) [ Private ]
{
	Set tRow = {}
	Set tRow.namespace = pNamespace
	Set tRow.item = pItem
	Set tRow.type = pType
	Set tRow.line = pLine
	Set tRow.snippet = ..BuildSnippet(pText, pTerm, pWholeWord, pCaseSensitive)
	Do pRows.%Push(tRow)
	Set pCount = pCount + 1
}

/// Trims the matching line around the first occurrence of the term (the same
/// one that satisfies pWholeWord/pCaseSensitive), limiting the context to
/// SNIPPETCONTEXTCHARS characters before/after.
ClassMethod BuildSnippet(pLine As %String, pTerm As %String, pWholeWord As %Boolean = 0, pCaseSensitive As %Boolean = 0) As %String [ Private ]
{
	Set tLine = $ZStrip(pLine, "<>W")
	Set tCtx = ..#SNIPPETCONTEXTCHARS
	Set tPos = ..FindMatchEnd(tLine, pTerm, pCaseSensitive, pWholeWord)
	If (tPos = 0) Quit tLine

	Set tMatchStart = tPos - $Length(pTerm)
	Set tFrom = $Select((tMatchStart - tCtx) < 1: 1, 1: tMatchStart - tCtx)
	Set tTo = tMatchStart + $Length(pTerm) + tCtx

	Set tSnippet = $Extract(tLine, tFrom, tTo)
	If (tFrom > 1) Set tSnippet = "..." _ tSnippet
	If ($Length(tLine) > tTo) Set tSnippet = tSnippet _ "..."
	Quit tSnippet
}

/// Looks for `pNeedle` inside `pHay`, honoring pCaseSensitive/pWholeWord.
/// Returns the position immediately after the end of the match found (same
/// semantics as $Find), or 0 if there is none.
ClassMethod FindMatchEnd(pHay As %String, pNeedle As %String, pCaseSensitive As %Boolean = 0, pWholeWord As %Boolean = 0) As %Integer [ Private ]
{
	Set tHay = $Select(pCaseSensitive: pHay, 1: $ZConvert(pHay, "U"))
	Set tNeedle = $Select(pCaseSensitive: pNeedle, 1: $ZConvert(pNeedle, "U"))
	If (tNeedle = "") Quit 0

	If 'pWholeWord {
		Quit $Find(tHay, tNeedle)
	}

	Set tLen = $Length(tNeedle)
	Set tSearchFrom = 1
	Set tResult = 0
	Set tDone = 0
	While 'tDone {
		Set tEndPos = $Find(tHay, tNeedle, tSearchFrom)
		If (tEndPos = 0) {
			Set tDone = 1
		} Else {
			Set tStartPos = tEndPos - tLen
			Set tBefore = $Select(tStartPos > 1: $Extract(tHay, tStartPos - 1), 1: "")
			Set tAfter = $Extract(tHay, tEndPos)
			If '..IsWordChar(tBefore) && '..IsWordChar(tAfter) {
				Set tResult = tEndPos
				Set tDone = 1
			} Else {
				Set tSearchFrom = tStartPos + 1
			}
		}
	}
	Quit tResult
}

/// A character is a "word character" if it is a letter, digit or "_" - used
/// to check the whole-word boundaries in FindMatchEnd.
ClassMethod IsWordChar(pChar As %String) As %Boolean [ Private ]
{
	If (pChar = "") Quit 0
	Set tUpper = $ZConvert(pChar, "U")
	Quit ($Translate(tUpper, "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_") '= tUpper)
}

}
