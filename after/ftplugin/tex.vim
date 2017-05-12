" =============================================================================
" File: ftplugin/tex.vim
" Description: Provide foldexpr and foldtext for TeX files
" Author: Matthias Vogelgesang <github.com/matze>
"
" =============================================================================

"{{{ Globals

if !exists('g:tex_fold_sec_char')
    let g:tex_fold_sec_char = '➜'
endif

if !exists('g:tex_fold_env_char')
    let g:tex_fold_env_char = '✎'
endif

if !exists('g:tex_fold_override_foldtext')
    let g:tex_fold_override_foldtext = 1
endif

if !exists('g:tex_fold_allow_marker')
    let g:tex_fold_allow_marker = 1
endif

if !exists('b:tex_fold_additional_envs')
  if !exists('g:tex_fold_additional_envs')
    let b:tex_fold_additional_envs = g:tex_fold_additional_envs
  else
    let b:tex_fold_additional_envs = []
  endif
endif

if !exists('g:tex_fold_use_default_envs')
    let g:tex_fold_use_default_envs = 1
endif

if !exists('g:tex_fold_ignore_envs')
    let g:tex_fold_ignore_envs = 0
endif

"}}}
"{{{ Fold options

setlocal foldmethod=expr
setlocal foldexpr=TeXFold(v:lnum)

if g:tex_fold_override_foldtext
    setlocal foldtext=TeXFoldText()
endif

"}}}
"{{{ Functions

function! TeXFold(lnum)
    let line = getline(a:lnum)
    let default_envs = g:tex_fold_use_default_envs?
        \['frame', 'table', 'figure', 'align', 'lstlisting']: []
    let envs = '\(' . join(default_envs + b:tex_fold_additional_envs, '\|') . '\)'

    if line =~ '^\(\s\|%\)*\\section'
        return '>1'
    endif

    if line =~ '^\(\s\|%\)*\\subsection'
        return '>2'
    endif

    if line =~ '^\(\s\|%\)*\\subsubsection'
        return '>3'
    endif

    if !g:tex_fold_ignore_envs
        if line =~ '^\(\s\|%\)*\\begin{' . envs
            return 'a1'
        endif

        if line =~ '^\s*\\end{document}'
          return 0
        elseif line =~ '^\(\s\|%\)*\\end{' . envs
            return 's1'
        endif
    endif

    if g:tex_fold_allow_marker
        if line =~ '%{{{5'
            return 'a5'
        elseif line =~ '%{{{'
            return 'a1'
        endif

        "if line =~ '^[^%]*%[^}]*}}}'
        if line =~ '%}}}5'
            return 's5'
        elseif line =~ '%}}}'
            return 's1'
        endif
    endif

    return '='
endfunction

function! TeXFoldText()
    let fillChar = '·'
    let fold_line = getline(v:foldstart)

    let commente = '{' . fillChar . fillChar . '}'
    if fold_line =~ '^\s*%' "commence par un %
      if !(fold_line =~ '^\s*%\({{{\|}}}\)') "à moins que commentée par commence par %{{{
        let fold_line = substitute(fold_line, '^[[:space:]%]*\({{{\)\@!', '' , '') "on enleve le commentaire init
        let commente = '{%%}'
      end
    end
    if fold_line =~ '^\s*\\\(sub\)*section'
        let pattern = '\\\(\(sub\)*\)section\(\**\){\([^}]*\)}'
        let repl = ' \3\1' . g:tex_fold_sec_char . ' \4'
    elseif fold_line =~ '^\s*\\begin{[^}]*}['
        let pattern = '\\begin{\([^}]*\)}\[\([^\]]*\)\]'
        let repl = ' ' . g:tex_fold_env_char . ' \1 : (\2)' 
    elseif fold_line =~ '^\s*\\begin'
        let pattern = '\\begin{\([^}]*\)}'
        let repl = ' ' . g:tex_fold_env_char . ' \1'
    "elseif fold_line =~ '^\s*%\(.*\)%{{{'
    "    "let pattern = '^[^{]*{' . '{{\([.]*\)'
    "    let pattern = '^\s*%\(.*\)%{{{'
    "    "let repl = '\1'
    "    let repl = '%commenté%   \1 |%| '
    elseif fold_line =~ '%.*{{{'
        "let pattern = '^[^{]*{' . '{{\([.]*\)'
        let pattern = '^\s*\([^%]*\)%[^{]*{{{'
        "let repl = '\1'
        let repl = ' \1 |%| '
    endif

    let line = substitute(fold_line, pattern, repl, '') . ' '
    let text = '+-' . commente . v:folddashes . v:folddashes . substitute(line, '\s*$', '' , '') . ' '
    "http://stackoverflow.com/a/5319120/6543971
    let offset = 10
    let linesNum = v:foldend-v:foldstart + 1
    return text . repeat(fillChar, 9*winwidth(0)/10 - strlen(text) - offset) . '{{'. linesNum .' lignes}}' . repeat(fillChar, offset + winwidth(0)/10)
endfunction

"}}}
"{{{ Undo

if exists('b:undo_ftplugin')
  let b:undo_ftplugin .= "|setl foldexpr< foldmethod< foldtext<"
else
  let b:undo_ftplugin = "setl foldexpr< foldmethod< foldtext<"
endif
"}}}
