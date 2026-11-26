# CodeSearch

*[English](README.md) | Português*

Ferramenta web para InterSystems IRIS/Caché que pesquisa um texto no código-fonte (classes e rotinas) de **todos os namespaces de uma vez**, sem precisar entrar em cada um.

## Conteúdo

| Classe | Função |
|---|---|
| `CodeSearch.Page` | Página Zen com o formulário de busca e a exibição dos resultados. |
| `CodeSearch.SearchAPI` | Endpoint HTTP (`%CSP.Page`) em JSON, chamado pela página. Ações: `start`, `status`, `result` e `cancel`. |
| `CodeSearch.Engine` | Lógica de busca: lista namespaces, enumera itens, lê o código e monta os trechos encontrados. |
| `CodeSearch.Messages` | Dicionário de mensagens (i18n) da interface, em inglês, espanhol e português. |

## Como a busca funciona

A busca roda em **segundo plano**, em um processo `Job` do servidor. Isso evita o erro HTTP 504 do Web Gateway, que corta qualquer requisição aberta por mais de ~60 s. O fluxo é:

1. A página chama `start`, e o servidor inicia o job e devolve um `jobId` na hora.
2. A página consulta `status` a cada ~0,7 s e mostra o andamento (namespace atual, namespaces concluídos, itens verificados e ocorrências).
3. Quando o job termina, a página busca o `result` e exibe os resultados.

O estado do job fica no global `^CodeSearchJob`, no namespace onde as classes estão instaladas. Jobs antigos (mais de 1 hora) são apagados automaticamente. Cada job só pode ser consultado ou cancelado pelo usuário que o iniciou.

## Requisitos

- InterSystems IRIS (ou Caché com suporte a JSON dinâmico e SQL `%SQL.Statement`).
- Acesso a uma Web Application CSP, que pode ser criada no Portal de Administração.
- Usuário com permissão de leitura nos namespaces que se deseja pesquisar. Namespaces sem acesso são listados como aviso na tela e não interrompem a busca.

## Instalação

1. **Importe e compile as classes** no namespace `%SYS`, para que o `%SYS.Namespace` seja acessível. O namespace usado pelo VS Code está em `.vscode/settings.json`.

   Pelo terminal do IRIS:

   ```objectscript
   zn "%SYS"
   do $system.OBJ.LoadDir("C:\caminho\para\SearchAll-app\CodeSearch", "ck", .errors, 1)
   ```

   Ou pelo VS Code, com a extensão InterSystems ObjectScript: abra a pasta e use **Import and Compile**.

2. **Crie uma Web Application CSP** em *System Administration > Security > Applications > Web Applications*:

   | Campo | Valor sugerido |
   |---|---|
   | Name | `/csp/codesearch` |
   | Namespace | `%SYS` |
   | Enable | Application, mais o método de autenticação desejado (ex.: Password) |
   | Allowed Authentication Methods | pelo menos um método autenticado, **não** use acesso sem login |

   `CodeSearch.Page` e `CodeSearch.SearchAPI` ficam na mesma aplicação, e a página chama a API por caminho relativo.

3. **Acesse a página:**

   ```
   http://<servidor>:<porta>/csp/codesearch/CodeSearch.Page.cls
   ```

> **Segurança:** por padrão, a página é protegida apenas pela autenticação da Web Application. Ela lê o código-fonte de todos os namespaces permitidos ao usuário logado. Restrinja o acesso a quem precisa. Para exigir uma role dedicada, crie um Resource (ex.: `%CodeSearch_Search`), uma Role com `USE` nele, e descomente/adicione em `CodeSearch.Page`:
>
> ```objectscript
> Parameter SECURITYRESOURCE = "%CodeSearch_Search:USE";
> ```

## Como usar

1. Digite o **texto a pesquisar** (mínimo de 3 caracteres) e tecle **Enter** ou clique em **Pesquisar**.
2. Ajuste as opções, se necessário:
   - **Palavra inteira:** só conta quando o termo aparece isolado (delimitado por caracteres que não sejam letra, dígito ou `_`).
   - **Diferenciar maiúsc./minúsc.:** por padrão a busca ignora a caixa.
   - **Namespaces:** seletor suspenso com multisseleção. O botão resume a escolha ("Todos os namespaces (29)", os nomes quando há até 2, ou "3 de 29 selecionados"). Ao clicar, abre a lista com campo de filtro e os atalhos **Selecionar todos** e **Limpar**, que valem só para os itens visíveis no filtro. Todos vêm marcados por padrão. Clique fora ou tecle Esc para fechar.
   - **Extensões:** `.cls`, `.mac`, `.int`, `.inc`, `.bas`.
   - **Máscara de nome (opcional):** filtra pelo nome do item. Aceita vários padrões separados por vírgula e `*` como curinga, sempre sem diferenciar maiúsculas de minúsculas. Exemplos: `app*.cls`, `*.mac,my.test.*.mac`. **Quando preenchida, substitui as extensões marcadas.**
3. Acompanhe o andamento: a barra e o status mostram o namespace atual, quantos já foram varridos, itens verificados, ocorrências e tempo decorrido. **Esc** ou o botão **Cancelar** interrompe a busca no servidor, e os resultados encontrados até então são exibidos.
4. Veja os resultados, agrupados por namespace e por classe/rotina, com o termo destacado e o número da linha:
   - **Filtrar resultados** refina a lista já exibida, por trecho de código ou nome do item.
   - **Expandir tudo / Recolher tudo** controla os grupos.
   - **Copiar nome** copia o nome do item para a área de transferência.

### Atalhos

| Tecla | Ação |
|---|---|
| Enter | Pesquisar |
| Esc | Cancelar a busca em andamento |
| Ctrl+K | Voltar ao campo de busca |

As preferências (termo, opções, extensões e namespaces selecionados) ficam salvas no navegador (localStorage) e são restauradas na próxima visita. O botão **Limpar** apaga o termo, a máscara e os resultados.

## Idiomas (i18n)

A interface está disponível em **inglês (en)**, **espanhol (es)** e **português (pt)**. O idioma é escolhido no seletor do cabeçalho; na primeira visita vale o idioma do navegador (ex.: `es-MX` usa `es`) e, se não houver tradução, o inglês. A escolha fica salva no navegador (`codesearch.lang`).

Os textos ficam em `CodeSearch.Messages`, um bloco `XData` XML por idioma (`<m k="chave">texto</m>`, com `%placeholders%`). O inglês é o idioma de reserva: chave ausente em outro idioma usa o texto em inglês. Para adicionar um idioma:

1. Copie o bloco `XData en`, renomeie para o código do novo idioma (ex.: `fr`) e traduza os valores, mantendo as chaves e os `%placeholders%`.
2. Inclua o código em `LANGUAGES` e o nome nativo em `LANGUAGENAMES` (mesma ordem) e recompile.

As respostas de erro da API (`SearchAPI`) trazem `error` (texto em inglês), `errorCode` e `errorParams`; a página traduz usando a chave `err.<errorCode>`.

## Limites

Definidos como parâmetros em `CodeSearch.Engine`:

| Parâmetro | Padrão | Descrição |
|---|---|---|
| `MAXRESULTS` | 500 | Máximo de ocorrências por busca. |
| `MAXSECONDS` | 600 | Tempo máximo de busca, em segundos. Como a busca roda em segundo plano, esse valor não é limitado pelo timeout do Web Gateway. |
| `MINTERMLEN` | 3 | Tamanho mínimo do termo. |
| `SNIPPETCONTEXTCHARS` | 80 | Caracteres de contexto antes/depois do termo no trecho exibido. |

Ao atingir `MAXRESULTS` ou `MAXSECONDS`, a busca para e a tela mostra um aviso de resultado truncado. Nesse caso, use um termo mais específico ou selecione menos namespaces e extensões.

## Solução de problemas

- **"Resposta do servidor não é JSON":** `CodeSearch.SearchAPI` não foi compilada, ou a sessão expirou e o servidor devolveu uma página de login. Recompile e recarregue a página.
- **"Não foi possível iniciar o processo de busca em segundo plano":** o servidor não conseguiu criar o `Job` (limite de processos/licenças atingido). Tente de novo ou peça a um administrador para verificar.
- **"O processo de busca parou de responder":** o job ficou mais de 3 minutos sem sinal de vida (ex.: foi encerrado no Portal). Faça a busca novamente.
- **"Busca não encontrada ou expirada":** o job foi apagado (mais de 1 hora) ou pertence a outro usuário.
- **Lista de namespaces vazia:** as classes precisam estar compiladas no `%SYS`, e o usuário precisa de acesso à listagem de namespaces.
- **Namespace aparece em "Sem acesso ou erro":** o usuário logado não tem permissão de leitura nele.
- **Classes não encontradas:** confira se `.cls` está marcada em Extensões e se a máscara está vazia ou compatível com o nome do item.
