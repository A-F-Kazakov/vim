scriptencoding utf-8

let s:icon_closed = g:tagbar_iconchars[0]
let s:icon_open   = g:tagbar_iconchars[1]

let s:type_init_done    = 0
let s:autocommands_done = 0
let s:statusline_in_use = 0

let s:checked_ctags       = 0
let s:checked_ctags_types = 0
let s:ctags_is_uctags     = 0
let s:ctags_types         = {}

let s:new_window      = 1
let s:is_maximized    = 0
let s:winrestcmd      = ''
let s:short_help      = 1
let s:nearby_disabled = 0
let s:paused = 0
let s:pwin_by_tagbar = 0
let s:buffer_seqno = 0
let s:vim_quitting = 0
let s:last_alt_bufnr = -1

let s:window_expanded   = 0
let s:expand_bufnr = -1
let s:window_pos = {'pre': {'x': 0, 'y': 0}, 'post': {'x': 0, 'y': 0}}

let s:compare_typeinfo = {}

let s:visibility_symbols = {'public': '+', 'protected': '#', 'private': '-'}

let g:loaded_tagbar = 1

let s:last_highlight_tline = 0

let s:warnings = {'type': [], 'encoding': 0}

function! s:Init(silent) abort
    if s:checked_ctags == 2 && a:silent
        return 0
    elseif s:checked_ctags != 1
        if !s:CheckForExCtags(a:silent)
            return 0
        endif
    endif

    if !s:checked_ctags_types
        call s:GetSupportedFiletypes()
    endif

    if !s:type_init_done
        call s:InitTypes()
    endif

    if !s:autocommands_done
        call s:CreateAutocommands()
        call s:AutoUpdate(fnamemodify(expand('%'), ':p'), 0)
    endif

    return 1
endfunction

function! s:InitTypes() abort
    let s:known_types = {}

    let type_asm = s:TypeInfo.New()
    let type_asm.ctagstype = 'asm'
    let type_asm.kinds     = [
        \ {'short' : 'm', 'long' : 'macros',  'fold' : 0, 'stl' : 1},
        \ {'short' : 't', 'long' : 'types',   'fold' : 0, 'stl' : 1},
        \ {'short' : 'd', 'long' : 'defines', 'fold' : 0, 'stl' : 1},
        \ {'short' : 'l', 'long' : 'labels',  'fold' : 0, 'stl' : 1}
    \ ]
    let s:known_types.asm = type_asm

    let type_asy = s:TypeInfo.New()
    let type_asy.ctagstype = 'c'
    let type_asy.kinds     = [
        \ {'short' : 'd', 'long' : 'macros',      'fold' : 1, 'stl' : 0},
        \ {'short' : 'p', 'long' : 'prototypes',  'fold' : 1, 'stl' : 0},
        \ {'short' : 'g', 'long' : 'enums',       'fold' : 0, 'stl' : 1},
        \ {'short' : 'e', 'long' : 'enumerators', 'fold' : 0, 'stl' : 0},
        \ {'short' : 't', 'long' : 'typedefs',    'fold' : 0, 'stl' : 0},
        \ {'short' : 's', 'long' : 'structs',     'fold' : 0, 'stl' : 1},
        \ {'short' : 'u', 'long' : 'unions',      'fold' : 0, 'stl' : 1},
        \ {'short' : 'm', 'long' : 'members',     'fold' : 0, 'stl' : 0},
        \ {'short' : 'v', 'long' : 'variables',   'fold' : 0, 'stl' : 0},
        \ {'short' : 'f', 'long' : 'functions',   'fold' : 0, 'stl' : 1}
    \ ]
    let type_asy.sro        = '::'
    let type_asy.kind2scope = {'g': 'enum', 's': 'struct', 'u': 'union'}
    let type_asy.scope2kind = {'enum': 'g', 'struct': 's', 'union': 'u'}
    let s:known_types.asy = type_asy

    let type_c = s:TypeInfo.New()
    let type_c.ctagstype = 'c'
    let type_c.kinds     = [
        \ {'short' : 'd', 'long' : 'macros',      'fold' : 1, 'stl' : 0},
        \ {'short' : 'p', 'long' : 'prototypes',  'fold' : 1, 'stl' : 0},
        \ {'short' : 'g', 'long' : 'enums',       'fold' : 0, 'stl' : 1},
        \ {'short' : 'e', 'long' : 'enumerators', 'fold' : 0, 'stl' : 0},
        \ {'short' : 't', 'long' : 'typedefs',    'fold' : 0, 'stl' : 0},
        \ {'short' : 's', 'long' : 'structs',     'fold' : 0, 'stl' : 1},
        \ {'short' : 'u', 'long' : 'unions',      'fold' : 0, 'stl' : 1},
        \ {'short' : 'm', 'long' : 'members',     'fold' : 0, 'stl' : 0},
        \ {'short' : 'v', 'long' : 'variables',   'fold' : 0, 'stl' : 0},
        \ {'short' : 'f', 'long' : 'functions',   'fold' : 0, 'stl' : 1}
    \ ]
    let type_c.sro        = '::'
    let type_c.kind2scope = {'g': 'enum', 's': 'struct', 'u': 'union'}
    let type_c.scope2kind = {'enum': 'g', 'struct': 's', 'union': 'u'}
    let s:known_types.c = type_c

    let type_cpp = s:TypeInfo.New()
    let type_cpp.ctagstype = 'c++'
    let type_cpp.kinds     = [
        \ {'short' : 'd', 'long' : 'macros',      'fold' : 1, 'stl' : 0},
        \ {'short' : 'p', 'long' : 'prototypes',  'fold' : 1, 'stl' : 0},
        \ {'short' : 'g', 'long' : 'enums',       'fold' : 0, 'stl' : 1},
        \ {'short' : 'e', 'long' : 'enumerators', 'fold' : 0, 'stl' : 0},
        \ {'short' : 't', 'long' : 'typedefs',    'fold' : 0, 'stl' : 0},
        \ {'short' : 'n', 'long' : 'namespaces',  'fold' : 0, 'stl' : 1},
        \ {'short' : 'c', 'long' : 'classes',     'fold' : 0, 'stl' : 1},
        \ {'short' : 's', 'long' : 'structs',     'fold' : 0, 'stl' : 1},
        \ {'short' : 'u', 'long' : 'unions',      'fold' : 0, 'stl' : 1},
        \ {'short' : 'f', 'long' : 'functions',   'fold' : 0, 'stl' : 1},
        \ {'short' : 'm', 'long' : 'members',     'fold' : 0, 'stl' : 0},
        \ {'short' : 'v', 'long' : 'variables',   'fold' : 0, 'stl' : 0}
    \ ]
    let type_cpp.sro        = '::'
    let type_cpp.kind2scope = {'g': 'enum', 'n': 'namespace', 'c': 'class', 's': 'struct', 'u': 'union'}
    let type_cpp.scope2kind = { 'enum': 'g', 'namespace': 'n', 'class': 'c', 'struct': 's', 'union': 'u'}
    let s:known_types.cpp = type_cpp

    let type_html = s:TypeInfo.New()
    let type_html.ctagstype = 'html'
    if s:ctags_is_uctags
        let type_html.kinds = [
            \ {'short' : 'a', 'long' : 'named anchors', 'fold' : 0, 'stl' : 1},
            \ {'short' : 'h', 'long' : 'H1 headings',   'fold' : 0, 'stl' : 1},
            \ {'short' : 'i', 'long' : 'H2 headings',   'fold' : 0, 'stl' : 1},
            \ {'short' : 'j', 'long' : 'H3 headings',   'fold' : 0, 'stl' : 1},
        \ ]
    else
        let type_html.kinds = [
            \ {'short' : 'f', 'long' : 'JavaScript functions', 'fold' : 0, 'stl' : 1},
            \ {'short' : 'a', 'long' : 'named anchors',        'fold' : 0, 'stl' : 1}
        \ ]
    endif
    let s:known_types.html = type_html

    let type_javascript = s:TypeInfo.New()
    let type_javascript.ctagstype = 'javascript'
    let jsctags = s:CheckFTCtags('jsctags', 'javascript')
    if jsctags != ''
        let type_javascript.kinds = [
            \ {'short' : 'v', 'long' : 'variables', 'fold' : 0, 'stl' : 0},
            \ {'short' : 'f', 'long' : 'functions', 'fold' : 0, 'stl' : 1}
        \ ]
        let type_javascript.sro        = '.'
        let type_javascript.kind2scope = {'v': 'namespace', 'f': 'namespace'}
        let type_javascript.scope2kind = {'namespace': 'v'}
        let type_javascript.ctagsbin   = jsctags
        let type_javascript.ctagsargs  = '-f -'
    else
        let type_javascript.kinds = [
            \ {'short': 'v', 'long': 'global variables', 'fold': 0, 'stl': 0},
            \ {'short': 'c', 'long': 'classes',          'fold': 0, 'stl': 1},
            \ {'short': 'p', 'long': 'properties',       'fold': 0, 'stl': 0},
            \ {'short': 'm', 'long': 'methods',          'fold': 0, 'stl': 1},
            \ {'short': 'f', 'long': 'functions',        'fold': 0, 'stl': 1},
        \ ]
        let type_javascript.sro        = '.'
        let type_javascript.kind2scope = {'c': 'class', 'f': 'function', 'm': 'method', 'p': 'property'}
        let type_javascript.scope2kind = {'class': 'c', 'function': 'f'}
    endif
    let s:known_types.javascript = type_javascript

    let type_make = s:TypeInfo.New()
    let type_make.ctagstype = 'make'
    let type_make.kinds     = [{'short': 'm', 'long': 'macros', 'fold': 0, 'stl': 1}]
    let s:known_types.make = type_make

    let type_sql = s:TypeInfo.New()
    let type_sql.ctagstype = 'sql'
    let type_sql.kinds     = [
        \ {'short' : 'P', 'long' : 'packages',               'fold' : 1, 'stl' : 1},
        \ {'short' : 'd', 'long' : 'prototypes',             'fold' : 0, 'stl' : 1},
        \ {'short' : 'c', 'long' : 'cursors',                'fold' : 0, 'stl' : 1},
        \ {'short' : 'f', 'long' : 'functions',              'fold' : 0, 'stl' : 1},
        \ {'short' : 'F', 'long' : 'record fields',          'fold' : 0, 'stl' : 1},
        \ {'short' : 'L', 'long' : 'block label',            'fold' : 0, 'stl' : 1},
        \ {'short' : 'p', 'long' : 'procedures',             'fold' : 0, 'stl' : 1},
        \ {'short' : 's', 'long' : 'subtypes',               'fold' : 0, 'stl' : 1},
        \ {'short' : 't', 'long' : 'tables',                 'fold' : 0, 'stl' : 1},
        \ {'short' : 'T', 'long' : 'triggers',               'fold' : 0, 'stl' : 1},
        \ {'short' : 'v', 'long' : 'variables',              'fold' : 0, 'stl' : 1},
        \ {'short' : 'i', 'long' : 'indexes',                'fold' : 0, 'stl' : 1},
        \ {'short' : 'e', 'long' : 'events',                 'fold' : 0, 'stl' : 1},
        \ {'short' : 'U', 'long' : 'publications',           'fold' : 0, 'stl' : 1},
        \ {'short' : 'R', 'long' : 'services',               'fold' : 0, 'stl' : 1},
        \ {'short' : 'D', 'long' : 'domains',                'fold' : 0, 'stl' : 1},
        \ {'short' : 'V', 'long' : 'views',                  'fold' : 0, 'stl' : 1},
        \ {'short' : 'n', 'long' : 'synonyms',               'fold' : 0, 'stl' : 1},
        \ {'short' : 'x', 'long' : 'MobiLink Table Scripts', 'fold' : 0, 'stl' : 1},
        \ {'short' : 'y', 'long' : 'MobiLink Conn Scripts',  'fold' : 0, 'stl' : 1},
        \ {'short' : 'z', 'long' : 'MobiLink Properties',    'fold' : 0, 'stl' : 1}
    \ ]
    let s:known_types.sql = type_sql

    let type_tex = s:TypeInfo.New()
    let type_tex.ctagstype = 'tex'
    let type_tex.kinds     = [
        \ {'short' : 'i', 'long' : 'includes',       'fold' : 1, 'stl' : 0},
        \ {'short' : 'p', 'long' : 'parts',          'fold' : 0, 'stl' : 1},
        \ {'short' : 'c', 'long' : 'chapters',       'fold' : 0, 'stl' : 1},
        \ {'short' : 's', 'long' : 'sections',       'fold' : 0, 'stl' : 1},
        \ {'short' : 'u', 'long' : 'subsections',    'fold' : 0, 'stl' : 1},
        \ {'short' : 'b', 'long' : 'subsubsections', 'fold' : 0, 'stl' : 1},
        \ {'short' : 'P', 'long' : 'paragraphs',     'fold' : 0, 'stl' : 0},
        \ {'short' : 'G', 'long' : 'subparagraphs',  'fold' : 0, 'stl' : 0},
        \ {'short' : 'l', 'long' : 'labels',         'fold' : 0, 'stl' : 0}
    \ ]
    let type_tex.sro        = '""'
    let type_tex.kind2scope = {'p': 'part', 'c': 'chapter', 's': 'section', 'u': 'subsection', 'b': 'subsubsection'}
    let type_tex.scope2kind = {'part': 'p', 'chapter': 'c', 'section': 's', 'subsection': 'u', 'subsubsection': 'b'}
    let type_tex.sort = 0
    let s:known_types.tex = type_tex

    let type_vim = s:TypeInfo.New()
    let type_vim.ctagstype = 'vim'
    let type_vim.kinds     = [
        \ {'short' : 'n', 'long' : 'vimball filenames',  'fold' : 0, 'stl' : 1},
        \ {'short' : 'v', 'long' : 'variables',          'fold' : 1, 'stl' : 0},
        \ {'short' : 'f', 'long' : 'functions',          'fold' : 0, 'stl' : 1},
        \ {'short' : 'a', 'long' : 'autocommand groups', 'fold' : 1, 'stl' : 1},
        \ {'short' : 'c', 'long' : 'commands',           'fold' : 0, 'stl' : 0},
        \ {'short' : 'm', 'long' : 'maps',               'fold' : 1, 'stl' : 0}
    \ ]
    let s:known_types.vim = type_vim

    for [type, typeinfo] in items(s:known_types)
        let typeinfo.ftype = type
    endfor

    call s:LoadUserTypeDefs()

    for typeinfo in values(s:known_types)
        call typeinfo.createKinddict()
    endfor

    let s:type_init_done = 1
endfunction

function! s:LoadUserTypeDefs(...) abort
    if a:0 > 0
        let type = a:1

        let defdict = {}
        let defdict[type] = g:tagbar_type_{type}
    else
        let defdict = tagbar#getusertypes()
    endif

    let transformed = {}
    for [type, def] in items(defdict)
        let transformed[type] = s:TransformUserTypeDef(def)
        let transformed[type].ftype = type
    endfor

    for [key, value] in items(transformed)
        if !has_key(s:known_types, key) || get(value, 'replace', 0)
            let s:known_types[key] = s:TypeInfo.New(value)
        else
            call extend(s:known_types[key], value)
        endif
    endfor

    if a:0 > 0
        call s:known_types[type].createKinddict()
    endif
endfunction

function! s:TransformUserTypeDef(def) abort
    let newdef = copy(a:def)

    if has_key(a:def, 'kinds')
        let newdef.kinds = []
        let kinds = a:def.kinds
        for kind in kinds
            let kindlist = split(kind, ':')
            let kinddict = {'short' : kindlist[0], 'long' : kindlist[1]}
            let kinddict.fold = get(kindlist, 2, 0)
            let kinddict.stl  = get(kindlist, 3, 1)
            call add(newdef.kinds, kinddict)
        endfor
    endif

    if has_key(a:def, 'kind2scope') && !has_key(a:def, 'scope2kind')
        let newdef.scope2kind = {}
        for [key, value] in items(a:def.kind2scope)
            let newdef.scope2kind[value] = key
        endfor
    elseif has_key(a:def, 'scope2kind') && !has_key(a:def, 'kind2scope')
        let newdef.kind2scope = {}
        for [key, value] in items(a:def.scope2kind)
            let newdef.kind2scope[value] = key
        endfor
    endif

    return newdef
endfunction

function! s:RestoreSession() abort
    let curfile = fnamemodify(bufname('%'), ':p')

    let tagbarwinnr = bufwinnr(s:TagbarBufName())
    if tagbarwinnr == -1
        return
    else
        let in_tagbar = 1
        if winnr() != tagbarwinnr
            call s:goto_win(tagbarwinnr)
            let in_tagbar = 0
        endif
    endif

    let s:last_autofocus = 0

    call s:Init(0)
    call s:InitWindow(g:tagbar_autoclose)
    call s:AutoUpdate(curfile, 0)

    if !in_tagbar
        call s:goto_win('p')
    endif
endfunction

function! s:MapKeys() abort
    nnoremap <script> <silent> <buffer> <2-LeftMouse>:call <SID>JumpToTag(0)<CR>
    nnoremap <script> <silent> <buffer> <LeftRelease> <LeftRelease>:call <SID>CheckMouseClick()<CR>
    inoremap <script> <silent> <buffer> <2-LeftMouse> <C-o>:call <SID>JumpToTag(0)<CR>
    inoremap <script> <silent> <buffer> <LeftRelease> <LeftRelease><C-o>:call <SID>CheckMouseClick()<CR>

    let maps = [
        \ ['jump',          'JumpToTag(0)'],
        \ ['preview',       'JumpToTag(1)'],
        \ ['previewwin',    'ShowInPreviewWin()'],
        \ ['nexttag',       'GotoNextToplevelTag(1)'],
        \ ['prevtag',       'GotoNextToplevelTag(-1)'],
        \ ['showproto',     'ShowPrototype(0)'],
        \ ['hidenonpublic', 'ToggleHideNonPublicTags()'],
        \
        \ ['openfold',      'OpenFold()'],
        \ ['closefold',     'CloseFold()'],
        \ ['togglefold',    'ToggleFold()'],
        \ ['openallfolds',  'SetFoldLevel(99, 1)'],
        \ ['closeallfolds', 'SetFoldLevel(0, 1)'],
        \ ['nextfold',      'GotoNextFold()'],
        \ ['prevfold',      'GotoPrevFold()'],
        \
        \ ['togglesort',            'ToggleSort()'],
        \ ['togglecaseinsensitive', 'ToggleCaseInsensitive()'],
        \ ['toggleautoclose',       'ToggleAutoclose()'],
        \ ['zoomwin',               'ZoomWindow()'],
        \ ['close',                 'CloseWindow()'],
        \ ['help',                  'ToggleHelp()'],
    \ ]

    let map_options = ' <script> <silent> <buffer> '
    if v:version > 703 || (v:version == 703 && has('patch1261'))
        let map_options .= ' <nowait> '
    endif

    for [map, func] in maps
        let def = get(g:, 'tagbar_map_' . map)
        if type(def) == type("")
            let keys = [def]
        else
            let keys = def
        endif
        for key in keys
            execute 'nnoremap' . map_options . key .
                        \ ' :call <SID>' . func . '<CR>'
        endfor
        unlet def
    endfor

    let b:tagbar_mapped_keys = 1
endfunction

function! s:CreateAutocommands() abort
    augroup TagbarAutoCmds
        autocmd!

        if !g:tagbar_silent
            autocmd CursorHold __Tagbar__.* call s:ShowPrototype(1)
        endif
        autocmd WinEnter   __Tagbar__.* call s:SetStatusLine()
        autocmd WinLeave   __Tagbar__.* call s:SetStatusLine()

        if g:tagbar_autopreview
            autocmd CursorMoved __Tagbar__.* nested call s:ShowInPreviewWin()
        endif

        autocmd BufEnter * if expand('<amatch>') !~ '__Tagbar__.*' | let s:last_alt_bufnr = bufnr('#') | endif
        if exists('##QuitPre')
            autocmd QuitPre * let s:vim_quitting = 1
        endif
        autocmd WinEnter * nested call s:HandleOnlyWindow()
        autocmd WinEnter * if bufwinnr(s:TagbarBufName()) == -1 | call s:ShrinkIfExpanded() | endif

        autocmd BufWritePost * call s:AutoUpdate(fnamemodify(expand('<afile>'), ':p'), 1)
        autocmd BufReadPost,BufEnter,CursorHold,FileType * call s:AutoUpdate(fnamemodify(expand('<afile>'), ':p'), 0)
        autocmd BufDelete,BufWipeout * nested call s:HandleBufDelete(expand('<afile>'), expand('<abuf>'))

        autocmd QuickFixCmdPre  *grep* let s:tagbar_qf_active = 1
        autocmd QuickFixCmdPost *grep* if exists('s:tagbar_qf_active') | unlet s:tagbar_qf_active | endif

        autocmd VimEnter * call s:CorrectFocusOnStartup()
    augroup END

    let s:autocommands_done = 1
endfunction

function! s:CheckForExCtags(silent) abort
    if !exists('g:tagbar_ctags_bin')
        let ctagsbins  = []
        let ctagsbins += ['ctags-exuberant'] " Debian
        let ctagsbins += ['exuberant-ctags']
        let ctagsbins += ['exctags'] " FreeBSD, NetBSD
        let ctagsbins += ['/usr/local/bin/ctags'] " Homebrew
        let ctagsbins += ['/opt/local/bin/ctags'] " Macports
        let ctagsbins += ['ectags'] " OpenBSD
        let ctagsbins += ['ctags']
        let ctagsbins += ['ctags.exe']
        let ctagsbins += ['tags']
        for ctags in ctagsbins
            if executable(ctags)
                let g:tagbar_ctags_bin = ctags
                break
            endif
        endfor
        if !exists('g:tagbar_ctags_bin')
            let errmsg = 'Tagbar: Exuberant ctags not found!'
            let infomsg = 'Please download Exuberant Ctags from' .
                        \ ' ctags.sourceforge.net and install it in a' .
                        \ ' directory in your $PATH or set g:tagbar_ctags_bin.'
            call s:CtagsErrMsg(errmsg, infomsg, a:silent)
            let s:checked_ctags = 2
            return 0
        endif
    else
        let wildignore_save = &wildignore
        set wildignore&

        let g:tagbar_ctags_bin = expand(g:tagbar_ctags_bin)

        let &wildignore = wildignore_save

        if !executable(g:tagbar_ctags_bin)
            let errmsg = "Tagbar: Exuberant ctags not found at '" . g:tagbar_ctags_bin . "'!"
            let infomsg = 'Please check your g:tagbar_ctags_bin setting.'
            call s:CtagsErrMsg(errmsg, infomsg, a:silent)
            let s:checked_ctags = 2
            return 0
        endif
    endif

    let ctags_cmd = s:EscapeCtagsCmd(g:tagbar_ctags_bin, '--version')
    if ctags_cmd == ''
        let s:checked_ctags = 2
        return 0
    endif

    let ctags_output = s:ExecuteCtags(ctags_cmd)

    if v:shell_error || ctags_output !~# '\(Exuberant\|Universal\) Ctags'
        let errmsg = 'Tagbar: Ctags doesn''t seem to be Exuberant Ctags!'
        let infomsg = 'BSD ctags will NOT WORK.' .
            \ ' Please download Exuberant Ctags from ctags.sourceforge.net' .
            \ ' and install it in a directory in your $PATH' .
            \ ' or set g:tagbar_ctags_bin.'
        call s:CtagsErrMsg(errmsg, infomsg, a:silent, ctags_cmd, ctags_output, v:shell_error)
        let s:checked_ctags = 2
        return 0
    elseif !s:CheckExCtagsVersion(ctags_output)
        let errmsg = 'Tagbar: Exuberant Ctags is too old!'
        let infomsg = 'You need at least version 5.5 for Tagbar to work.' .
            \ ' Please download a newer version from ctags.sourceforge.net.'
        call s:CtagsErrMsg(errmsg, infomsg, a:silent, ctags_cmd, ctags_output)
        let s:checked_ctags = 2
        return 0
    else
        let s:checked_ctags = 1
        return 1
    endif
endfunction

function! s:CtagsErrMsg(errmsg, infomsg, silent, ...) abort
    let ctags_cmd    = a:0 > 0 ? a:1 : ''
    let ctags_output = a:0 > 1 ? a:2 : ''

    let exit_code_set = a:0 > 2
    if exit_code_set
        let exit_code = a:3
    endif

    if !a:silent
        call s:warning(a:errmsg)
        echomsg a:infomsg

        if ctags_cmd == ''
            return
        endif

        echomsg 'Executed command: "' . ctags_cmd . '"'
        if ctags_output != ''
            echomsg 'Command output:'
            for line in split(ctags_output, '\n')
                echomsg line
            endfor
        else
            echomsg 'Command output is empty.'
        endif
        if exit_code_set
            echomsg 'Exit code: ' . exit_code
        endif
    endif
endfunction

function! s:CheckExCtagsVersion(output) abort
    if a:output =~ 'Universal Ctags'
        let s:ctags_is_uctags = 1
        return 1
    endif

    if a:output =~ 'Exuberant Ctags Development'
        return 1
    endif

    let matchlist = matchlist(a:output, '\vExuberant Ctags (\d+)\.(\d+)')
    let major     = matchlist[1]
    let minor     = matchlist[2]

    return major >= 6 || (major == 5 && minor >= 5)
endfunction

function! s:CheckFTCtags(bin, ftype) abort
    if executable(a:bin)
        return a:bin
    endif

    if exists('g:tagbar_type_' . a:ftype)
        let userdef = g:tagbar_type_{a:ftype}
        if has_key(userdef, 'ctagsbin')
            return userdef.ctagsbin
        else
            return ''
        endif
    endif

    return ''
endfunction

function! s:GetSupportedFiletypes() abort
    let ctags_cmd = s:EscapeCtagsCmd(g:tagbar_ctags_bin, '--list-languages')
    if ctags_cmd == ''
        return
    endif

    let ctags_output = s:ExecuteCtags(ctags_cmd)

    if v:shell_error
        return
    endif

    let types = split(ctags_output, '\n\+')

    for type in types
        if match(type, '\[disabled\]') == -1
            let s:ctags_types[tolower(type)] = 1
        endif
    endfor

    let s:checked_ctags_types = 1
endfunction

let s:BaseTag = {}

function! s:BaseTag.New(name) abort dict
    let newobj = copy(self)

    call newobj._init(a:name)

    return newobj
endfunction

function! s:BaseTag._init(name) abort dict
    let self.name          = a:name
    let self.fields        = {}
    let self.fields.line   = 0
    let self.fields.column = 0
    let self.prototype     = ''
    let self.path          = ''
    let self.fullpath      = a:name
    let self.depth         = 0
    let self.parent        = {}
    let self.tline         = -1
    let self.fileinfo      = {}
    let self.typeinfo      = {}
endfunction

function! s:BaseTag.isNormalTag() abort dict
    return 0
endfunction

function! s:BaseTag.isPseudoTag() abort dict
    return 0
endfunction

function! s:BaseTag.isKindheader() abort dict
    return 0
endfunction

function! s:BaseTag.getPrototype(short) abort dict
    return self.prototype
endfunction

function! s:BaseTag._getPrefix() abort dict
    let fileinfo = self.fileinfo

    if has_key(self, 'children') && !empty(self.children)
        if fileinfo.tagfolds[self.fields.kind][self.fullpath]
            let prefix = s:icon_closed
        else
            let prefix = s:icon_open
        endif
    else
        let prefix = ' '
    endif
    if g:tagbar_show_visibility
        if has_key(self.fields, 'access')
            let prefix .= get(s:visibility_symbols, self.fields.access, ' ')
        elseif has_key(self.fields, 'file')
            let prefix .= s:visibility_symbols.private
        else
            let prefix .= ' '
        endif
    endif

    return prefix
endfunction

function! s:BaseTag.initFoldState() abort dict
    let fileinfo = self.fileinfo

    if s:known_files.has(fileinfo.fpath) &&
     \ has_key(fileinfo, '_tagfolds_old') &&
     \ has_key(fileinfo._tagfolds_old[self.fields.kind], self.fullpath)
        let fileinfo.tagfolds[self.fields.kind][self.fullpath] = fileinfo._tagfolds_old[self.fields.kind][self.fullpath]
    elseif self.depth >= fileinfo.foldlevel
        let fileinfo.tagfolds[self.fields.kind][self.fullpath] = 1
    else
        let fileinfo.tagfolds[self.fields.kind][self.fullpath] = fileinfo.kindfolds[self.fields.kind]
    endif
endfunction

function! s:BaseTag.getClosedParentTline() abort dict
    let tagline  = self.tline

    let parents   = []
    let curparent = self.parent
    while !empty(curparent)
        call add(parents, curparent)
        let curparent = curparent.parent
    endwhile
    for parent in reverse(parents)
        if parent.isFolded()
            let tagline = parent.tline
            break
        endif
    endfor

    return tagline
endfunction

function! s:BaseTag.isFoldable() abort dict
    return has_key(self, 'children') && !empty(self.children)
endfunction

function! s:BaseTag.isFolded() abort dict
    return self.fileinfo.tagfolds[self.fields.kind][self.fullpath]
endfunction

function! s:BaseTag.openFold() abort dict
    if self.isFoldable()
        let self.fileinfo.tagfolds[self.fields.kind][self.fullpath] = 0
    endif
endfunction

function! s:BaseTag.closeFold() abort dict
    let newline = line('.')

    if !empty(self.parent) && self.parent.isKindheader()
        call self.parent.closeFold()
        let newline = self.parent.tline
    elseif self.isFoldable() && !self.isFolded()
        let self.fileinfo.tagfolds[self.fields.kind][self.fullpath] = 1
        let newline = self.tline
    elseif !empty(self.parent)
        let parent = self.parent
        let self.fileinfo.tagfolds[parent.fields.kind][parent.fullpath] = 1
        let newline = parent.tline
    endif

    return newline
endfunction

function! s:BaseTag.setFolded(folded) abort dict
    let self.fileinfo.tagfolds[self.fields.kind][self.fullpath] = a:folded
endfunction

function! s:BaseTag.openParents() abort dict
    let parent = self.parent

    while !empty(parent)
        call parent.openFold()
        let parent = parent.parent
    endwhile
endfunction

let s:NormalTag = copy(s:BaseTag)

function! s:NormalTag.isNormalTag() abort dict
    return 1
endfunction

function! s:NormalTag.strfmt() abort dict
    let typeinfo = self.typeinfo

    let suffix = get(self.fields, 'signature', '')
    if has_key(self.fields, 'type')
        let suffix .= ' : ' . self.fields.type
    elseif has_key(typeinfo, 'kind2scope') && has_key(typeinfo.kind2scope, self.fields.kind)
        let suffix .= ' : ' . typeinfo.kind2scope[self.fields.kind]
    endif

    return self._getPrefix() . self.name . suffix . "\n"
endfunction

function! s:NormalTag.str(longsig, full) abort dict
    if a:full && self.path != ''
        let str = self.path . self.typeinfo.sro . self.name
    else
        let str = self.name
    endif

    if has_key(self.fields, 'signature')
        if a:longsig
            let str .= self.fields.signature
        else
            let str .= '()'
        endif
    endif

    return str
endfunction

function! s:NormalTag.getPrototype(short) abort dict
    if self.prototype != ''
        let prototype = self.prototype
    else
        let bufnr = self.fileinfo.bufnr

        if self.fields.line == 0 || !bufloaded(bufnr)
            return substitute(self.pattern, '^\\V\\^\\C\s*\(.*\)\\$$', '\1', '')
        endif

        let line = getbufline(bufnr, self.fields.line)[0]
        let list = split(line, '\zs')

        let start = index(list, '(')
        if start == -1
            return substitute(line, '^\s\+', '', '')
        endif

        let opening = count(list, '(', 0, start)
        let closing = count(list, ')', 0, start)
        if closing >= opening
            return substitute(line, '^\s\+', '', '')
        endif

        let balance = opening - closing

        let prototype = line
        let curlinenr = self.fields.line + 1
        while balance > 0
            let curline = getbufline(bufnr, curlinenr)[0]
            let curlist = split(curline, '\zs')
            let balance += count(curlist, '(')
            let balance -= count(curlist, ')')
            let prototype .= "\n" . curline
            let curlinenr += 1
        endwhile

        let self.prototype = prototype
    endif

    if a:short
        let prototype = substitute(prototype, '^\s\+', '', '')
        let prototype = substitute(prototype, '\_s\+', ' ', 'g')
        let prototype = substitute(prototype, '(\s\+', '(', 'g')
        let prototype = substitute(prototype, '\s\+)', ')', 'g')
        let maxlen = &columns - 12
        if len(prototype) > maxlen
            let prototype = prototype[:maxlen - 1 - 3]
            let prototype .= '...'
        endif
    endif

    return prototype
endfunction

let s:PseudoTag = copy(s:BaseTag)

function! s:PseudoTag.isPseudoTag() abort dict
    return 1
endfunction

function! s:PseudoTag.strfmt() abort dict
    let typeinfo = self.typeinfo

    let suffix = get(self.fields, 'signature', '')
    if has_key(typeinfo.kind2scope, self.fields.kind)
        let suffix .= ' : ' . typeinfo.kind2scope[self.fields.kind]
    endif

    return self._getPrefix() . self.name . '*' . suffix
endfunction

let s:KindheaderTag = copy(s:BaseTag)

function! s:KindheaderTag.isKindheader() abort dict
    return 1
endfunction

function! s:KindheaderTag.getPrototype(short) abort dict
    return self.name . ': ' . self.numtags . ' ' . (self.numtags > 1 ? 'tags' : 'tag')
endfunction

function! s:KindheaderTag.isFoldable() abort dict
    return 1
endfunction

function! s:KindheaderTag.isFolded() abort dict
    return self.fileinfo.kindfolds[self.short]
endfunction

function! s:KindheaderTag.openFold() abort dict
    let self.fileinfo.kindfolds[self.short] = 0
endfunction

function! s:KindheaderTag.closeFold() abort dict
    let self.fileinfo.kindfolds[self.short] = 1
    return line('.')
endfunction

function! s:KindheaderTag.toggleFold() abort dict
    let fileinfo = s:TagbarState().getCurrent(0)
    let fileinfo.kindfolds[self.short] = !fileinfo.kindfolds[self.short]
endfunction

let s:TypeInfo = {}

function! s:TypeInfo.New(...) abort dict
    let newobj = copy(self)
    let newobj.kinddict = {}

    if a:0 > 0
        call extend(newobj, a:1)
    endif

    return newobj
endfunction

function! s:TypeInfo.getKind(kind) abort dict
    let idx = self.kinddict[a:kind]
    return self.kinds[idx]
endfunction

function! s:TypeInfo.createKinddict() abort dict
    let i = 0
    for kind in self.kinds
        let self.kinddict[kind.short] = i
        let i += 1
    endfor
endfunction

let s:FileInfo = {}

function! s:FileInfo.New(fname, ftype, typeinfo) abort dict
    let newobj = copy(self)
    let newobj.fpath = a:fname
    let newobj.bufnr = bufnr(a:fname)
    let newobj.mtime = getftime(a:fname)
    let newobj.ftype = a:ftype
    let newobj.tags = []
    let newobj.fline = {}
    let newobj.tline = {}
    let newobj.kindfolds = {}
    let newobj.typeinfo = a:typeinfo
    for kind in a:typeinfo.kinds
        let newobj.kindfolds[kind.short] = g:tagbar_foldlevel == 0 ? 1 : kind.fold
    endfor

    let newobj.tagfolds = {}
    for kind in a:typeinfo.kinds
        let newobj.tagfolds[kind.short] = {}
    endfor

    let newobj.foldlevel = g:tagbar_foldlevel

    return newobj
endfunction

function! s:FileInfo.reset() abort dict
    let self.mtime = getftime(self.fpath)
    let self.tags  = []
    let self.fline = {}
    let self.tline = {}

    let self._tagfolds_old = self.tagfolds
    let self.tagfolds = {}

    for kind in self.typeinfo.kinds
        let self.tagfolds[kind.short] = {}
    endfor
endfunction

function! s:FileInfo.clearOldFolds() abort dict
    if exists('self._tagfolds_old')
        unlet self._tagfolds_old
    endif
endfunction

function! s:FileInfo.sortTags() abort dict
    if get(s:compare_typeinfo, 'sort', g:tagbar_sort)
        call s:SortTags(self.tags, 's:CompareByKind')
    else
        call s:SortTags(self.tags, 's:CompareByLine')
    endif
endfunction

function! s:FileInfo.openKindFold(kind) abort dict
    let self.kindfolds[a:kind.short] = 0
endfunction

function! s:FileInfo.closeKindFold(kind) abort dict
    let self.kindfolds[a:kind.short] = 1
endfunction

let s:state = {'_current': {}, '_paused': {}}

function! s:state.New() abort dict
    return deepcopy(self)
endfunction

function! s:state.getCurrent(forcecurrent) abort dict
    if !s:paused || a:forcecurrent
        return self._current
    else
        return self._paused
    endif
endfunction

function! s:state.setCurrent(fileinfo) abort dict
    let self._current = a:fileinfo
endfunction

function! s:state.setPaused() abort dict
    let self._paused = self._current
endfunction

let s:known_files = {'_files': {}}

function! s:known_files.get(fname) abort dict
    return get(self._files, a:fname, {})
endfunction

function! s:known_files.put(fileinfo, ...) abort dict
    if a:0 == 1
        let self._files[a:1] = a:fileinfo
    else
        let fname = a:fileinfo.fpath
        let self._files[fname] = a:fileinfo
    endif
endfunction

function! s:known_files.has(fname) abort dict
    return has_key(self._files, a:fname)
endfunction

function! s:known_files.rm(fname) abort dict
    if s:known_files.has(a:fname)
        call remove(self._files, a:fname)
    endif
endfunction

function! s:ToggleWindow(flags) abort
    let tagbarwinnr = bufwinnr(s:TagbarBufName())
    if tagbarwinnr != -1
        call s:CloseWindow()
        return
    endif

    call s:OpenWindow(a:flags)
endfunction

function! s:OpenWindow(flags) abort
    let autofocus = a:flags =~# 'f'
    let jump      = a:flags =~# 'j'
    let autoclose = a:flags =~# 'c'

    let curfile = fnamemodify(bufname('%'), ':p')
    let curline = line('.')

    let tagbarwinnr = bufwinnr(s:TagbarBufName())
    if tagbarwinnr != -1
        if winnr() != tagbarwinnr && jump
            call s:goto_win(tagbarwinnr)
            call s:HighlightTag(g:tagbar_autoshowtag != 2, 1, curline)
        endif
        return
    endif

    if exists('*win_getid')
        let prevwinid = win_getid()
        if winnr('$') > 1
            call s:goto_win('p', 1)
            let pprevwinid = win_getid()
            call s:goto_win('p', 1)
        endif
    else
        let prevwinnr = winnr()
        if winnr('$') > 1
            call s:goto_win('p', 1)
            let pprevwinnr = winnr()
            call s:goto_win('p', 1)
        endif
    endif

    let s:last_autofocus = autofocus

    if !s:Init(0)
        return 0
    endif

    if g:tagbar_expand >= 1 && !s:window_expanded && (has('gui_running') || g:tagbar_expand == 2)
        let s:window_pos.pre.x = getwinposx()
        let s:window_pos.pre.y = getwinposy()
        let &columns += g:tagbar_width + 1
        let s:window_pos.post.x = getwinposx()
        let s:window_pos.post.y = getwinposy()
        let s:window_expanded = 1
    endif

    let s:window_opening = 1
    if g:tagbar_vertical == 0
        let mode = 'vertical '
        let openpos = g:tagbar_left ? 'topleft ' : 'botright '
        let width = g:tagbar_width
    else
        let mode = ''
        let openpos = g:tagbar_left ? 'leftabove ' : 'rightbelow '
        let width = g:tagbar_vertical
    endif
    exe 'silent keepalt ' . openpos . mode . width . 'split ' . s:TagbarBufName()
    exe 'silent ' . mode . 'resize ' . width
    unlet s:window_opening

    call s:InitWindow(autoclose)

    if empty(s:known_files.get(curfile))
        call s:known_files.rm(curfile)
    endif

    call s:AutoUpdate(curfile, 0)
    call s:HighlightTag(g:tagbar_autoshowtag != 2, 1, curline)

    if !(g:tagbar_autoclose || autofocus || g:tagbar_autofocus)
        if exists('*win_getid')
            if exists('pprevwinid')
                noautocmd call win_gotoid(pprevwinid)
            endif
            call win_gotoid(prevwinid)
        else
            if winnr() == prevwinnr || (exists('pprevwinnr') && winnr() == pprevwinnr)
                call s:goto_win('p')
            else
                if exists('pprevwinnr')
                    call s:goto_win(pprevwinnr, 1)
                endif
                call s:goto_win(prevwinnr)
            endif
        endif
    endif
endfunction

function! s:InitWindow(autoclose) abort
    setlocal filetype=tagbar
    setlocal noreadonly " in case the "view" mode is used
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nobuflisted
    setlocal nomodifiable
    setlocal textwidth=0

    if has('balloon_eval')
        setlocal balloonexpr=TagbarBalloonExpr()
        set ballooneval
    endif

    setlocal nolist
    setlocal nowrap
    setlocal winfixwidth
    setlocal nospell

    if g:tagbar_show_linenumbers == 0
        setlocal nonumber
        if exists('+relativenumber')
            setlocal norelativenumber
        endif
    elseif g:tagbar_show_linenumbers == 1
        setlocal number
    elseif g:tagbar_show_linenumbers == 2
        setlocal relativenumber
    else
        set number<
        if exists('+relativenumber')
            set relativenumber<
        endif
    endif

    setlocal nofoldenable
    setlocal foldcolumn=0
    setlocal foldmethod&
    setlocal foldexpr&

    let w:autoclose = a:autoclose

    call s:SetStatusLine()

    let s:new_window = 1
    let cpoptions_save = &cpoptions
    set cpoptions&vim

    if !exists('b:tagbar_mapped_keys')
        call s:MapKeys()
    endif

    let &cpoptions = cpoptions_save

    if g:tagbar_expand
        let s:expand_bufnr = bufnr('%')
    endif
endfunction

function! s:CloseWindow() abort
    let tagbarwinnr = bufwinnr(s:TagbarBufName())
    if tagbarwinnr == -1
        return
    endif

    if s:pwin_by_tagbar
        pclose
        let tagbarwinnr = bufwinnr(s:TagbarBufName())
    endif

    if winnr() == tagbarwinnr
        if winbufnr(2) != -1
            let curfile = s:TagbarState().getCurrent(0)

            close

            call s:goto_win('p')

            if !empty(curfile)
                let filebufnr = bufnr(curfile.fpath)

                if bufnr('%') != filebufnr
                    let filewinnr = bufwinnr(filebufnr)
                    if filewinnr != -1
                        call s:goto_win(filewinnr)
                    endif
                endif
            endif
        endif
    else
        call s:mark_window()
        call s:goto_win(tagbarwinnr)
        close

        call s:goto_markedwin()
    endif

    call s:ShrinkIfExpanded()

    if &equalalways
        wincmd =
    endif

    if s:autocommands_done && !s:statusline_in_use
        autocmd! TagbarAutoCmds
        let s:autocommands_done = 0
    endif
endfunction

function! s:ShrinkIfExpanded() abort
    if !s:window_expanded || &filetype == 'tagbar' || s:expand_bufnr == -1
        return
    endif

    let tablist = []
    for i in range(tabpagenr('$'))
        call extend(tablist, tabpagebuflist(i + 1))
    endfor

    if index(tablist, s:expand_bufnr) == -1
        let &columns -= g:tagbar_width + 1
        let s:window_expanded = 0
        let s:expand_bufnr = -1
        if getwinposx() != -1 && getwinposx() == s:window_pos.post.x && getwinposy() == s:window_pos.post.y
           execute 'winpos ' . s:window_pos.pre.x . ' ' . s:window_pos.pre.y
        endif
    endif
endfunction

function! s:ZoomWindow() abort
    if s:is_maximized
        execute 'vertical resize ' . g:tagbar_width
        execute s:winrestcmd
        let s:is_maximized = 0
    else
        let s:winrestcmd = winrestcmd()
        if g:tagbar_zoomwidth == 1
            vertical resize
        elseif g:tagbar_zoomwidth == 0
            let func = exists('*strdisplaywidth') ? 'strdisplaywidth' : 'strlen'
            let maxline = max(map(getline(line('w0'), line('w$')), func . '(v:val)'))
            execute 'vertical resize ' . maxline
        elseif g:tagbar_zoomwidth > 1
            execute 'vertical resize ' . g:tagbar_zoomwidth
        endif
        let s:is_maximized = 1
    endif
endfunction

function! s:CorrectFocusOnStartup() abort
    if bufwinnr(s:TagbarBufName()) != -1 && !g:tagbar_autofocus && !s:last_autofocus
        let curfile = s:TagbarState().getCurrent(1)
        if !empty(curfile) && curfile.fpath != fnamemodify(bufname('%'), ':p')
            let winnr = bufwinnr(curfile.fpath)
            if winnr != -1
                call s:goto_win(winnr)
            endif
        endif
    endif
endfunction

function! s:ProcessFile(fname, ftype) abort
    if !s:IsValidFile(a:fname, a:ftype)
        return
    endif

    let typeinfo = s:known_types[a:ftype]

    if s:known_files.has(a:fname) && !empty(s:known_files.get(a:fname)) && s:known_files.get(a:fname).ftype == a:ftype
        let fileinfo = s:known_files.get(a:fname)
        let typeinfo = fileinfo.typeinfo
        call fileinfo.reset()
    else
        if exists('#TagbarProjects#User')
            execute 'doautocmd <nomodeline> TagbarProjects User ' . a:fname
            if exists('b:tagbar_type')
                let typeinfo = extend(copy(typeinfo), s:TransformUserTypeDef(b:tagbar_type))
                call typeinfo.createKinddict()
            endif
        endif
        let fileinfo = s:FileInfo.New(a:fname, a:ftype, typeinfo)
    endif

    let tempfile = tempname()
    let ext = fnamemodify(fileinfo.fpath, ':e')
    if ext != ''
        let tempfile .= '.' . ext
    endif

    call writefile(getbufline(fileinfo.bufnr, 1, '$'), tempfile)
    let fileinfo.mtime = getftime(tempfile)

    let ctags_output = s:ExecuteCtagsOnFile(tempfile, a:fname, typeinfo)

    call delete(tempfile)

    if ctags_output == -1
        call s:known_files.put({}, a:fname)
        return
    elseif ctags_output == ''
        call s:known_files.put(s:FileInfo.New(a:fname, a:ftype, s:known_types[a:ftype]), a:fname)
        return
    endif

    let rawtaglist = split(ctags_output, '\n\+')
    for line in rawtaglist
        if line =~# '^!_TAG_'
            continue
        endif

        let parts = split(line, ';"')
        if len(parts) == 2 " Is a valid tag line
            let taginfo = s:ParseTagline(parts[0], parts[1], typeinfo, fileinfo)
            if !empty(taginfo)
                let fileinfo.fline[taginfo.fields.line] = taginfo
                call add(fileinfo.tags, taginfo)
            endif
        endif
    endfor

    let processedtags = []
    if has_key(typeinfo, 'kind2scope')
        let scopedtags = []
        let is_scoped = 'has_key(typeinfo.kind2scope, v:val.fields.kind) ||
                       \ has_key(v:val, "scope")'
        let scopedtags += filter(copy(fileinfo.tags), is_scoped)
        call filter(fileinfo.tags, '!(' . is_scoped . ')')

        call s:AddScopedTags(scopedtags, processedtags, {}, 0, typeinfo, fileinfo, line('$'))

        if !empty(scopedtags)
            echoerr 'Tagbar: ''scopedtags'' not empty after processing,'
                  \ 'this should never happen!'
                  \ 'Please contact the script maintainer with an example.'
        endif
    endif

    for kind in typeinfo.kinds

        let curtags = filter(copy(fileinfo.tags), 'v:val.fields.kind ==# kind.short')

        if empty(curtags)
            continue
        endif

        let kindtag          = s:KindheaderTag.New(kind.long)
        let kindtag.short    = kind.short
        let kindtag.numtags  = len(curtags)
        let kindtag.fileinfo = fileinfo

        for tag in curtags
            let tag.parent = kindtag
        endfor
    endfor

    if !empty(processedtags)
        call extend(fileinfo.tags, processedtags)
    endif

    call fileinfo.clearOldFolds()

    let s:compare_typeinfo = typeinfo
    call fileinfo.sortTags()

    call s:known_files.put(fileinfo)
endfunction

function! s:ExecuteCtagsOnFile(fname, realfname, typeinfo) abort
    if has_key(a:typeinfo, 'ctagsargs') && type(a:typeinfo.ctagsargs) == type('')
        let ctags_args = ' ' . a:typeinfo.ctagsargs . ' '
    elseif has_key(a:typeinfo, 'ctagsargs') && type(a:typeinfo.ctagsargs) == type([])
        let ctags_args = a:typeinfo.ctagsargs
    else
        let ctags_args  = [ '-f',
                          \ '-',
                          \ '--format=2',
                          \ '--excmd=pattern',
                          \ '--fields=nksSaf',
                          \ '--extra=',
                          \ '--file-scope=yes',
                          \ '--sort=no',
                          \ '--append=no'
                          \ ]

        if has_key(a:typeinfo, 'deffile')
            let ctags_args += ['--options=' . expand(a:typeinfo.deffile)]
        endif

        if has_key(a:typeinfo, 'ctagstype')
            let ctags_type = a:typeinfo.ctagstype

            let ctags_kinds = ''
            for kind in a:typeinfo.kinds
                let ctags_kinds .= kind.short
            endfor

            let ctags_args += ['--language-force=' . ctags_type]
            let ctags_args += ['--' . ctags_type . '-kinds=' . ctags_kinds]
        endif
    endif

    if has_key(a:typeinfo, 'ctagsbin')
        let wildignore_save = &wildignore
        set wildignore&
        let ctags_bin = expand(a:typeinfo.ctagsbin)
        let &wildignore = wildignore_save
    else
        let ctags_bin = g:tagbar_ctags_bin
    endif

    let ctags_cmd = s:EscapeCtagsCmd(ctags_bin, ctags_args, a:fname)
    if ctags_cmd == ''
        return ''
    endif

    let ctags_output = s:ExecuteCtags(ctags_cmd)

    if v:shell_error || ctags_output =~ 'Warning: cannot open source file'
        if bufwinnr(s:TagbarBufName()) != -1 && (!s:known_files.has(a:realfname) || !empty(s:known_files.get(a:realfname)))
            call s:warning('Tagbar: Could not execute ctags for ' . a:realfname . '!')
            echomsg 'Executed command: "' . ctags_cmd . '"'
            if !empty(ctags_output)
                echomsg 'Command output:'
                for line in split(ctags_output, '\n')
                    echomsg line
                endfor
            endif
            echomsg 'Exit code: ' . v:shell_error
        endif
        return -1
    endif
    return ctags_output
endfunction

function! s:ParseTagline(part1, part2, typeinfo, fileinfo) abort
    let basic_info  = split(a:part1, '\t')

    let taginfo      = s:NormalTag.New(basic_info[0])
    let taginfo.file = basic_info[1]

    let pattern = join(basic_info[2:], "\t")
    let start   = 2 " skip the slash and the ^
    let end     = strlen(pattern) - 1
    if pattern[end - 1] ==# '$'
        let end -= 1
        let dollar = '\$'
    else
        let dollar = ''
    endif
    let pattern         = strpart(pattern, start, end - start)
    let taginfo.pattern = '\V\^\C' . pattern . dollar

    let fields = split(a:part2, '^\t\|\t\ze\w\+:')
    if fields[0] !~# ':'
        let taginfo.fields.kind = remove(fields, 0)
    endif
    for field in fields
        let delimit = stridx(field, ':')
        let key = strpart(field, 0, delimit)
        let val = substitute(strpart(field, delimit + 1), '\t', '', 'g')
        if key == "file"
            let taginfo.fields[key] = 'yes'
        endif
        if len(val) > 0
            if key == 'line' || key == 'column'
                let taginfo.fields[key] = str2nr(val)
            else
                let taginfo.fields[key] = val
            endif
        endif
    endfor
    if has_key(taginfo.fields, 'lineno')
        let taginfo.fields.line = str2nr(taginfo.fields.lineno)
    endif
    if taginfo.fields.line < 0
        let taginfo.fields.line = 0
    endif

    if !has_key(taginfo.fields, 'kind')
        if index(s:warnings.type, a:typeinfo.ftype) == -1
            call s:warning("No 'kind' field found for tag " . basic_info[0] . "!" . " Please read the last section of ':help tagbar-extend'.")
            call add(s:warnings.type, a:typeinfo.ftype)
        endif
        return {}
    endif

    if has_key(a:typeinfo, 'scope2kind')
        for scope in keys(a:typeinfo.scope2kind)
            if has_key(taginfo.fields, scope)
                let taginfo.scope = scope
                let taginfo.path  = taginfo.fields[scope]

                let taginfo.fullpath = taginfo.path . a:typeinfo.sro . taginfo.name
                break
            endif
        endfor
        let taginfo.depth = len(split(taginfo.path, '\V' . a:typeinfo.sro))
    endif

    let taginfo.fileinfo = a:fileinfo
    let taginfo.typeinfo = a:typeinfo

    try
        call taginfo.initFoldState()
    catch /^Vim(\a\+):E716:/ 
        if index(s:warnings.type, a:typeinfo.ftype) == -1
            call s:warning('Unknown tag kind encountered: ' .
                \ '"' . taginfo.fields.kind . '".' .
                \ ' Your ctags and Tagbar configurations are out of sync!' .
                \ ' Please read '':help tagbar-extend''.')
            call add(s:warnings.type, a:typeinfo.ftype)
        endif
        return {}
    endtry

    return taginfo
endfunction

function! s:AddScopedTags(tags, processedtags, parent, depth, typeinfo, fileinfo, maxline) abort
    if !empty(a:parent)
        let curpath = a:parent.fullpath
        let pscope  = a:typeinfo.kind2scope[a:parent.fields.kind]
    else
        let curpath = ''
        let pscope  = ''
    endif

    let is_cur_tag = 'v:val.depth == a:depth'

    if !empty(curpath)
        let is_cur_tag .= ' &&
        \ (v:val.path ==# curpath ||
         \ match(v:val.path, ''\V\^\C'' . curpath . a:typeinfo.sro) == 0) &&
        \ (v:val.path ==# curpath ? (v:val.scope ==# pscope) : 1) &&
        \ v:val.fields.line >= a:parent.fields.line &&
        \ v:val.fields.line <= a:maxline'
    endif

    let curtags = filter(copy(a:tags), is_cur_tag)

    if !empty(curtags)
        call filter(a:tags, '!(' . is_cur_tag . ')')

        let realtags   = []
        let pseudotags = []

        while !empty(curtags)
            let tag = remove(curtags, 0)

            if tag.path != curpath
                let pseudotag = s:ProcessPseudoTag(curtags, tag, a:parent, a:typeinfo, a:fileinfo)

                call add(pseudotags, pseudotag)
            else
                call add(realtags, tag)
            endif
        endwhile

        for tag in realtags
            let tag.parent = a:parent

            if !has_key(a:typeinfo.kind2scope, tag.fields.kind)
                continue
            endif

            if !has_key(tag, 'children')
                let tag.children = []
            endif

            let twins = filter(copy(realtags),
                             \ "v:val.fullpath ==# '" .
                             \ substitute(tag.fullpath, "'", "''", 'g') . "'" .
                             \ " && v:val.fields.line != " . tag.fields.line)
            let maxline = line('$')
            for twin in twins
                if twin.fields.line <= maxline && twin.fields.line > tag.fields.line
                    let maxline = twin.fields.line - 1
                endif
            endfor

            call s:AddScopedTags(a:tags, tag.children, tag, a:depth + 1, a:typeinfo, a:fileinfo, maxline)
        endfor
        call extend(a:processedtags, realtags)

        for tag in pseudotags
            call s:ProcessPseudoChildren(a:tags, tag, a:depth, a:typeinfo, a:fileinfo)
        endfor
        call extend(a:processedtags, pseudotags)
    endif

    let is_grandchild = 'v:val.depth > a:depth'

    if !empty(curpath)
        let is_grandchild .= ' && match(v:val.path, ''\V\^\C'' . curpath . a:typeinfo.sro) == 0'
    endif

    let grandchildren = filter(copy(a:tags), is_grandchild)

    if !empty(grandchildren)
        call s:AddScopedTags(a:tags, a:processedtags, a:parent, a:depth + 1, a:typeinfo, a:fileinfo, a:maxline)
    endif
endfunction

function! s:ProcessPseudoTag(curtags, tag, parent, typeinfo, fileinfo) abort
    let curpath = !empty(a:parent) ? a:parent.fullpath : ''

    let pseudoname = substitute(a:tag.path, curpath, '', '')
    let pseudoname = substitute(pseudoname, '\V\^' . a:typeinfo.sro, '', '')
    let pseudotag  = s:CreatePseudoTag(pseudoname, a:parent, a:tag.scope, a:typeinfo, a:fileinfo)
    let pseudotag.children = [a:tag]

    let ispseudochild = 'v:val.path ==# a:tag.path && v:val.scope ==# a:tag.scope'
    let pseudochildren = filter(copy(a:curtags), ispseudochild)
    if !empty(pseudochildren)
        call filter(a:curtags, '!(' . ispseudochild . ')')
        call extend(pseudotag.children, pseudochildren)
    endif

    return pseudotag
endfunction

function! s:ProcessPseudoChildren(tags, tag, depth, typeinfo, fileinfo) abort
    for childtag in a:tag.children
        let childtag.parent = a:tag

        if !has_key(a:typeinfo.kind2scope, childtag.fields.kind)
            continue
        endif

        if !has_key(childtag, 'children')
            let childtag.children = []
        endif

        call s:AddScopedTags(a:tags, childtag.children, childtag, a:depth + 1, a:typeinfo, a:fileinfo, line('$'))
    endfor

    let is_grandchild = 'v:val.depth > a:depth && ' .
            \ 'match(v:val.path,' .
            \ '''^\C'' . substitute(a:tag.fullpath, "''", "''''", "g")) == 0'
    let grandchildren = filter(copy(a:tags), is_grandchild)
    if !empty(grandchildren)
        call s:AddScopedTags(a:tags, a:tag.children, a:tag, a:depth + 1, a:typeinfo, a:fileinfo, line('$'))
    endif
endfunction

function! s:CreatePseudoTag(name, parent, scope, typeinfo, fileinfo) abort
    if !empty(a:parent)
        let curpath = a:parent.fullpath
        let pscope  = a:typeinfo.kind2scope[a:parent.fields.kind]
    else
        let curpath = ''
        let pscope  = ''
    endif

    let pseudotag             = s:PseudoTag.New(a:name)
    let pseudotag.fields.kind = a:typeinfo.scope2kind[a:scope]

    let parentscope = substitute(curpath, a:name . '$', '', '')
    let parentscope = substitute(parentscope, '\V\^' . a:typeinfo.sro . '\$', '', '')

    if pscope != ''
        let pseudotag.fields[pscope] = parentscope
        let pseudotag.scope    = pscope
        let pseudotag.path     = parentscope
        let pseudotag.fullpath = pseudotag.path . a:typeinfo.sro . pseudotag.name
    endif
    let pseudotag.depth = len(split(pseudotag.path, '\V' . a:typeinfo.sro))

    let pseudotag.parent = a:parent

    let pseudotag.fileinfo = a:fileinfo
    let pseudotag.typeinfo = a:typeinfo

    call pseudotag.initFoldState()

    return pseudotag
endfunction

function! s:SortTags(tags, comparemethod) abort
    call sort(a:tags, a:comparemethod)

    for tag in a:tags
        if has_key(tag, 'children')
            call s:SortTags(tag.children, a:comparemethod)
        endif
    endfor
endfunction

function! s:CompareByKind(tag1, tag2) abort
    let typeinfo = s:compare_typeinfo

    if typeinfo.kinddict[a:tag1.fields.kind] <# typeinfo.kinddict[a:tag2.fields.kind]
        return -1
    elseif typeinfo.kinddict[a:tag1.fields.kind] ># typeinfo.kinddict[a:tag2.fields.kind]
        return 1
    else
        if a:tag1.name[0] ==# '~'
            let name1 = a:tag1.name[1:]
        else
            let name1 = a:tag1.name
        endif
        if a:tag2.name[0] ==# '~'
            let name2 = a:tag2.name[1:]
        else
            let name2 = a:tag2.name
        endif

        let ci = g:tagbar_case_insensitive
        if (((!ci) && (name1 <=# name2)) || (ci && (name1 <=? name2)))
            return -1
        else
            return 1
        endif
    endif
endfunction

function! s:CompareByLine(tag1, tag2) abort
    return a:tag1.fields.line - a:tag2.fields.line
endfunction

function! s:ToggleSort() abort
    let fileinfo = s:TagbarState().getCurrent(0)
    if empty(fileinfo)
        return
    endif

    let curline = line('.')
    let taginfo = s:GetTagInfo(curline, 0)

    match none

    let s:compare_typeinfo = s:known_types[fileinfo.ftype]

    if has_key(s:compare_typeinfo, 'sort')
        let s:compare_typeinfo.sort = !s:compare_typeinfo.sort
    else
        let g:tagbar_sort = !g:tagbar_sort
    endif

    call fileinfo.sortTags()

    call s:RenderContent()
    call s:SetStatusLine()

    if !empty(taginfo)
        execute taginfo.tline
    else
        execute curline
    endif
endfunction

function! s:RenderContent(...) abort
    let s:new_window = 0

    if a:0 == 1
        let fileinfo = a:1
    else
        let fileinfo = s:TagbarState().getCurrent(0)
    endif

    if empty(fileinfo)
        return
    endif

    let tagbarwinnr = bufwinnr(s:TagbarBufName())

    if &filetype == 'tagbar'
        let in_tagbar = 1
    else
        let in_tagbar = 0
        let prevwinnr = winnr()

        call s:goto_win('p', 1)
        let pprevwinnr = winnr()
        call s:goto_win(tagbarwinnr, 1)
    endif

    if !empty(s:TagbarState().getCurrent(0)) && fileinfo.fpath ==# s:TagbarState().getCurrent(0).fpath
        let saveline = line('.')
        let savecol  = col('.')
        let topline  = line('w0')
    endif

    let lazyredraw_save = &lazyredraw
    set lazyredraw
    let eventignore_save = &eventignore
    set eventignore=all

    setlocal modifiable

    silent %delete _

    call s:PrintHelp()

    let typeinfo = fileinfo.typeinfo

    if !empty(fileinfo.tags)
        call s:PrintKinds(typeinfo, fileinfo)
    else
        if g:tagbar_compact && s:short_help
            silent 0put ='\" No tags found.'
        else
            silent  put ='\" No tags found.'
        endif
    endif

    for linenr in range(line('$'), 1, -1)
        if getline(linenr) =~ '^$'
            execute 'silent ' . linenr . 'delete _'
        else
            break
        endif
    endfor

    setlocal nomodifiable

    if !empty(s:TagbarState().getCurrent(0)) && fileinfo.fpath ==# s:TagbarState().getCurrent(0).fpath
        let scrolloff_save = &scrolloff
        set scrolloff=0

        call cursor(topline, 1)
        normal! zt
        call cursor(saveline, savecol)

        let &scrolloff = scrolloff_save
    else
        execute 1
        call winline()

        let s:last_highlight_tline = 0
    endif

    let &lazyredraw  = lazyredraw_save
    let &eventignore = eventignore_save

    if !in_tagbar
        call s:goto_win(pprevwinnr, 1)
        call s:goto_win(prevwinnr, 1)
    endif
endfunction

function! s:PrintKinds(typeinfo, fileinfo) abort
    let is_first_tag = 1

    for kind in a:typeinfo.kinds
        let curtags = filter(copy(a:fileinfo.tags), 'v:val.fields.kind ==# kind.short')

        if empty(curtags)
            continue
        endif

        if has_key(a:typeinfo, 'kind2scope') && has_key(a:typeinfo.kind2scope, kind.short)
            for tag in curtags
                call s:PrintTag(tag, 0, is_first_tag, a:fileinfo, a:typeinfo)

                if !g:tagbar_compact
                    silent put _
                endif

                let is_first_tag = 0
            endfor
        else
            let kindtag = curtags[0].parent

            if kindtag.isFolded()
                let foldmarker = s:icon_closed
            else
                let foldmarker = s:icon_open
            endif

            let padding = g:tagbar_show_visibility ? ' ' : ''
            if g:tagbar_compact && is_first_tag && s:short_help
                silent 0put =foldmarker . padding . kind.long
            else
                silent  put =foldmarker . padding . kind.long
            endif

            let curline                   = line('.')
            let kindtag.tline             = curline
            let a:fileinfo.tline[curline] = kindtag

            if !kindtag.isFolded()
                for tag in curtags
                    let str = tag.strfmt()
                    silent put =repeat(' ', g:tagbar_indent) . str

                    let curline                   = line('.')
                    let tag.tline                 = curline
                    let a:fileinfo.tline[curline] = tag
                    let tag.depth                 = 1
                endfor
            endif

            if !g:tagbar_compact
                silent put _
            endif

            let is_first_tag = 0
        endif
    endfor
endfunction

function! s:PrintTag(tag, depth, is_first, fileinfo, typeinfo) abort
    if g:tagbar_hide_nonpublic && get(a:tag.fields, 'access', 'public') !=# 'public'
        let a:tag.tline = -1
        return
    endif

    let tagstr = repeat(' ', a:depth * g:tagbar_indent) . a:tag.strfmt()
    if a:is_first && g:tagbar_compact && s:short_help
        silent 0put =tagstr
    else
        silent  put =tagstr
    endif

    let curline                   = line('.')
    let a:tag.tline               = curline
    let a:fileinfo.tline[curline] = a:tag

    if a:tag.isFoldable() && !a:tag.isFolded()
        for ckind in a:typeinfo.kinds
            let childfilter = 'v:val.fields.kind ==# ckind.short'
            if g:tagbar_hide_nonpublic
                let childfilter .= ' && get(v:val.fields, "access", "public") ==# "public"'
            endif
            let childtags = filter(copy(a:tag.children), childfilter)
            if len(childtags) > 0
                if !has_key(a:typeinfo.kind2scope, ckind.short)
                    let indent  = (a:depth + 1) * g:tagbar_indent
                    let indent += g:tagbar_show_visibility
                    let indent += 1 " fold symbol
                    silent put =repeat(' ', indent) . '[' . ckind.long . ']'
                    let headertag = s:BaseTag.New(ckind.long)
                    let headertag.parent = a:tag
                    let headertag.fileinfo = a:tag.fileinfo
                    let a:fileinfo.tline[line('.')] = headertag
                endif
                for childtag in childtags
                    call s:PrintTag(childtag, a:depth + 1, 0, a:fileinfo, a:typeinfo)
                endfor
            endif
        endfor
    endif
endfunction

function! s:PrintHelp() abort
    if !g:tagbar_compact && s:short_help
        silent 0put ='\" Press ' . s:get_map_str('help') . ' for help'
        silent  put _
    elseif !s:short_help
        silent 0put ='\" Tagbar keybindings'
        silent  put ='\"'
        silent  put ='\" --------- General ---------'
        silent  put ='\" ' . s:get_map_str('jump') . ': Jump to tag definition'
        silent  put ='\" ' . s:get_map_str('preview') . ': As above, but stay in'
        silent  put ='\"    Tagbar window'
        silent  put ='\" ' . s:get_map_str('previewwin') . ': Show tag in preview window'
        silent  put ='\" ' . s:get_map_str('nexttag') . ': Go to next top-level tag'
        silent  put ='\" ' . s:get_map_str('prevtag') . ': Go to previous top-level tag'
        silent  put ='\" ' . s:get_map_str('showproto') . ': Display tag prototype'
        silent  put ='\" ' . s:get_map_str('hidenonpublic') . ': Hide non-public tags'
        silent  put ='\"'
        silent  put ='\" ---------- Folds ----------'
        silent  put ='\" ' . s:get_map_str('openfold') . ': Open fold'
        silent  put ='\" ' . s:get_map_str('closefold') . ': Close fold'
        silent  put ='\" ' . s:get_map_str('togglefold') . ': Toggle fold'
        silent  put ='\" ' . s:get_map_str('openallfolds') . ': Open all folds'
        silent  put ='\" ' . s:get_map_str('closeallfolds') . ': Close all folds'
        silent  put ='\" ' . s:get_map_str('nextfold') . ': Go to next fold'
        silent  put ='\" ' . s:get_map_str('prevfold') . ': Go to previous fold'
        silent  put ='\"'
        silent  put ='\" ---------- Misc -----------'
        silent  put ='\" ' . s:get_map_str('togglesort') . ': Toggle sort'
        silent  put ='\" ' . s:get_map_str('togglecaseinsensitive') . ': Toggle case insensitive sort option'
        silent  put ='\" ' . s:get_map_str('toggleautoclose') . ': Toggle autoclose option'
        silent  put ='\" ' . s:get_map_str('zoomwin') . ': Zoom window in/out'
        silent  put ='\" ' . s:get_map_str('close') . ': Close window'
        silent  put ='\" ' . s:get_map_str('help') . ': Toggle help'
        silent  put _
    endif
endfunction

function! s:get_map_str(map) abort
    let def = get(g:, 'tagbar_map_' . a:map)
    if type(def) == type("")
        return def
    else
        return join(def, ', ')
    endif
endfunction

function! s:RenderKeepView(...) abort
    if a:0 == 1
        let line = a:1
    else
        let line = line('.')
    endif

    let curcol  = col('.')
    let topline = line('w0')

    call s:RenderContent()

    let scrolloff_save = &scrolloff
    set scrolloff=0

    call cursor(topline, 1)
    normal! zt
    call cursor(line, curcol)

    let &scrolloff = scrolloff_save

    redraw
endfunction

function! s:HighlightTag(openfolds, ...) abort
    let tagline = 0

    let force = a:0 > 0 ? a:1 : 0

    if a:0 > 1
        let tag = s:GetNearbyTag(1, 0, a:2)
    else
        let tag = s:GetNearbyTag(1, 0)
    endif
    if !empty(tag)
        let tagline = tag.tline
    endif

    if !force && tagline == s:last_highlight_tline
        return
    else
        let s:last_highlight_tline = tagline
    endif

    let tagbarwinnr = bufwinnr(s:TagbarBufName())
    if tagbarwinnr == -1
        return
    endif

    if tagbarwinnr == winnr()
        let in_tagbar = 1
    else
        let in_tagbar = 0
        let prevwinnr = winnr()
        call s:goto_win('p', 1)
        let pprevwinnr = winnr()
        call s:goto_win(tagbarwinnr, 1)
    endif

    try
        match none

        if tagline == 0
            return
        endif

        if g:tagbar_autoshowtag == 1 || a:openfolds
            call s:OpenParents(tag)
        endif

        let tagline = tag.getClosedParentTline()

        if tagline <= 0
            return
        endif

        execute tagline

        call winline()

        let foldpat = '[' . s:icon_open . s:icon_closed . ' ]'
        let pattern = '/^\%' . tagline . 'l\s*' . foldpat . '[-+# ]\zs[^( ]\+\ze/'
        if hlexists('TagbarHighlight') " Safeguard in case syntax highlighting is disabled
            execute 'match TagbarHighlight ' . pattern
        else
            execute 'match Search ' . pattern
        endif
    finally
        if !in_tagbar
            call s:goto_win(pprevwinnr, 1)
            call s:goto_win(prevwinnr, 1)
        endif
        redraw
    endtry
endfunction

function! s:JumpToTag(stay_in_tagbar) abort
    let taginfo = s:GetTagInfo(line('.'), 1)

    let autoclose = w:autoclose

    if empty(taginfo) || !taginfo.isNormalTag()
        return
    endif

    let tagbarwinnr = winnr()

    call s:GotoFileWindow(taginfo.fileinfo)
    mark '

    execute taginfo.fields.line

    if match(getline('.'), taginfo.pattern) == -1
        let interval = 1
        let forward  = 1
        while search(taginfo.pattern, 'W' . forward ? '' : 'b') == 0
            if !forward
                if interval > line('$')
                    break
                else
                    let interval = interval * 2
                endif
            endif
            let forward = !forward
        endwhile
    endif

    let curline = line('.')
    if taginfo.fields.line != curline
        let taginfo.fields.line = curline
        let taginfo.fileinfo.fline[curline] = taginfo
    endif

    normal! z.
    if taginfo.fields.column > 0
        call cursor(taginfo.fields.line, taginfo.fields.column)
    else
        call cursor(taginfo.fields.line, 1)
        call search(taginfo.name, 'c', line('.'))
    endif

    normal! zv

    if a:stay_in_tagbar
        call s:HighlightTag(0)
        call s:goto_win(tagbarwinnr)
        redraw
    elseif g:tagbar_autoclose || autoclose
        call s:CloseWindow()
    else
        if s:pwin_by_tagbar
            pclose
        endif
        call s:HighlightTag(0)
    endif
endfunction

function! s:ShowInPreviewWin() abort
    let pos = getpos('.')
    let taginfo = s:GetTagInfo(pos[1], 1)

    if empty(taginfo) || !taginfo.isNormalTag()
        return
    endif

    let pwin_open = 0
    for win in range(1, winnr('$'))
        if getwinvar(win, '&previewwindow')
            let pwin_open = 1
            break
        endif
    endfor

    if g:tagbar_vertical == 0
        call s:GotoFileWindow(taginfo.fileinfo, 1)
        call s:mark_window()
    endif

    if !pwin_open
        silent execute g:tagbar_previewwin_pos . ' pedit ' . fnameescape(taginfo.fileinfo.fpath)
        if g:tagbar_vertical != 0
            silent execute 'vertical resize ' . g:tagbar_width
        endif
        let s:pwin_by_tagbar = 1
    endif

    if g:tagbar_vertical != 0
        call s:GotoFileWindow(taginfo.fileinfo, 1)
        call s:mark_window()
    endif

    let include_save = &include
    set include=
    silent! execute taginfo.fields.line . ',$psearch! /' . taginfo.pattern . '/'
    let &include = include_save

    call s:goto_win('P', 1)
    normal! zv
    normal! zz
    call s:goto_markedwin(1)
    call s:goto_tagbar(1)
    call cursor(pos[1], pos[2])
endfunction

function! s:ShowPrototype(short) abort
    let taginfo = s:GetTagInfo(line('.'), 1)

    if empty(taginfo)
        return ''
    endif

    echo taginfo.getPrototype(a:short)
endfunction

function! s:ToggleHelp() abort
    let s:short_help = !s:short_help

    match none

    call s:RenderContent()

    execute 1
    redraw
endfunction

function! s:GotoNextToplevelTag(direction) abort
    let curlinenr = line('.')
    let newlinenr = line('.')

    if a:direction == 1
        let range = range(line('.') + 1, line('$'))
    else
        let range = range(line('.') - 1, 1, -1)
    endif

    for tmplinenr in range
        let taginfo = s:GetTagInfo(tmplinenr, 0)

        if empty(taginfo)
            continue
        elseif empty(taginfo.parent)
            let newlinenr = tmplinenr
            break
        endif
    endfor

    if curlinenr != newlinenr
        execute newlinenr
        call winline()
    endif

    redraw
endfunction

function! s:OpenFold() abort
    let fileinfo = s:TagbarState().getCurrent(0)
    if empty(fileinfo)
        return
    endif

    let curline = line('.')

    let tag = s:GetTagInfo(curline, 0)
    if empty(tag)
        return
    endif

    call tag.openFold()

    call s:RenderKeepView()
endfunction

function! s:CloseFold() abort
    let fileinfo = s:TagbarState().getCurrent(0)
    if empty(fileinfo)
        return
    endif

    match none

    let curline = line('.')

    let curtag = s:GetTagInfo(curline, 0)
    if empty(curtag)
        return
    endif

    let newline = curtag.closeFold()

    call s:RenderKeepView(newline)
endfunction

function! s:ToggleFold() abort
    let fileinfo = s:TagbarState().getCurrent(0)
    if empty(fileinfo)
        return
    endif

    match none

    let curtag = s:GetTagInfo(line('.'), 0)
    if empty(curtag)
        return
    endif

    let newline = line('.')

    if curtag.isKindheader()
        call curtag.toggleFold()
    elseif curtag.isFoldable()
        if curtag.isFolded()
            call curtag.openFold()
        else
            let newline = curtag.closeFold()
        endif
    else
        let newline = curtag.closeFold()
    endif

    call s:RenderKeepView(newline)
endfunction

function! s:SetFoldLevel(level, force) abort
    if a:level < 0
        call s:warning('Foldlevel can''t be negative')
        return
    endif

    let fileinfo = s:TagbarState().getCurrent(0)
    if empty(fileinfo)
        return
    endif

    call s:SetFoldLevelRecursive(fileinfo, fileinfo.tags, a:level)

    let typeinfo = fileinfo.typeinfo

    if a:level == 0
        for kind in typeinfo.kinds
            call fileinfo.closeKindFold(kind)
        endfor
    else
        for kind in typeinfo.kinds
            if a:force || !kind.fold
                call fileinfo.openKindFold(kind)
            endif
        endfor
    endif

    let fileinfo.foldlevel = a:level

    call s:RenderContent()
endfunction

function! s:SetFoldLevelRecursive(fileinfo, tags, level) abort
    for tag in a:tags
        if tag.depth >= a:level
            call tag.setFolded(1)
        else
            call tag.setFolded(0)
        endif

        if has_key(tag, 'children')
            call s:SetFoldLevelRecursive(a:fileinfo, tag.children, a:level)
        endif
    endfor
endfunction

function! s:OpenParents(...) abort
    if a:0 == 1
        let tag = a:1
    else
        let tag = s:GetNearbyTag(1, 0)
    endif

    if !empty(tag)
        call tag.openParents()
        call s:RenderKeepView()
    endif
endfunction

function! s:GotoNextFold() abort
    let curlinenr = line('.')
    let newlinenr = line('.')

    let range = range(line('.') + 1, line('$'))

    for linenr in range
        let taginfo = s:GetTagInfo(linenr, 0)

        if empty(taginfo)
            continue
        elseif !empty(get(taginfo, 'children', [])) || taginfo.isKindheader()
            let newlinenr = linenr
            break
        endif
    endfor

    if curlinenr != newlinenr
        execute linenr
        call winline()
    endif

    redraw
endfunction

function! s:GotoPrevFold() abort
    let curlinenr = line('.')
    let newlinenr = line('.')
    let curtag = s:GetTagInfo(curlinenr, 0)
    let curparent = get(curtag, 'parent', {})

    let range = range(line('.') - 1, 1, -1)

    for linenr in range
        let taginfo = s:GetTagInfo(linenr, 0)

        if empty(taginfo)
            continue
        elseif (!empty(taginfo.parent) && taginfo.parent != curparent &&
              \ empty(get(taginfo, 'children', []))) ||
             \ ((!empty(get(taginfo, 'children', [])) || taginfo.isKindheader()) &&
              \ taginfo.isFolded())
            let newlinenr = linenr
            break
        endif
    endfor

    if curlinenr != newlinenr
        execute linenr
        call winline()
    endif

    redraw
endfunction

function! s:AutoUpdate(fname, force) abort
    if exists('s:tagbar_qf_active')
        return
    elseif exists('s:window_opening')
        return
    endif

    let bufnr = bufnr(a:fname)
    let ftype = getbufvar(bufnr, '&filetype')

    if ftype == 'tagbar'
        return
    endif

    let sftype = get(split(ftype, '\.'), 0, '')
    if !s:IsValidFile(a:fname, sftype)
        let s:nearby_disabled = 1
        return
    endif

    let updated = 0

    if s:known_files.has(a:fname)
        let curfile = s:known_files.get(a:fname)
        " if a:force || getbufvar(curfile.bufnr, '&modified') ||
        if a:force || empty(curfile) || curfile.ftype != sftype || (filereadable(a:fname) && getftime(a:fname) > curfile.mtime)
            call s:ProcessFile(a:fname, sftype)
            let updated = 1
        else
        endif
    elseif !s:known_files.has(a:fname)
        call s:ProcessFile(a:fname, sftype)
        let updated = 1
    endif

    let fileinfo = s:known_files.get(a:fname)

    if empty(fileinfo)
        return
    endif

    if bufwinnr(s:TagbarBufName()) != -1 && !s:paused &&
     \ (s:new_window || updated ||
      \ (!empty(s:TagbarState().getCurrent(0)) &&
       \ a:fname != s:TagbarState().getCurrent(0).fpath))
        call s:RenderContent(fileinfo)
    endif

    if !empty(fileinfo)
        call s:TagbarState().setCurrent(fileinfo)
        let s:nearby_disabled = 0
    endif

    call s:HighlightTag(0)
    call s:SetStatusLine()
endfunction

function! s:CheckMouseClick() abort
    let line   = getline('.')
    let curcol = col('.')

    if (match(line, s:icon_open . '[-+ ]') + 1) == curcol
        call s:CloseFold()
    elseif (match(line, s:icon_closed . '[-+ ]') + 1) == curcol
        call s:OpenFold()
    elseif g:tagbar_singleclick
        call s:JumpToTag(0)
    endif
endfunction

function! s:DetectFiletype(bufnr) abort
    let ftype = getbufvar(a:bufnr, '&filetype')

    if bufloaded(a:bufnr)
        return ftype
    endif

    if ftype != ''
        return ftype
    endif

    let bufname = bufname(a:bufnr)
    let eventignore_save = &eventignore
    set eventignore=FileType
    let filetype_save = &filetype

    exe 'doautocmd filetypedetect BufRead ' . bufname
    let ftype = &filetype

    let &filetype = filetype_save
    let &eventignore = eventignore_save

    return ftype
endfunction

function! s:EscapeCtagsCmd(ctags_bin, args, ...) abort
    if exists('+shellslash')
        let shellslash_save = &shellslash
        set noshellslash
    endif

    if &shell =~ 'cmd\.exe$' && a:ctags_bin !~ '\s'
        let ctags_cmd = a:ctags_bin
    else
        let ctags_cmd = shellescape(a:ctags_bin)
    endif

    if type(a:args)==type('')
        let ctags_cmd .= ' ' . a:args
    elseif type(a:args)==type([])
        for arg in a:args
            let ctags_cmd .= ' ' . shellescape(arg)
        endfor
    endif

    if a:0 == 1
        let ctags_cmd .= ' ' . shellescape(a:1)
    endif

    if exists('+shellslash')
        let &shellslash = shellslash_save
    endif

    if has('multi_byte')
        if g:tagbar_systemenc != &encoding
            let ctags_cmd = iconv(ctags_cmd, &encoding, g:tagbar_systemenc)
        elseif $LANG != ''
            let ctags_cmd = iconv(ctags_cmd, &encoding, $LANG)
        endif
    endif

    if ctags_cmd == ''
        if !s:warnings.encoding
            call s:warning('Tagbar: Ctags command encoding conversion failed!' .
                \ ' Please read ":h g:tagbar_systemenc".')
            let s:warnings.encoding = 1
        endif
    endif

    return ctags_cmd
endfunction

function! s:ExecuteCtags(ctags_cmd) abort
    if &shell =~# 'fish$'
        " Reset shell since fish isn't really compatible
        let shell_save = &shell
        set shell=sh
    endif

    if exists('+shellslash')
        let shellslash_save = &shellslash
        set noshellslash
    endif

    if &shell =~ 'cmd\.exe'
        let shellxquote_save = &shellxquote
        set shellxquote=\"
        let shellcmdflag_save = &shellcmdflag
        set shellcmdflag=/s\ /c
    endif

        silent let ctags_output = system(a:ctags_cmd)

    if &shell =~ 'cmd\.exe'
        let &shellxquote  = shellxquote_save
        let &shellcmdflag = shellcmdflag_save
    endif

    if exists('+shellslash')
        let &shellslash = shellslash_save
    endif

    if exists('shell_save')
        let &shell = shell_save
    endif

    return ctags_output
endfunction

function! s:GetNearbyTag(all, forcecurrent, ...) abort
    if s:nearby_disabled
        return {}
    endif

    let fileinfo = s:TagbarState().getCurrent(a:forcecurrent)
    if empty(fileinfo)
        return {}
    endif

    let typeinfo = fileinfo.typeinfo
    if a:0 > 0
        let curline = a:1
    else
        let curline = line('.')
    endif
    let tag = {}

    for line in range(curline, 1, -1)
        if has_key(fileinfo.fline, line)
            let curtag = fileinfo.fline[line]
            if a:all || typeinfo.getKind(curtag.fields.kind).stl
                let tag = curtag
                break
            endif
        endif
    endfor

    return tag
endfunction

function! s:GetTagInfo(linenr, ignorepseudo) abort
    let fileinfo = s:TagbarState().getCurrent(0)

    if empty(fileinfo)
        return {}
    endif

    let curline = getbufline(bufnr(s:TagbarBufName()), a:linenr)[0]
    if curline =~ '^\s*$' || curline[0] == '"'
        return {}
    endif

    if !has_key(fileinfo.tline, a:linenr)
        return {}
    endif

    let taginfo = fileinfo.tline[a:linenr]

    if a:ignorepseudo && taginfo.isPseudoTag()
        return {}
    endif

    return taginfo
endfunction

function! s:GetFileWinnr(fileinfo) abort
    let filewinnr = 0
    let prevwinnr = winnr("#")

    if winbufnr(prevwinnr) == a:fileinfo.bufnr && !getwinvar(prevwinnr, '&previewwindow')
        let filewinnr = prevwinnr
    else
        for i in range(1, winnr('$'))
            call s:goto_win(i, 1)
            if bufnr('%') == a:fileinfo.bufnr && !&previewwindow
                let filewinnr = winnr()
                break
            endif
        endfor

        call s:goto_tagbar(1)
    endif

    return filewinnr
endfunction

function! s:GotoFileWindow(fileinfo, ...) abort
    let noauto = a:0 > 0 ? a:1 : 0

    let filewinnr = s:GetFileWinnr(a:fileinfo)

    if filewinnr == 0
        for i in range(1, winnr('$'))
            call s:goto_win(i, 1)
            if &buftype == '' && !&previewwindow
                execute 'buffer ' . a:fileinfo.bufnr
                break
            endif
        endfor
    else
        call s:goto_win(filewinnr, 1)
    endif

    call s:goto_tagbar(noauto)
    call s:goto_win('p', noauto)
endfunction

function! s:ToggleHideNonPublicTags() abort
    let fileinfo = s:TagbarState().getCurrent(0)
    if empty(fileinfo)
        return
    endif

    let curline = line('.')
    let taginfo = s:GetTagInfo(curline, 0)

    match none

    let g:tagbar_hide_nonpublic = !g:tagbar_hide_nonpublic
    call s:RenderKeepView()
    call s:SetStatusLine()

    if !empty(taginfo)
        execute taginfo.tline
    else
        execute curline
    endif
endfunction

function! s:ToggleCaseInsensitive() abort
    let fileinfo = s:TagbarState().getCurrent(0)
    if empty(fileinfo)
        return
    endif

    let curline = line('.')
    let taginfo = s:GetTagInfo(curline, 0)

    match none

    let g:tagbar_case_insensitive = !g:tagbar_case_insensitive

    call fileinfo.sortTags()

    call s:RenderKeepView()
    call s:SetStatusLine()

    if !empty(taginfo)
        execute taginfo.tline
    else
        execute curline
    endif
endfunction

function! s:ToggleAutoclose() abort
    let g:tagbar_autoclose = !g:tagbar_autoclose
    call s:SetStatusLine()
endfunction

function! s:IsValidFile(fname, ftype) abort

    if a:fname == '' || a:ftype == ''
        return 0
    endif

    if !filereadable(a:fname) && getbufvar(a:fname, 'netrw_tmpfile') == ''
        return 0
    endif

    if getbufvar(a:fname, 'tagbar_ignore') == 1
        return 0
    endif

    let winnr = bufwinnr(a:fname)
    if winnr != -1 && getwinvar(winnr, '&diff')
        return 0
    endif

    if &previewwindow
        return 0
    endif

    if !has_key(s:known_types, a:ftype)
        if exists('g:tagbar_type_' . a:ftype)
            call s:LoadUserTypeDefs(a:ftype)
        else
            return 0
        endif
    endif

    return 1
endfunction

function! s:SetStatusLine()
    let tagbarwinnr = bufwinnr(s:TagbarBufName())
    if tagbarwinnr == -1
        return
    endif

    if tagbarwinnr != winnr()
        let in_tagbar = 0
        let prevwinnr = winnr()
        call s:goto_win('p', 1)
        let pprevwinnr = winnr()
        call s:goto_win(tagbarwinnr, 1)
    else
        let in_tagbar = 1
    endif

    if !empty(s:TagbarState().getCurrent(0))
        let fileinfo = s:TagbarState().getCurrent(0)
        let fname = fnamemodify(fileinfo.fpath, ':t')
        let sorted = get(fileinfo.typeinfo, 'sort', g:tagbar_sort)
    else
        let fname = ''
        let sorted = g:tagbar_sort
    endif
    let sortstr = sorted ? 'Name' : 'Order'

    let flags = []
    let flags += exists('w:autoclose') && w:autoclose ? ['c'] : []
    let flags += g:tagbar_autoclose ? ['C'] : []
    let flags += (sorted && g:tagbar_case_insensitive) ? ['i'] : []
    let flags += g:tagbar_hide_nonpublic ? ['v'] : []

    if exists('g:tagbar_status_func')
        let args = [in_tagbar, sortstr, fname, flags]
        let &l:statusline = call(g:tagbar_status_func, args)
    else
        let colour = in_tagbar ? '%#StatusLine#' : '%#StatusLineNC#'
        let flagstr = join(flags, '')
        if flagstr != ''
            let flagstr = '[' . flagstr . '] '
        endif
        let text = colour . '[' . sortstr . '] ' . flagstr . fname
        let &l:statusline = text
    endif

    if !in_tagbar
        call s:goto_win(pprevwinnr, 1)
        call s:goto_win(prevwinnr, 1)
    endif
endfunction

function! s:HandleOnlyWindow() abort
    let tagbarwinnr = bufwinnr(s:TagbarBufName())
    if tagbarwinnr == -1
        return
    endif

    let vim_quitting = s:vim_quitting
    let s:vim_quitting = 0

    if vim_quitting && !s:HasOpenFileWindows()
        if winnr('$') >= 1
            call s:goto_win(tagbarwinnr, 1)
        endif

        if tabpagenr('$') == 1
            noautocmd keepalt bdelete
        endif

        try
            try
                quit
            catch /.*/ " This can be E173 and maybe others
                call s:OpenWindow('')
                echoerr v:exception
            endtry
        catch /.*/
            echohl ErrorMsg
            echo v:exception
            echohl None
        endtry
    endif
endfunction

function! s:HandleBufDelete(bufname, bufnr) abort
    let nr = str2nr(a:bufnr)
    if bufexists(nr) && !buflisted(nr)
        return
    endif

    let tagbarwinnr = bufwinnr(s:TagbarBufName())
    if tagbarwinnr == -1 || a:bufname =~ '__Tagbar__.*'
        return
    endif

    call s:known_files.rm(fnamemodify(a:bufname, ':p'))

    if !s:HasOpenFileWindows()
        if tabpagenr('$') == 1 && exists('t:tagbar_buf_name')
            call setbufvar(a:bufname, 'tagbar_ignore', 1)

            if s:last_alt_bufnr == -1 || s:last_alt_bufnr == expand('<abuf>')
                if argc() > 1 && argidx() < argc() - 1
                    next
                else
                    enew
                endif
            else
                let last_alt_bufnr = s:last_alt_bufnr

                call setbufvar(last_alt_bufnr, 'tagbar_ignore', 1)
                execute 'keepalt buffer' last_alt_bufnr
                call setbufvar(last_alt_bufnr, 'tagbar_ignore', 0)
            endif

            set winfixwidth<

            call s:OpenWindow('')
        elseif exists('t:tagbar_buf_name')
            close
        endif
    endif
endfunction

function! s:ReopenWindow(delbufname) abort
    if expand('<amatch>') == a:delbufname
        return
    endif

    autocmd! TagbarAutoCmds BufWinEnter
    call s:OpenWindow("")
endfunction

function! s:HasOpenFileWindows() abort
    for i in range(1, winnr('$'))
        let buf = winbufnr(i)

        if !buflisted(buf) && getbufvar(buf, '&filetype') != 'netrw'
            continue
        endif

        if getbufvar(buf, '&buftype') != ''
            continue
        endif

        if getwinvar(i, '&previewwindow')
            continue
        endif

        return 1
    endfor

    return 0
endfunction

function! s:TagbarBufName() abort
    if !exists('t:tagbar_buf_name')
        let s:buffer_seqno += 1
        let t:tagbar_buf_name = '__Tagbar__.' . s:buffer_seqno
    endif

    return t:tagbar_buf_name
endfunction

function! s:TagbarState() abort
    if !exists('t:tagbar_state')
        let t:tagbar_state = s:state.New()
    endif

    return t:tagbar_state
endfunction

function! s:goto_win(winnr, ...) abort
    let cmd = type(a:winnr) == type(0) ? a:winnr . 'wincmd w' : 'wincmd ' . a:winnr
    let noauto = a:0 > 0 ? a:1 : 0

    if noauto
        noautocmd execute cmd
    else
        execute cmd
    endif
endfunction

function! s:goto_tagbar(...) abort
    let noauto = a:0 > 0 ? a:1 : 0
    call s:goto_win(bufwinnr(s:TagbarBufName()), noauto)
endfunction

function! s:mark_window() abort
    let w:tagbar_mark = 1
endfunction

function! s:goto_markedwin(...) abort
    let noauto = a:0 > 0 ? a:1 : 0
    for window in range(1, winnr('$'))
        call s:goto_win(window, noauto)
        if exists('w:tagbar_mark')
            unlet w:tagbar_mark
            break
        endif
    endfor
endfunction

function! s:warning(msg) abort
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction

function! TagbarBalloonExpr() abort
    let taginfo = s:GetTagInfo(v:beval_lnum, 1)

    if empty(taginfo)
        return ''
    endif

    return taginfo.getPrototype(0)
endfunction

" Wrappers {{{2
function! tagbar#ToggleWindow(...) abort
    let flags = a:0 > 0 ? a:1 : ''
    call s:ToggleWindow(flags)
endfunction

function! tagbar#OpenWindow(...) abort
    let flags = a:0 > 0 ? a:1 : ''
    call s:OpenWindow(flags)
endfunction

function! tagbar#CloseWindow() abort
    call s:CloseWindow()
endfunction

function! tagbar#SetFoldLevel(level, force) abort
    call s:SetFoldLevel(a:level, a:force)
endfunction

function! tagbar#highlighttag(openfolds, force) abort
    let tagbarwinnr = bufwinnr(s:TagbarBufName())
    if tagbarwinnr == -1
        echohl WarningMsg
        echomsg "Warning: Can't highlight tag, Tagbar window not open"
        echohl None
        return
    endif
    call s:HighlightTag(a:openfolds, a:force)
endfunction

function! tagbar#RestoreSession() abort
    call s:RestoreSession()
endfunction

function! tagbar#toggle_pause() abort
    let s:paused = !s:paused

    if s:paused
        call s:TagbarState().setPaused()
    else
        call s:AutoUpdate(fnamemodify(expand('%'), ':p'), 1)
    endif
endfunction

function! tagbar#getusertypes() abort
    let userdefs = filter(copy(g:), 'v:key =~ "^tagbar_type_"')

    let typedict = {}
    for [key, val] in items(userdefs)
        let type = substitute(key, '^tagbar_type_', '', '')
        let typedict[type] = val
    endfor

    return typedict
endfunction

function! tagbar#autoopen(...) abort
    let always = a:0 > 0 ? a:1 : 1

    call s:Init(0)

    for bufnr in range(1, bufnr('$'))
        if buflisted(bufnr) && (always || bufwinnr(bufnr) != -1)
            let ftype = s:DetectFiletype(bufnr)
            if s:IsValidFile(bufname(bufnr), ftype)
                call s:OpenWindow('')
                return
            endif
        endif
    endfor
endfunction

function! tagbar#currenttag(fmt, default, ...) abort
    let s:statusline_in_use = 1

    if a:0 > 0
        let longsig   = a:1 =~# 's' || (type(a:1) == type(0) && a:1 != 0)
        let fullpath  = a:1 =~# 'f'
        let prototype = a:1 =~# 'p'
    else
        let longsig   = 0
        let fullpath  = 0
        let prototype = 0
    endif

    if !s:Init(1)
        return a:default
    endif

    let tag = s:GetNearbyTag(0, 1)

    if !empty(tag)
        if prototype
            return tag.getPrototype(1)
        else
            return printf(a:fmt, tag.str(longsig, fullpath))
        endif
    else
        return a:default
    endif
endfunction

function! tagbar#currentfile() abort
    let filename = ''

    if !empty(s:TagbarState().getCurrent(1))
        let filename = fnamemodify(s:TagbarState().getCurrent(1).fpath, ':t')
    endif

    return filename
endfunction

function! tagbar#gettypeconfig(type) abort
    if !s:Init(1)
        return ''
    endif

    let typeinfo = get(s:known_types, a:type, {})

    if empty(typeinfo)
        call s:warning('Unknown type ' . a:type . '!')
        return
    endif

    let output = "let g:tagbar_type_" . a:type . " = {\n"

    let output .= "    \\ 'kinds' : [\n"
    for kind in typeinfo.kinds
        let output .= "        \\ '" . kind.short . ":" . kind.long
        if kind.fold || !kind.stl
            if kind.fold
                let output .= ":1"
            else
                let output .= ":0"
            endif
        endif
        if !kind.stl
            let output .= ":0"
        endif
        let output .= "',\n"
    endfor
    let output .= "    \\ ],\n"

    let output .= "\\ }"

    silent put =output
endfunction

function! tagbar#inspect(var) abort
    return get(s:, a:var)
endfunction
