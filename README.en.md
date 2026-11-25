# CodeSearch

*English | [Português](README.md)*

A web tool for InterSystems IRIS/Caché that searches for text in the source code (classes and routines) of **all namespaces at once**, without having to enter each one.

## Contents

| Class | Purpose |
|---|---|
| `CodeSearch.Page` | Zen page with the search form and the results display. |
| `CodeSearch.SearchAPI` | JSON HTTP endpoint (`%CSP.Page`) called by the page. Actions: `start`, `status`, `result` and `cancel`. |
| `CodeSearch.Engine` | Search logic: lists namespaces, enumerates items, reads the code and builds the snippets found. |
| `CodeSearch.Messages` | Message dictionary (i18n) for the interface, in English, Spanish and Portuguese. |

## How the search works

The search runs in the **background**, in a server `Job` process. This avoids the Web Gateway HTTP 504 error, which cuts off any request open for more than ~60 s. The flow is:

1. The page calls `start`, and the server starts the job and immediately returns a `jobId`.
2. The page queries `status` every ~0.7 s and shows the progress (current namespace, namespaces completed, items checked and matches).
3. When the job finishes, the page fetches the `result` and displays the results.

The job state is kept in the `^CodeSearchJob` global, in the namespace where the classes are installed. Old jobs (older than 1 hour) are deleted automatically. Each job can only be queried or cancelled by the user who started it.

## Requirements

- InterSystems IRIS (or Caché with support for dynamic JSON and `%SQL.Statement` SQL).
- Access to a CSP Web Application, which can be created in the Management Portal.
- A user with read permission on the namespaces to be searched. Namespaces without access are listed as a warning on screen and do not interrupt the search.

## Installation

1. **Import and compile the classes** in the `%SYS` namespace, so that `%SYS.Namespace` is accessible. The namespace used by VS Code is in `.vscode/settings.json`.

   From the IRIS terminal:

   ```objectscript
   zn "%SYS"
   do $system.OBJ.LoadDir("C:\path\to\SearchAll-app\CodeSearch", "ck", .errors, 1)
   ```

   Or from VS Code, with the InterSystems ObjectScript extension: open the folder and use **Import and Compile**.

2. **Create a CSP Web Application** in *System Administration > Security > Applications > Web Applications*:

   | Field | Suggested value |
   |---|---|
   | Name | `/csp/codesearch` |
   | Namespace | `%SYS` |
   | Enable | Application, plus the desired authentication method (e.g.: Password) |
   | Allowed Authentication Methods | at least one authenticated method, **do not** allow unauthenticated access |

   `CodeSearch.Page` and `CodeSearch.SearchAPI` live in the same application, and the page calls the API by relative path.

3. **Open the page:**

   ```
   http://<server>:<port>/csp/codesearch/CodeSearch.Page.cls
   ```

> **Security:** by default, the page is protected only by the Web Application authentication. It reads the source code of every namespace the logged-in user is allowed to access. Restrict access to those who need it. To require a dedicated role, create a Resource (e.g.: `%CodeSearch_Search`), a Role with `USE` on it, and uncomment/add in `CodeSearch.Page`:
>
> ```objectscript
> Parameter SECURITYRESOURCE = "%CodeSearch_Search:USE";
> ```

## How to use

1. Type the **text to search** (minimum 3 characters) and press **Enter** or click **Search**.
2. Adjust the options, if needed:
   - **Whole word:** only counts when the term appears on its own (delimited by characters that are not a letter, digit or `_`).
   - **Match case:** by default the search ignores case.
   - **Namespaces:** dropdown selector with multi-select. The button summarizes the choice ("All namespaces (29)", the names when up to 2 are selected, or "3 of 29 selected"). Clicking it opens the list with a filter field and the **Select all** and **Clear** shortcuts, which apply only to the items visible under the filter. All are checked by default. Click outside or press Esc to close.
   - **Extensions:** `.cls`, `.mac`, `.int`, `.inc`, `.bas`.
   - **Name mask (optional):** filters by item name. Accepts several comma-separated patterns and `*` as a wildcard, always case-insensitive. Examples: `app*.cls`, `*.mac,my.test.*.mac`. **When filled in, it replaces the checked extensions.**
3. Follow the progress: the bar and the status show the current namespace, how many have been scanned, items checked, matches and elapsed time. **Esc** or the **Cancel** button stops the search on the server, and the results found so far are displayed.
4. View the results, grouped by namespace and by class/routine, with the term highlighted and the line number:
   - **Filter results** narrows the list already shown, by code snippet or item name.
   - **Expand all / Collapse all** controls the groups.
   - **Copy name** copies the item name to the clipboard.

### Shortcuts

| Key | Action |
|---|---|
| Enter | Search |
| Esc | Cancel the search in progress |
| Ctrl+K | Go back to the search field |

The preferences (term, options, extensions and selected namespaces) are saved in the browser (localStorage) and restored on the next visit. The **Clear** button erases the term, the mask and the results.

## Languages (i18n)

The interface is available in **English (en)**, **Spanish (es)** and **Portuguese (pt)**. The language is chosen with the selector in the header; on the first visit the browser language applies (e.g.: `es-MX` uses `es`) and, if there is no translation, English. The choice is saved in the browser (`codesearch.lang`).

The texts live in `CodeSearch.Messages`, one XML `XData` block per language (`<m k="key">text</m>`, with `%placeholders%`). English is the fallback language: a key missing from another language uses the English text. To add a language:

1. Copy the `XData en` block, rename it to the new language code (e.g.: `fr`) and translate the values, keeping the keys and the `%placeholders%`.
2. Add the code to `LANGUAGES` and its native name to `LANGUAGENAMES` (same order) and recompile.

The API error responses (`SearchAPI`) carry `error` (English text), `errorCode` and `errorParams`; the page translates them using the key `err.<errorCode>`.

## Limits

Defined as parameters in `CodeSearch.Engine`:

| Parameter | Default | Description |
|---|---|---|
| `MAXRESULTS` | 500 | Maximum number of matches per search. |
| `MAXSECONDS` | 600 | Maximum search time, in seconds. Since the search runs in the background, this value is not limited by the Web Gateway timeout. |
| `MINTERMLEN` | 3 | Minimum length of the term. |
| `SNIPPETCONTEXTCHARS` | 80 | Characters of context before/after the term in the displayed snippet. |

When `MAXRESULTS` or `MAXSECONDS` is reached, the search stops and the screen shows a truncated-results warning. In that case, use a more specific term or select fewer namespaces and extensions.

## Troubleshooting

- **"The server response is not JSON":** `CodeSearch.SearchAPI` was not compiled, or the session expired and the server returned a login page. Recompile and reload the page.
- **"Could not start the background search process":** the server could not create the `Job` (process/license limit reached). Try again or ask an administrator to check.
- **"The search process stopped responding":** the job went more than 3 minutes without a sign of life (e.g.: it was terminated in the Portal). Run the search again.
- **"Search not found or expired":** the job was deleted (older than 1 hour) or belongs to another user.
- **Empty namespace list:** the classes must be compiled in `%SYS`, and the user needs access to the namespace listing.
- **Namespace shown under "No access or errors in namespaces":** the logged-in user has no read permission on it.
- **Classes not found:** check that `.cls` is checked under Extensions and that the mask is empty or compatible with the item name.
