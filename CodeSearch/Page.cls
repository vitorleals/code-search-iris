Class CodeSearch.Page Extends %ZEN.Component.page
{

/// Title shown in the browser tab (product name, not translated).
Parameter PAGENAME = "Search IRIS/Caché";

/// The dedicated security layer is on standby for now. The page is protected
/// only by the default authentication of the CSP Web Application. When the
/// dedicated role is resumed, add here:
///   Parameter SECURITYRESOURCE = "%CodeSearch_Search:USE";
/// and create the corresponding Resource/Role.
///
/// Internationalization (i18n): every user-visible text comes from
/// CodeSearch.Messages (en/es/pt). The language is chosen client-side:
/// the user's saved choice, else the browser language, else English. Static
/// markup carries data-i18n* attributes (applied by applyI18n) and dynamic
/// texts go through the t() client method.
XData Style
{
<style type="text/css">
html, body { height: 100%; margin: 0; background: #f5f6f7; }
body, input, button { font-family: -apple-system, "Segoe UI", Arial, Helvetica, sans-serif; }

.muted { color: #777; font-size: 11px; }

/* ---------- Header ---------- */
.header {
	background: #2c3e50;
	color: #fff;
	padding: 12px 20px;
	display: flex;
	align-items: baseline;
	gap: 14px;
}
.header h1 { margin: 0; font-size: 20px; font-weight: 600; }
.header .tagline { font-size: 12px; opacity: 0.75; }
.lang-select {
	margin-left: auto;
	height: 26px;
	padding: 0 6px;
	font-size: 12px;
	color: #fff;
	background: rgba(255,255,255,0.12);
	border: 1px solid rgba(255,255,255,0.35);
	border-radius: 4px;
	cursor: pointer;
}
.lang-select option { color: #333; background: #fff; }
.lang-select:focus { outline: none; box-shadow: 0 0 0 3px rgba(47,128,237,0.4); }

/* ---------- Form ---------- */
.search-form {
	padding: 16px 20px 12px 20px;
	background: #fff;
	border-bottom: 1px solid #dcdfe1;
	font-size: 13px;
}
.field-label, .panel-title {
	display: block;
	font-weight: 600;
	margin-bottom: 5px;
	color: #333;
}
.term-row { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }
.term-input {
	flex: 1 1 380px;
	max-width: 640px;
	height: 38px;
	box-sizing: border-box;
	padding: 0 12px;
	font-size: 15px;
	border: 1px solid #b8bec3;
	border-radius: 4px;
}
.term-input:focus, .ns-filter:focus, .mask-input:focus, .result-filter:focus {
	outline: none;
	border-color: #2f80ed;
	box-shadow: 0 0 0 3px rgba(47,128,237,0.2);
}
.term-input.invalid { border-color: #c0392b; box-shadow: 0 0 0 3px rgba(192,57,43,0.15); }

.btn {
	height: 38px;
	padding: 0 18px;
	font-size: 14px;
	border-radius: 4px;
	border: 1px solid #b8bec3;
	background: #fff;
	color: #333;
	cursor: pointer;
}
.btn:hover { background: #f0f2f3; }
.btn:disabled { opacity: 0.55; cursor: not-allowed; }
.btn-primary { background: #2f80ed; border-color: #2f80ed; color: #fff; font-weight: 600; }
.btn-primary:hover { background: #2370d6; }
.btn-primary:disabled:hover { background: #2f80ed; }
.btn-cancel { display: none; border-color: #c0392b; color: #c0392b; }
.btn-link {
	background: none;
	border: none;
	color: #2f80ed;
	cursor: pointer;
	padding: 2px 4px;
	font-size: 12px;
}
.btn-link:hover { text-decoration: underline; }

.form-error { color: #c0392b; font-size: 12px; min-height: 16px; margin: 4px 0 0 2px; }

.chips { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
.chip {
	display: inline-flex;
	align-items: center;
	gap: 5px;
	padding: 4px 10px;
	border: 1px solid #cfd4d8;
	border-radius: 14px;
	background: #fafbfb;
	cursor: pointer;
	user-select: none;
	font-size: 12px;
}
.chip:hover { background: #eef1f3; }
.chip input { margin: 0; }

.form-grid {
	display: flex;
	flex-wrap: wrap;
	gap: 18px;
	margin-top: 14px;
	align-items: flex-start;
}
.panel { min-width: 240px; }
.panel-ns { min-width: 280px; }

/* Namespace dropdown selector (multi-select) */
.ms { position: relative; display: inline-block; }
.ms-toggle {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 10px;
	width: 300px;
	max-width: 100%;
	height: 32px;
	box-sizing: border-box;
	padding: 0 10px;
	font-size: 13px;
	text-align: left;
	background: #fff;
	color: #333;
	border: 1px solid #b8bec3;
	border-radius: 4px;
	cursor: pointer;
}
.ms-toggle:hover { background: #f7f9fa; }
.ms-toggle:focus { outline: none; border-color: #2f80ed; box-shadow: 0 0 0 3px rgba(47,128,237,0.2); }
.ms-toggle.empty { border-color: #c0392b; color: #c0392b; }
.ms-summary { overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
.ms-caret {
	flex: none;
	width: 0;
	height: 0;
	border-left: 5px solid transparent;
	border-right: 5px solid transparent;
	border-top: 6px solid #666;
}
.ms-menu {
	display: none;
	position: absolute;
	top: 100%;
	left: 0;
	z-index: 30;
	width: 320px;
	max-width: 90vw;
	margin-top: 4px;
	padding: 8px;
	box-sizing: border-box;
	background: #fff;
	border: 1px solid #b8bec3;
	border-radius: 4px;
	box-shadow: 0 6px 18px rgba(0,0,0,0.18);
}
.ms-menu .ns-filter { width: 100%; height: 30px; }
.ms-actions { display: flex; align-items: center; gap: 6px; margin: 6px 0 4px 0; }
.ms-actions .muted { margin-left: auto; }
.ns-filter, .mask-input {
	height: 28px;
	box-sizing: border-box;
	padding: 0 8px;
	border: 1px solid #b8bec3;
	border-radius: 4px;
	font-size: 12px;
}
.mask-input { width: 100%; max-width: 300px; height: 32px; font-size: 13px; }
.ns-items {
	max-height: 260px;
	overflow-y: auto;
	border: 1px solid #e6e6e6;
	border-radius: 4px;
	padding: 2px;
}
.ns-item {
	display: flex;
	align-items: center;
	gap: 6px;
	padding: 4px 8px;
	border-radius: 3px;
	cursor: pointer;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}
.ns-item:hover { background: #eef4fe; }
.ns-item input { margin: 0; flex: none; }
.ns-item.hidden { display: none; }

/* ---------- Status / warnings ---------- */
.status-label {
	display: block;
	padding: 8px 20px;
	font-size: 13px;
	color: #444;
	min-height: 18px;
}
.status-label.busy { color: #1f5fbf; }
.status-label.busy:before {
	content: "";
	display: inline-block;
	width: 11px;
	height: 11px;
	margin-right: 8px;
	border: 2px solid #b9d2f7;
	border-top-color: #2f80ed;
	border-radius: 50%;
	vertical-align: -2px;
	animation: cs-spin 0.8s linear infinite;
}
.status-label.error { color: #c0392b; font-weight: 600; }
@keyframes cs-spin { to { transform: rotate(360deg); } }

.progress-wrap {
	display: none;
	height: 4px;
	margin: 0 20px 8px 20px;
	background: #dfe6ee;
	border-radius: 2px;
	overflow: hidden;
}
.progress-bar {
	height: 100%;
	width: 0;
	background: #2f80ed;
	transition: width 0.4s ease;
}

.warning-banner {
	margin: 0 20px 8px 20px;
	padding: 8px 12px;
	background: #fff3cd;
	border: 1px solid #ffe08a;
	color: #7a5b00;
	font-size: 12px;
	border-radius: 4px;
}
.warning-banner + .warning-banner { margin-top: -2px; }

/* ---------- Results ---------- */
.results-toolbar {
	display: flex;
	flex-wrap: wrap;
	align-items: center;
	gap: 8px;
	padding: 4px 20px 8px 20px;
}
.result-filter {
	width: 260px;
	height: 28px;
	box-sizing: border-box;
	padding: 0 8px;
	border: 1px solid #b8bec3;
	border-radius: 4px;
	font-size: 12px;
}
.results-wrap { padding: 0 20px 30px 20px; }

.ns-group {
	background: #fff;
	border: 1px solid #dcdfe1;
	border-radius: 4px;
	margin-bottom: 10px;
}
.ns-group > summary {
	padding: 8px 12px;
	background: #34495e;
	color: #fff;
	border-radius: 3px 3px 0 0;
	cursor: pointer;
	font-size: 13px;
}
.ns-name { font-weight: 600; }
.badge {
	display: inline-block;
	margin-left: 8px;
	padding: 1px 8px;
	border-radius: 10px;
	background: rgba(127,140,150,0.25);
	font-size: 11px;
	font-weight: normal;
}
.ns-group > summary .badge { background: rgba(255,255,255,0.2); }

.item-group { border-top: 1px solid #e6e6e6; }
.item-group > summary {
	padding: 6px 12px;
	cursor: pointer;
	background: #f7f8f9;
	font-size: 12px;
}
.item-group > summary:hover { background: #eef1f3; }
.item-name { font-weight: 600; color: #1f3a5f; }
.copy-btn {
	margin-left: 8px;
	padding: 0 6px;
	font-size: 11px;
	border: 1px solid #cfd4d8;
	border-radius: 3px;
	background: #fff;
	cursor: pointer;
	color: #555;
}
.copy-btn:hover { background: #eef1f3; }

.results-table {
	width: 100%;
	table-layout: fixed;
	border-collapse: collapse;
	font-size: 12px;
}
.results-table col.col-line { width: 64px; }
.results-table td {
	padding: 4px 10px;
	border-top: 1px solid #f0f0f0;
	vertical-align: top;
}
.results-table tr:hover td { background: #f3f8ff; }
.results-table td.line { color: #888; text-align: right; font-family: Consolas, "Courier New", monospace; }
.results-table td.snippet {
	font-family: Consolas, "Courier New", monospace;
	white-space: pre-wrap;
	overflow-wrap: anywhere;
}
.hl { background: #fff176; font-weight: bold; padding: 0 1px; }

.empty-state { text-align: center; color: #555; padding: 40px 20px; font-size: 14px; }
.empty-state p { margin: 6px 0; }

.toast {
	position: fixed;
	bottom: 24px;
	left: 50%;
	transform: translateX(-50%);
	background: #2c3e50;
	color: #fff;
	padding: 8px 16px;
	border-radius: 4px;
	font-size: 13px;
	z-index: 50;
	opacity: 0.95;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page xmlns="http://www.intersystems.com/zen" title="Search IRIS/Caché">
<html id="pageHeader">
<div class="header"><h1>Search IRIS/Caché</h1><span class="tagline" data-i18n="tagline">Code search across all namespaces</span><select id="langSelect" class="lang-select" data-i18n-title="language" title="Language" aria-label="Language" onchange="zenPage.setLanguage(this.value);"></select></div>
</html>

<html id="searchFormHost" OnDrawContent="DrawSearchForm">
</html>

<html id="warningBanner" hidden="true" containerStyle="display: none;">
</html>

<html id="lblStatus" containerStyle="display: block;">
<span class="status-label" id="lblStatusText" role="status" aria-live="polite"></span>
<div class="progress-wrap" id="progressWrap"><div class="progress-bar" id="progressBar"></div></div>
</html>

<html id="resultsHost">
</html>
</page>
}

/// Draws the whole search form, including the namespace checklist (one
/// checkbox per namespace configured on the server, obtained from
/// CodeSearch.Engine.GetNamespaces; all checked by default).
/// It is a single OnDrawContent to keep the flexbox layout under the control
/// of the page CSS, without depending on Zen's automatic layout system.
///
/// Texts are written in English as the fallback and replaced on the client
/// from the data-i18n* attributes (see applyI18n). The message dictionary
/// and the language list are embedded here as JavaScript globals.
ClassMethod DrawSearchForm(pSeed As %String) As %Status
{
	// If the dictionary cannot be loaded (e.g.: CodeSearch.Messages was not
	// compiled), the form is still drawn in its English fallback texts and
	// the cause is logged to the browser console.
	Set tMessages = "{}", tLanguages = "[]", tLoadError = ""
	Try {
		Set tMessages = ##class(CodeSearch.Messages).AllJSON()
		Set tLanguages = ##class(CodeSearch.Messages).LanguagesJSON()
	} Catch ex {
		Set tLoadError = ex.DisplayString()
	}
	Write "<script type=""text/javascript"">"
	Write "var csMessages = ", tMessages, ";"
	Write "var csLanguages = ", tLanguages, ";"
	If (tLoadError '= "") {
		Write "if (window.console) { console.error('CodeSearch i18n: ", $ZConvert(tLoadError, "O", "JS"), "'); }"
	}
	Write "</script>", !

	&html<<div class="search-form">
	<label class="field-label" for="txtTermInput" data-i18n="termLabel">Text to search</label>
	<div class="term-row">
		<input type="text" id="txtTermInput" class="term-input" autocomplete="off" data-i18n-placeholder="termPlaceholder" placeholder="Type at least 3 characters and press Enter" onkeydown="zenPage.onTermKey(event);" oninput="zenPage.clearFormError();"/>
		<button type="button" id="btnSearch" class="btn btn-primary" data-i18n="search" onclick="zenPage.doSearch();">Search</button>
		<button type="button" id="btnCancel" class="btn btn-cancel" data-i18n="cancel" onclick="zenPage.cancelSearch();">Cancel</button>
		<button type="button" id="btnClear" class="btn" data-i18n="clear" data-i18n-title="clearTitle" onclick="zenPage.clearForm();" title="Clears the text and the results">Clear</button>
	</div>
	<div class="chips">
		<label class="chip"><input type="checkbox" id="chkWholeWord"/> <span data-i18n="wholeWord">Whole word</span></label>
		<label class="chip"><input type="checkbox" id="chkCaseSensitive"/> <span data-i18n="matchCase">Match case</span></label>
	</div>
	<div class="form-error" id="formError" role="alert"></div>

	<div class="form-grid">
		<div class="panel panel-ns">
			<span class="panel-title" data-i18n="namespaces">Namespaces</span>
			<div class="ms" id="nsDropdown">
				<button type="button" id="nsToggle" class="ms-toggle" aria-haspopup="true" aria-expanded="false" onclick="zenPage.toggleNsMenu(event);"><span class="ms-summary" id="nsSummary">All namespaces</span><span class="ms-caret"></span></button>
				<div class="ms-menu" id="nsMenu">
					<input type="text" id="nsFilter" class="ns-filter" data-i18n-placeholder="nsFilterPlaceholder" placeholder="Filter namespaces" autocomplete="off" oninput="zenPage.filterNamespaces();"/>
					<div class="ms-actions">
						<button type="button" class="btn-link" data-i18n="nsSelectAll" onclick="zenPage.setAllNamespaces(true);">Select all</button>
						<button type="button" class="btn-link" data-i18n="nsClear" onclick="zenPage.setAllNamespaces(false);">Clear</button>
						<span class="muted" id="nsCount"></span>
					</div>
					<div class="ns-items">>

	Set tJSON = ##class(CodeSearch.Engine).GetNamespaces()
	Set tArr = []
	Try {
		Set tArr = [].%FromJSON(tJSON)
	} Catch {
	}
	Set tIter = tArr.%GetIterator()
	While tIter.%GetNext(.tKey, .tName) {
		Set tEsc = $ZConvert(tName, "O", "HTML")
		&html<<label class="ns-item" data-name="#(tEsc)#"><input type="checkbox" name="nsbox" value="#(tEsc)#" checked="checked" onclick="zenPage.onNsChange();"/> #(tEsc)#</label>>
	}

	&html<</div>
				</div>
			</div>
		</div>

		<div class="panel">
			<span class="panel-title" data-i18n="extensions">Extensions</span>
			<div class="chips" style="margin-top:0">
				<label class="chip"><input type="checkbox" id="chkCls" checked="checked"/> .cls</label>
				<label class="chip"><input type="checkbox" id="chkMac" checked="checked"/> .mac</label>
				<label class="chip"><input type="checkbox" id="chkInt"/> .int</label>
				<label class="chip"><input type="checkbox" id="chkInc"/> .inc</label>
				<label class="chip"><input type="checkbox" id="chkBas"/> .bas</label>
			</div>
		</div>

		<div class="panel">
			<label class="panel-title" for="txtExtraMaskInput" data-i18n="maskLabel">Name mask (optional)</label>
			<input type="text" id="txtExtraMaskInput" class="mask-input" autocomplete="off" data-i18n-placeholder="maskPlaceholder" placeholder="e.g.: app*.cls,*.mac,my.test.*.mac" onkeydown="zenPage.onTermKey(event);"/>
			<div class="muted" data-i18n="maskHint">If filled in, it replaces the checked extensions.</div>
		</div>
	</div>
</div>>

	Quit $$$OK
}

/// [ZenMethod] to reflect namespaces created after the page was already
/// loaded.
ClassMethod RefreshNamespaces() As %String [ ZenMethod ]
{
	Quit ##class(CodeSearch.Engine).GetNamespaces()
}

/// Initialization: sets up the language (i18n), restores the saved
/// preferences, focuses the search field and registers shortcuts (Esc cancels
/// the search; Ctrl+K goes back to the search field).
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.initI18n();
	this.restorePrefs();
	this.updateNsCount();

	var term = document.getElementById('txtTermInput');
	if (term) {
		term.focus();
		term.select();
	}

	var self = this;
	// A click outside the namespace selector closes the menu.
	document.addEventListener('click', function(e) {
		var dd = document.getElementById('nsDropdown');
		if (dd && self.isNsMenuOpen() && !dd.contains(e.target)) {
			self.closeNsMenu();
		}
	});
	document.addEventListener('keydown', function(e) {
		if (e.key === 'Escape') {
			if (self.isNsMenuOpen()) {
				self.closeNsMenu();
				var tg = document.getElementById('nsToggle');
				if (tg) {
					tg.focus();
				}
			} else if (self._search) {
				self.cancelSearch();
			}
		}
		if ((e.ctrlKey || e.metaKey) && (e.key === 'k' || e.key === 'K')) {
			e.preventDefault();
			var t = document.getElementById('txtTermInput');
			if (t) {
				t.focus();
				t.select();
			}
		}
	});
}

/// Returns the codes of the supported languages (from CodeSearch.Messages).
/// The first one is the default/fallback language.
ClientMethod supportedLanguages() [ Language = javascript ]
{
	var codes = [];
	if (typeof csLanguages !== 'undefined') {
		for (var i = 0; i < csLanguages.length; i++) {
			codes.push(csLanguages[i].code);
		}
	}
	if (codes.length === 0) {
		codes.push('en');
	}
	return codes;
}

/// Picks the initial language: the one the user saved, else the first
/// browser language that is supported (e.g.: "es-MX" -> "es"), else the
/// default language (English).
ClientMethod detectLanguage() [ Language = javascript ]
{
	var codes = this.supportedLanguages();
	try {
		var saved = localStorage.getItem('codesearch.lang');
		if (saved && codes.indexOf(saved) !== -1) {
			return saved;
		}
	} catch (e) {
		// localStorage unavailable (private mode etc.) - fall through
	}
	var prefs = (navigator.languages && navigator.languages.length) ? navigator.languages : [navigator.language || ''];
	for (var i = 0; i < prefs.length; i++) {
		var base = String(prefs[i]).toLowerCase().split('-')[0];
		if (codes.indexOf(base) !== -1) {
			return base;
		}
	}
	return codes[0];
}

/// Fills the language selector, picks the language and translates the page.
ClientMethod initI18n() [ Language = javascript ]
{
	this._lang = this.detectLanguage();

	var sel = document.getElementById('langSelect');
	if (sel && (typeof csLanguages !== 'undefined')) {
		sel.innerHTML = '';
		for (var i = 0; i < csLanguages.length; i++) {
			var opt = document.createElement('option');
			opt.value = csLanguages[i].code;
			opt.appendChild(document.createTextNode(csLanguages[i].name));
			sel.appendChild(opt);
		}
		sel.value = this._lang;
	}
	this.applyI18n();
}

/// Switches the language (language selector), remembers the choice and
/// refreshes everything already on screen.
ClientMethod setLanguage(pLang) [ Language = javascript ]
{
	if (this.supportedLanguages().indexOf(pLang) === -1) {
		return;
	}
	this._lang = pLang;
	try {
		localStorage.setItem('codesearch.lang', pLang);
	} catch (e) {
		// localStorage unavailable - the choice just won't persist
	}
	this.applyI18n();
	this.updateNsCount();

	if (this._formErr) {
		this.showFormError(this._formErr.key, this._formErr.markTerm, this._formErr.params);
	}
	// Re-render the last result (status line, warnings and the results
	// themselves) in the new language. A running search refreshes its status
	// on the next poll.
	var last = this._lastRender;
	if (last && !this._search) {
		this.renderResults(last.data, last.term, last.wholeWord, last.caseSensitive);
	}
}

/// Translates the static markup: elements with data-i18n get their text,
/// data-i18n-placeholder their placeholder and data-i18n-title their title
/// (and aria-label, when present).
ClientMethod applyI18n() [ Language = javascript ]
{
	document.documentElement.lang = this._lang;

	// When a key is unknown, msg() returns the key itself: in that case the
	// English text already in the markup is kept.
	var els = document.querySelectorAll('[data-i18n]');
	for (var i = 0; i < els.length; i++) {
		var key = els[i].getAttribute('data-i18n');
		var val = this.msg(key);
		if (val !== key) {
			els[i].textContent = val;
		}
	}
	els = document.querySelectorAll('[data-i18n-placeholder]');
	for (var j = 0; j < els.length; j++) {
		var pkey = els[j].getAttribute('data-i18n-placeholder');
		var pval = this.msg(pkey);
		if (pval !== pkey) {
			els[j].setAttribute('placeholder', pval);
		}
	}
	els = document.querySelectorAll('[data-i18n-title]');
	for (var k = 0; k < els.length; k++) {
		var tkey = els[k].getAttribute('data-i18n-title');
		var txt = this.msg(tkey);
		if (txt === tkey) {
			continue;
		}
		els[k].setAttribute('title', txt);
		if (els[k].hasAttribute('aria-label')) {
			els[k].setAttribute('aria-label', txt);
		}
	}
}

/// Looks up a message in the current language, falling back to English and
/// then to the key itself, and fills in the {placeholders} from pParams.
/// The result is plain text: escape it (esc) before putting it in HTML.
ClientMethod msg(pKey, pParams) [ Language = javascript ]
{
	var all = (typeof csMessages !== 'undefined') ? csMessages : {};
	var text = all[this._lang] ? all[this._lang][pKey] : undefined;
	if (text === undefined || text === null) {
		text = all.en ? all.en[pKey] : undefined;
	}
	if (text === undefined || text === null) {
		return pKey;
	}
	if (pParams) {
		text = String(text).replace(/%(\w+)%/g, function(m, name) {
			return (pParams[name] !== undefined && pParams[name] !== null) ? pParams[name] : m;
		});
	}
	return text;
}

/// Text of a failed server response: the translation of its errorCode
/// ("err.<errorCode>" in CodeSearch.Messages), else the English `error`
/// text sent by the server, else the message pFallbackKey.
ClientMethod serverMsg(pData, pFallbackKey) [ Language = javascript ]
{
	if (pData && pData.errorCode) {
		var key = 'err.' + pData.errorCode;
		var txt = this.msg(key, pData.errorParams);
		if (txt !== key) {
			return txt;
		}
	}
	return (pData && pData.error) ? pData.error : this.msg(pFallbackKey);
}

/// Enter triggers the search from the text fields.
ClientMethod onTermKey(pEvent) [ Language = javascript ]
{
	if (pEvent && (pEvent.key === 'Enter' || pEvent.keyCode === 13)) {
		this.doSearch();
	}
}

/// Triggers the search: validates the form, shows the "Searching..." state
/// with a timer, shows the "Cancel" button and calls the server
/// asynchronously (fetch) against CodeSearch.SearchAPI, so the browser tab is
/// not frozen during the up to Engine::MAXSECONDS seconds the search may take.
ClientMethod doSearch() [ Language = javascript ]
{
	if (this._search) {
		return; // a search is already in progress
	}

	var termEl = document.getElementById('txtTermInput');
	var term = termEl.value.replace(/^\s+|\s+$/g, '');
	var extraMask = document.getElementById('txtExtraMaskInput').value.replace(/^\s+|\s+$/g, '');

	var extCls = document.getElementById('chkCls').checked ? 1 : 0;
	var extMac = document.getElementById('chkMac').checked ? 1 : 0;
	var extInt = document.getElementById('chkInt').checked ? 1 : 0;
	var extInc = document.getElementById('chkInc').checked ? 1 : 0;
	var extBas = document.getElementById('chkBas').checked ? 1 : 0;
	var wholeWord = document.getElementById('chkWholeWord').checked ? 1 : 0;
	var caseSensitive = document.getElementById('chkCaseSensitive').checked ? 1 : 0;

	var nsCsv = this.getSelectedNamespaces();

	var minLen = 3; // keep in sync with CodeSearch.Engine:MINTERMLEN
	if (term.length < minLen) {
		this.showFormError('err.minTerm', true, { min: minLen });
		termEl.focus();
		return;
	}
	if (nsCsv === '') {
		this.showFormError('errNoNs', false);
		return;
	}
	if (extraMask === '' && (extCls + extMac + extInt + extInc + extBas) === 0) {
		this.showFormError('errNoExtOrMask', false);
		return;
	}

	this.clearFormError();
	this.savePrefs();

	document.getElementById('btnSearch').disabled = true;
	document.getElementById('btnCancel').style.display = 'inline-block';
	this.hideWarnings();
	this.setResultsHtml('');
	this._lastRender = null;

	var self = this;
	var search = {
		id: null,
		term: term,
		wholeWord: wholeWord,
		caseSensitive: caseSensitive,
		startedAt: new Date().getTime(),
		cancelRequested: false,
		failures: 0,
		timer: null
	};
	this._search = search;
	this.setStatus(this.msg('starting'), 'busy');

	var qs = 'action=start&term=' + encodeURIComponent(term)
		+ '&namespaces=' + encodeURIComponent(nsCsv)
		+ '&extCls=' + extCls
		+ '&extMac=' + extMac
		+ '&extInt=' + extInt
		+ '&extInc=' + extInc
		+ '&extBas=' + extBas
		+ '&extraMask=' + encodeURIComponent(extraMask)
		+ '&wholeWord=' + wholeWord
		+ '&caseSensitive=' + caseSensitive;

	// The search runs in the background on the server: here we only start the
	// job and then query its progress (pollSearch) in short requests.
	this.apiCall(qs)
		.then(function(data) {
			if (self._search !== search) {
				return;
			}
			if (!data.ok) {
				self.finishSearch(search);
				self.setStatus(self.serverMsg(data, 'startFailed'), 'error');
				return;
			}
			search.id = data.jobId;
			if (search.cancelRequested) {
				self.apiCall('action=cancel&id=' + encodeURIComponent(search.id)).catch(function() {});
			}
			self.pollSearch();
		})
		.catch(function(err) {
			if (self._search !== search) {
				return;
			}
			self.finishSearch(search);
			self.setStatus(self.msg('serverError', { detail: (err && err.message ? err.message : err) }), 'error');
		});
}

/// Calls CodeSearch.SearchAPI and returns a Promise with the JSON response.
ClientMethod apiCall(pQuery) [ Language = javascript ]
{
	var self = this;
	return fetch('CodeSearch.SearchAPI.cls?' + pQuery, { credentials: 'same-origin' })
		.then(function(response) {
			return response.text().then(function(text) {
				if (!response.ok) {
					throw new Error('HTTP ' + response.status + ' - ' + text.substring(0, 200));
				}
				try {
					return JSON.parse(text);
				} catch (e) {
					// The body did not come back as JSON - probably SearchAPI.cls has
					// not been compiled/loaded on the server yet, or the session
					// expired and the server returned an HTML login/error page.
					throw new Error(self.msg('nonJson', { detail: text.substring(0, 200) }));
				}
			});
		});
}

/// Queries the job progress every ~0.7 s, updates the progress bar and, when
/// the server finishes, fetches and shows the result. Tolerates up to 3
/// consecutive network failures before giving up.
ClientMethod pollSearch() [ Language = javascript ]
{
	var search = this._search;
	if (!search) {
		return;
	}
	var self = this;

	this.apiCall('action=status&id=' + encodeURIComponent(search.id))
		.then(function(st) {
			if (self._search !== search) {
				return;
			}
			search.failures = 0;
			if (!st.ok) {
				self.finishSearch(search);
				self.setStatus(self.serverMsg(st, 'statusFailed'), 'error');
				return;
			}
			if (st.status === 'done') {
				return self.apiCall('action=result&id=' + encodeURIComponent(search.id)).then(function(data) {
					if (self._search !== search) {
						return;
					}
					self.finishSearch(search);
					self.renderResults(data, search.term, search.wholeWord, search.caseSensitive);
				});
			}
			self.showProgress(st, search);
			search.timer = setTimeout(function() { self.pollSearch(); }, 700);
		})
		.catch(function(err) {
			if (self._search !== search) {
				return;
			}
			search.failures++;
			if (search.failures < 3) {
				search.timer = setTimeout(function() { self.pollSearch(); }, 1500);
				return;
			}
			self.finishSearch(search);
			self.setStatus(self.msg('serverError', { detail: (err && err.message ? err.message : err) }), 'error');
		});
}

/// Shows the progress: current namespace, how many were already scanned,
/// items checked, matches so far and elapsed time.
ClientMethod showProgress(pStatus, pSearch) [ Language = javascript ]
{
	var secs = Math.floor((new Date().getTime() - pSearch.startedAt) / 1000);
	var parts = [this.msg(pSearch.cancelRequested ? 'progCancelling' : 'progSearching')];
	if (pStatus.ns) {
		parts.push(this.msg('progIn', { ns: pStatus.ns }));
	}
	if (pStatus.nsTotal > 0) {
		parts.push(this.msg('progNs', { done: pStatus.nsDone, total: pStatus.nsTotal }));
	}
	parts.push(this.msg('progStats', { items: pStatus.items, matches: pStatus.matches, secs: secs }));
	if (!pSearch.cancelRequested) {
		parts.push(this.msg('progEsc'));
	}
	this.setStatus(parts.join(' '), 'busy');

	var bar = document.getElementById('progressBar');
	if (bar) {
		var pct = (pStatus.nsTotal > 0) ? Math.round(100 * pStatus.nsDone / pStatus.nsTotal) : 0;
		bar.style.width = pct + '%';
	}
}

/// Ends the "search in progress" state (buttons, timers and progress).
ClientMethod finishSearch(pSearch) [ Language = javascript ]
{
	if (pSearch && pSearch.timer) {
		clearTimeout(pSearch.timer);
	}
	if (this._search === pSearch) {
		this._search = null;
	}
	document.getElementById('btnSearch').disabled = false;
	document.getElementById('btnCancel').style.display = 'none';
	var bar = document.getElementById('progressBar');
	if (bar) {
		bar.style.width = '0';
	}
}

/// Asks the server to cancel the search in progress ("Cancel" button or Esc
/// key). The server stops at the next item and returns the partial result,
/// which is shown normally.
ClientMethod cancelSearch() [ Language = javascript ]
{
	var search = this._search;
	if (!search || search.cancelRequested) {
		return;
	}
	search.cancelRequested = true;
	this.setStatus(this.msg('cancelling'), 'busy');
	if (search.id) {
		this.apiCall('action=cancel&id=' + encodeURIComponent(search.id)).catch(function() {});
	}
}

/// Clears the term, the mask and the results, and returns focus to the search field.
ClientMethod clearForm() [ Language = javascript ]
{
	// Cancels on the server and lets go of the search: the partial result
	// will not be shown.
	var running = this._search;
	if (running) {
		this.cancelSearch();
		this.finishSearch(running);
	}
	document.getElementById('txtTermInput').value = '';
	document.getElementById('txtExtraMaskInput').value = '';
	this.clearFormError();
	this.hideWarnings();
	this.setStatus('', '');
	this.setResultsHtml('');
	this._lastData = null;
	this._lastRender = null;
	document.getElementById('txtTermInput').focus();
}

/// Shows a validation message right below the form (instead of a modal
/// alert()). pKey is a message key (translated now, and again if the
/// language changes). If pMarkTerm, highlights the search field in red.
ClientMethod showFormError(pKey, pMarkTerm, pParams) [ Language = javascript ]
{
	this._formErr = { key: pKey, markTerm: pMarkTerm, params: pParams };
	var el = document.getElementById('formError');
	if (el) {
		el.innerHTML = this.esc(this.msg(pKey, pParams));
	}
	var term = document.getElementById('txtTermInput');
	if (term) {
		if (pMarkTerm) {
			term.className = 'term-input invalid';
		} else {
			term.className = 'term-input';
		}
	}
}

ClientMethod clearFormError() [ Language = javascript ]
{
	this._formErr = null;
	var el = document.getElementById('formError');
	if (el) {
		el.innerHTML = '';
	}
	var term = document.getElementById('txtTermInput');
	if (term) {
		term.className = 'term-input';
	}
}

/// Reads the namespace checkboxes: "*" if all are checked, otherwise the CSV
/// list of the checked ones. Returns "" if none is checked.
ClientMethod getSelectedNamespaces() [ Language = javascript ]
{
	var boxes = document.getElementsByName('nsbox');
	var arr = [];
	for (var i = 0; i < boxes.length; i++) {
		if (boxes[i].checked) {
			arr.push(boxes[i].value);
		}
	}
	if (boxes.length === 0 || arr.length === boxes.length) {
		return '*';
	}
	return arr.join(',');
}

/// Checks/unchecks the namespaces currently visible in the list (respects
/// the typed filter: with an empty filter, that is all of them).
ClientMethod setAllNamespaces(pChecked) [ Language = javascript ]
{
	var boxes = document.getElementsByName('nsbox');
	for (var i = 0; i < boxes.length; i++) {
		if (boxes[i].parentNode.className.indexOf('hidden') === -1) {
			boxes[i].checked = pChecked;
		}
	}
	this.updateNsCount();
}

ClientMethod onNsChange() [ Language = javascript ]
{
	this.updateNsCount();
}

/// Updates the summary shown on the selector button ("All namespaces (29)",
/// the names when up to 2 are checked, or "n of m selected") and the counter
/// inside the menu.
ClientMethod updateNsCount() [ Language = javascript ]
{
	var boxes = document.getElementsByName('nsbox');
	var picked = [];
	for (var i = 0; i < boxes.length; i++) {
		if (boxes[i].checked) {
			picked.push(boxes[i].value);
		}
	}
	var n = picked.length;
	var total = boxes.length;

	var text;
	if (total === 0) {
		text = this.msg('nsNone');
	} else if (n === total) {
		text = this.msg('nsAll', { total: total });
	} else if (n === 0) {
		text = this.msg('nsNoneSelected');
	} else if (n <= 2) {
		text = picked.join(', ');
	} else {
		text = this.msg('nsNOfM', { n: n, total: total });
	}

	var summary = document.getElementById('nsSummary');
	if (summary) {
		summary.innerHTML = this.esc(text);
		summary.title = picked.join(', ');
	}
	var toggle = document.getElementById('nsToggle');
	if (toggle) {
		toggle.className = (n === 0 && total > 0) ? 'ms-toggle empty' : 'ms-toggle';
	}
	var lbl = document.getElementById('nsCount');
	if (lbl) {
		lbl.innerHTML = this.esc(this.msg('nsCount', { n: n, total: total }));
	}
}

/// Opens/closes the namespace selection menu.
ClientMethod toggleNsMenu(pEvent) [ Language = javascript ]
{
	if (pEvent) {
		pEvent.stopPropagation();
	}
	var menu = document.getElementById('nsMenu');
	if (!menu) {
		return;
	}
	if (menu.style.display === 'block') {
		this.closeNsMenu();
		return;
	}
	menu.style.display = 'block';
	document.getElementById('nsToggle').setAttribute('aria-expanded', 'true');
	var f = document.getElementById('nsFilter');
	if (f) {
		f.focus();
		f.select();
	}
}

ClientMethod closeNsMenu() [ Language = javascript ]
{
	var menu = document.getElementById('nsMenu');
	if (menu) {
		menu.style.display = 'none';
	}
	var toggle = document.getElementById('nsToggle');
	if (toggle) {
		toggle.setAttribute('aria-expanded', 'false');
	}
}

ClientMethod isNsMenuOpen() [ Language = javascript ]
{
	var menu = document.getElementById('nsMenu');
	return !!(menu && menu.style.display === 'block');
}

/// Filters the namespace list by the typed text.
ClientMethod filterNamespaces() [ Language = javascript ]
{
	var q = document.getElementById('nsFilter').value.toLowerCase();
	var boxes = document.getElementsByName('nsbox');
	for (var i = 0; i < boxes.length; i++) {
		var label = boxes[i].parentNode;
		var match = (q === '' || boxes[i].value.toLowerCase().indexOf(q) !== -1);
		label.className = match ? 'ns-item' : 'ns-item hidden';
	}
}

/// Saves the form preferences in the browser (localStorage).
ClientMethod savePrefs() [ Language = javascript ]
{
	try {
		var boxes = document.getElementsByName('nsbox');
		var selected = [];
		for (var i = 0; i < boxes.length; i++) {
			if (boxes[i].checked) {
				selected.push(boxes[i].value);
			}
		}
		var prefs = {
			term: document.getElementById('txtTermInput').value,
			mask: document.getElementById('txtExtraMaskInput').value,
			wholeWord: document.getElementById('chkWholeWord').checked,
			caseSensitive: document.getElementById('chkCaseSensitive').checked,
			cls: document.getElementById('chkCls').checked,
			mac: document.getElementById('chkMac').checked,
			int: document.getElementById('chkInt').checked,
			inc: document.getElementById('chkInc').checked,
			bas: document.getElementById('chkBas').checked,
			namespaces: (selected.length === boxes.length) ? null : selected
		};
		localStorage.setItem('codesearch.prefs', JSON.stringify(prefs));
	} catch (e) {
		// localStorage unavailable (private mode etc.) - carry on without persisting
	}
}

/// Restores the preferences saved by savePrefs.
ClientMethod restorePrefs() [ Language = javascript ]
{
	try {
		var raw = localStorage.getItem('codesearch.prefs');
		if (!raw) {
			return;
		}
		var p = JSON.parse(raw);
		document.getElementById('txtTermInput').value = p.term || '';
		document.getElementById('txtExtraMaskInput').value = p.mask || '';
		document.getElementById('chkWholeWord').checked = !!p.wholeWord;
		document.getElementById('chkCaseSensitive').checked = !!p.caseSensitive;
		document.getElementById('chkCls').checked = !!p.cls;
		document.getElementById('chkMac').checked = !!p.mac;
		document.getElementById('chkInt').checked = !!p.int;
		document.getElementById('chkInc').checked = !!p.inc;
		document.getElementById('chkBas').checked = !!p.bas;
		if (p.namespaces && p.namespaces.length) {
			var boxes = document.getElementsByName('nsbox');
			for (var i = 0; i < boxes.length; i++) {
				boxes[i].checked = (p.namespaces.indexOf(boxes[i].value) !== -1);
			}
		}
	} catch (e) {
		// corrupted/unavailable preferences - keep the defaults
	}
}

/// Renders the JSON response of the search: status, warnings (truncation and
/// namespaces with errors) and the results grouped by namespace and item.
ClientMethod renderResults(pData, pTerm, pWholeWord, pCaseSensitive) [ Language = javascript ]
{
	if (!pData.ok) {
		this.setStatus(this.serverMsg(pData, 'searchError'), 'error');
		return;
	}

	this._lastData = pData;
	// Remembered so the results can be re-rendered when the language changes.
	this._lastRender = { data: pData, term: pTerm, wholeWord: pWholeWord, caseSensitive: pCaseSensitive };

	var secs = (pData.elapsedMs / 1000).toFixed(1);
	this.setStatus(this.msg('resultSummary', {
		matches: pData.totalMatches,
		items: pData.itemsScanned,
		namespaces: pData.namespacesScanned.length,
		secs: secs
	}), 'ok');

	var warnings = [];
	if (pData.truncated) {
		if (pData.truncateReason === 'cancelled') {
			warnings.push(this.msg('warnCancelled'));
		} else if (pData.truncateReason === 'maxResults') {
			warnings.push(this.msg('warnMaxResults'));
		} else {
			warnings.push(this.msg('warnMaxSeconds'));
		}
	}
	if (pData.namespaceErrors && pData.namespaceErrors.length > 0) {
		var names = [];
		for (var i = 0; i < pData.namespaceErrors.length; i++) {
			names.push(pData.namespaceErrors[i].namespace);
		}
		warnings.push(this.msg('warnNsErrors', { names: names.join(', ') }));
	}
	this.showWarnings(warnings);

	if (pData.rows.length === 0) {
		this.setResultsHtml(
			'<div class="empty-state"><p><strong>' + this.esc(this.msg('emptyTitle', { term: pTerm })) + '</strong></p>'
			+ '<p class="muted">' + this.esc(this.msg('emptyHint')) + '</p></div>');
		return;
	}

	// Groups by namespace and, within it, by class/routine.
	var groups = {};
	var nsOrder = [];
	for (var r = 0; r < pData.rows.length; r++) {
		var row = pData.rows[r];
		if (!groups[row.namespace]) {
			groups[row.namespace] = { items: {}, order: [], count: 0 };
			nsOrder.push(row.namespace);
		}
		var g = groups[row.namespace];
		g.count++;
		if (!g.items[row.item]) {
			g.items[row.item] = [];
			g.order.push(row.item);
		}
		g.items[row.item].push(row);
	}

	// With many results, items start collapsed to make reading easier.
	var itemOpen = (pData.rows.length <= 150) ? ' open' : '';

	var html = [];
	html.push('<div class="results-toolbar">'
		+ '<input type="text" id="resultFilter" class="result-filter" placeholder="' + this.escAttr(this.msg('filterPlaceholder')) + '" autocomplete="off" oninput="zenPage.filterResults();"/>'
		+ '<button type="button" class="btn-link" onclick="zenPage.toggleGroups(true);">' + this.esc(this.msg('expandAll')) + '</button>'
		+ '<button type="button" class="btn-link" onclick="zenPage.toggleGroups(false);">' + this.esc(this.msg('collapseAll')) + '</button>'
		+ '<span class="muted" id="filterCount"></span></div>');
	html.push('<div class="results-wrap">');

	for (var n = 0; n < nsOrder.length; n++) {
		var ns = nsOrder[n];
		var grp = groups[ns];
		html.push('<details class="ns-group" open><summary><span class="ns-name">' + this.esc(ns) + '</span>'
			+ '<span class="badge" data-total="' + grp.count + '">' + grp.count + '</span></summary>');
		for (var k = 0; k < grp.order.length; k++) {
			var item = grp.order[k];
			var list = grp.items[item];
			html.push('<details class="item-group"' + itemOpen + '><summary><span class="item-name">' + this.esc(item) + '</span>'
				+ '<span class="badge" data-total="' + list.length + '">' + list.length + '</span>'
				+ '<button type="button" class="copy-btn" data-copy="' + this.escAttr(item) + '" onclick="event.preventDefault();event.stopPropagation();zenPage.copyText(this.getAttribute(\'data-copy\'));">' + this.esc(this.msg('copyName')) + '</button></summary>'
				+ '<table class="results-table"><colgroup><col class="col-line"/><col/></colgroup><tbody>');
			for (var j = 0; j < list.length; j++) {
				html.push('<tr data-text="' + this.escAttr(String(list[j].snippet).toLowerCase()) + '"><td class="line">' + list[j].line
					+ '</td><td class="snippet">' + this.highlight(list[j].snippet, pTerm, pWholeWord, pCaseSensitive) + '</td></tr>');
			}
			html.push('</tbody></table></details>');
		}
		html.push('</details>');
	}
	html.push('</div>');
	this.setResultsHtml(html.join(''));
}

/// Writes the results HTML straight into the DOM. It must NOT use
/// setProperty('content'): on a Zen html component that triggers a server
/// round trip (refreshContents) carrying the whole HTML, which fails with
/// <MAXSTRING> when there are many results.
ClientMethod setResultsHtml(pHtml) [ Language = javascript ]
{
	var div = zen('resultsHost').getEnclosingDiv();
	if (div) {
		div.innerHTML = pHtml;
	}
}

/// Filters, on the client, the rows already shown (by code snippet or item
/// name) and updates the counters of each group.
ClientMethod filterResults() [ Language = javascript ]
{
	var q = document.getElementById('resultFilter').value.toLowerCase();
	var nsGroups = document.querySelectorAll('.ns-group');
	var shown = 0;
	var total = 0;

	for (var a = 0; a < nsGroups.length; a++) {
		var nsVisible = 0;
		var itemGroups = nsGroups[a].querySelectorAll('.item-group');
		for (var b = 0; b < itemGroups.length; b++) {
			var ig = itemGroups[b];
			var itemName = ig.querySelector('.item-name').innerText.toLowerCase();
			var nameMatch = (q !== '' && itemName.indexOf(q) !== -1);
			var rows = ig.querySelectorAll('tbody tr');
			var vis = 0;
			for (var c = 0; c < rows.length; c++) {
				var ok = (q === '' || nameMatch || rows[c].getAttribute('data-text').indexOf(q) !== -1);
				rows[c].style.display = ok ? '' : 'none';
				if (ok) {
					vis++;
				}
			}
			total += rows.length;
			shown += vis;
			nsVisible += vis;
			ig.style.display = (vis > 0) ? '' : 'none';
			ig.querySelector('.badge').innerHTML = vis;
			if (q !== '' && vis > 0) {
				ig.open = true;
			}
		}
		nsGroups[a].style.display = (nsVisible > 0) ? '' : 'none';
		nsGroups[a].querySelector('.badge').innerHTML = nsVisible;
	}

	var lbl = document.getElementById('filterCount');
	if (lbl) {
		lbl.innerHTML = (q === '') ? '' : this.esc(this.msg('filterCount', { shown: shown, total: total }));
	}
}

/// Expands/collapses all the result groups.
ClientMethod toggleGroups(pOpen) [ Language = javascript ]
{
	var items = document.querySelectorAll('.item-group');
	for (var i = 0; i < items.length; i++) {
		items[i].open = pOpen;
	}
	var nss = document.querySelectorAll('.ns-group');
	for (var j = 0; j < nss.length; j++) {
		nss[j].open = true;
	}
}

/// Copies a text to the clipboard and notifies with a toast.
ClientMethod copyText(pText) [ Language = javascript ]
{
	var self = this;
	var done = function() { self.showToast(self.msg('copied', { text: pText })); };
	if (navigator.clipboard && navigator.clipboard.writeText) {
		navigator.clipboard.writeText(pText).then(done, function() { self.copyFallback(pText); done(); });
	} else {
		this.copyFallback(pText);
		done();
	}
}

ClientMethod copyFallback(pText) [ Language = javascript ]
{
	var ta = document.createElement('textarea');
	ta.value = pText;
	ta.style.position = 'fixed';
	ta.style.opacity = '0';
	document.body.appendChild(ta);
	ta.select();
	try {
		document.execCommand('copy');
	} catch (e) {
	}
	document.body.removeChild(ta);
}

ClientMethod showToast(pMsg) [ Language = javascript ]
{
	var old = document.getElementById('csToast');
	if (old) {
		old.parentNode.removeChild(old);
	}
	var t = document.createElement('div');
	t.id = 'csToast';
	t.className = 'toast';
	t.appendChild(document.createTextNode(pMsg));
	document.body.appendChild(t);
	setTimeout(function() {
		if (t.parentNode) {
			t.parentNode.removeChild(t);
		}
	}, 1800);
}

/// Escapes the HTML characters of a text before inserting it into the page.
ClientMethod esc(pText) [ Language = javascript ]
{
	if (pText === null || pText === undefined) {
		return '';
	}
	var div = document.createElement('div');
	div.appendChild(document.createTextNode(String(pText)));
	return div.innerHTML;
}

/// Escapes a text for use inside a double-quoted HTML attribute.
ClientMethod escAttr(pText) [ Language = javascript ]
{
	return this.esc(pText).replace(/"/g, '&quot;');
}

/// Wraps the occurrences of the searched term in <span class="hl">. Matching
/// is done on the original text and each piece is escaped separately, so the
/// term can never match inside an HTML entity (e.g.: searching for "amp"
/// must not break "&amp;").
ClientMethod highlight(pText, pTerm, pWholeWord, pCaseSensitive) [ Language = javascript ]
{
	var text = (pText === null || pText === undefined) ? '' : String(pText);
	if (!pTerm) {
		return this.esc(text);
	}
	var escTerm = pTerm.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
	var pattern = pWholeWord ? ('\\b(' + escTerm + ')\\b') : ('(' + escTerm + ')');
	var re = new RegExp(pattern, pCaseSensitive ? 'g' : 'ig');

	var out = '';
	var last = 0;
	var m;
	while ((m = re.exec(text)) !== null) {
		if (m[0].length === 0) {
			re.lastIndex++;
			continue;
		}
		out += this.esc(text.substring(last, m.index)) + '<span class="hl">' + this.esc(m[0]) + '</span>';
		last = m.index + m[0].length;
	}
	return out + this.esc(text.substring(last));
}

/// Updates the status line. pKind: "busy" (spinner), "error", "ok" or "".
ClientMethod setStatus(pMsg, pKind) [ Language = javascript ]
{
	var el = document.getElementById('lblStatusText');
	if (el) {
		el.className = 'status-label' + (pKind ? (' ' + pKind) : '');
		el.innerHTML = this.esc(pMsg);
	}
	var wrap = document.getElementById('progressWrap');
	if (wrap) {
		wrap.style.display = (pKind === 'busy') ? 'block' : 'none';
	}
}

/// Shows one or more warning messages (one yellow banner per message).
ClientMethod showWarnings(pList) [ Language = javascript ]
{
	if (!pList || pList.length === 0) {
		this.hideWarnings();
		return;
	}
	var html = '';
	for (var i = 0; i < pList.length; i++) {
		html += '<div class="warning-banner">' + this.esc(pList[i]) + '</div>';
	}
	var comp = zen('warningBanner');
	comp.setProperty('content', html);
	comp.setHidden(false);
}

ClientMethod hideWarnings() [ Language = javascript ]
{
	var comp = zen('warningBanner');
	comp.setProperty('content', '');
	comp.setHidden(true);
}

}
