function! db_ui#dbout#jump_to_foreign_table() abort
  let parsed = db#url#parse(b:db)
  let scheme = db_ui#schemas#get(parsed.scheme)
  if empty(scheme)
    return db_ui#utils#echo_err(parsed.scheme.' scheme not supported for foreign key jump.')
  endif

  let cell_range = s:get_cell_range(getline(scheme.cell_line_number), col('.'))
  let field_name = trim(getline(scheme.cell_line_number - 1)[(cell_range.from):(cell_range.to)])
  let field_value = trim(getline('.')[(cell_range.from):(cell_range.to)])
  let foreign_key_query = substitute(scheme.foreign_key_query, '{col_name}', field_name, '')
  let result = scheme.parse_results(db_ui#schemas#query({ 'conn': b:db }, foreign_key_query), 3)
  if empty(result)
    return db_ui#utils#echo_err('No valid foreign key found.')
  endif

  let [foreign_table_name, foreign_column_name,foreign_table_schema] = result[0]
  let query = printf(scheme.select_foreign_key_query, foreign_table_schema, foreign_table_name, foreign_column_name, db_ui#utils#quote_query_value(field_value))
  exe 'DB '.query
endfunction

function! db_ui#dbout#foldexpr(lnum) abort
  if getline(a:lnum) !~? '^[[:blank:]]*$'
    " Mysql
    if getline(a:lnum) =~? '^+---' && getline(a:lnum + 2) =~? '^+---'
      return '>1'
    endif
    " Postgres & Sqlserver
    if getline(a:lnum + 1) =~? '^----'
      return '>1'
    endif
    return 1
  endif

  "Postgres & Sqlserver
  if getline(a:lnum) =~? '^[[:blank:]]*$'
    if getline(a:lnum + 2) !~? '^----'
      return 1
    endif
    return 0
  endif

  return -1
endfunction

function! db_ui#dbout#yank_cell_value() abort
  let parsed = db#url#parse(b:db)
  let scheme = db_ui#schemas#get(parsed.scheme)
  if empty(scheme)
    return db_ui#utils#echo_err('Yanking cell value not supported for '.parsed.scheme.' scheme.')
  endif

  let cell_range = s:get_cell_range(getline(scheme.cell_line_number), col('.'))
  let field_value = trim(getline('.')[(cell_range.from):(cell_range.to)])
  call setreg(v:register, field_value)
endfunction

function! s:get_cell_range(line, col) abort
  let table_line = '-'
  let col = a:col - 1
  let from = 0
  let to = 0
  while col >= 0 && a:line[col] ==? table_line
    let from = col
    let col -= 1
  endwhile
  let col = a:col - 1
  while col <= len(a:line) && a:line[col] ==? table_line
    let to = col
    let col += 1
  endwhile

  return {'from': from, 'to': to}
endfunction
