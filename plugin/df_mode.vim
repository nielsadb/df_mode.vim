"=============================================================================
"    Copyright: Copyright (C) 2013 Niels Aan de Brugh
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               filtering.vim is provided *as is* and comes with no
"               warranty of any kind, either expressed or implied. In no
"               event will the copyright holder be liable for any damages
"               resulting from the use of this software.
" Name Of File: df_mode.vim
"  Description: Distraction Free Editing & Buffer Groups
"   Maintainer: Niels Aan de Brugh (nielsadb+vim at gmail dot com)
" Last Changed: 17 February 2013
"      Version: See g:df_mode_version for version number.
"        Usage: Copy file to plugin in $VIMRUNTIME, or use
"               pathogen/vundle/etc.
"=============================================================================

if exists("g:df_mode_version") || &cp
    finish
endif
let g:df_mode_version = '0.9'

let s:config = {
            \ 'main_window_width_target':                 96,
            \ 'multi_window_slack_threshold':             10,
            \ 'saved_session_directory':                  '...///...Set me up!...\\\...',
            \ 'always_show_unbound_buffers':              0,
            \ 'empty_lines_before_unbound_buffer_group':  2,
            \ 'always_show_group_titles':                 0,
            \ 'show_buffer_grous':                        1,
            \ 'esc_closes_additional_window':             1,
            \ 'group_order':
            \        map(range(1, 9), 'v:val.""') + ['0', '#'],
            \ }

if exists('g:df_saved_session_directory')
    let s:config.saved_session_directory = g:df_saved_session_directory
endif

function! DF_GetConfig()
    return s:config
endfunction

function! DF_Redraw()
    call s:UpdateTabGroups()
endfunction

function! DF_Enable()
    let g:distraction_free_mode = 1
    colors dclear
    set laststatus=2
    set statusline=%{DF_MinimalStatusLineInfo()}
    if s:config.esc_closes_additional_window
        nnoremap <Esc> :call <SID>CloseWindow()<CR>:echo<CR>
    endif

    let slack = &columns - s:config.main_window_width_target
    " Note that this will obliterate buffers with bufhidden=wipe.
    silent! wincmd o

    let existing_left_buffer = 0
    let existing_right_buffer = 0
    for b in range(1, bufnr('$'))
        if getbufvar(b, 'leftwhitespacebuffer')
            let existing_left_buffer = b
        elseif getbufvar(b, 'rightwhitespacebuffer')
            let existing_right_buffer = b
        endif
    endfor

    if slack > s:config.multi_window_slack_threshold
        if existing_left_buffer
            wincmd v
            exe 'buffer '.existing_left_buffer
            normal! gg"_dG
        else
            vnew
            call s:MakeWhiteSpaceBuffer()
            let b:leftwhitespacebuffer = 1
        endif
        if existing_right_buffer
            wincmd v
            exe 'buffer '.existing_right_buffer
            normal! gg"_dG
        else
            vnew
            call s:MakeWhiteSpaceBuffer()
            let b:rightwhitespacebuffer = 1
        endif

        call s:SetBufferGroupSyntax()
        call s:config.set_buffer_groups_highlighting()

        wincmd L
        call s:SetWindowWidth(float2nr(0.70 * slack))
        wincmd h
        wincmd h
        call s:SetWindowWidth(float2nr(0.30 * slack))
        wincmd l
    end

    call s:UpdateTabGroups()
endfunction

function! DF_AddBufferToGroup(bufnr, group)
    if !has_key(s:tabgroups, a:group)
        let s:tabgroups[a:group] = {}
        if empty(s:highlighted_group)
            let s:highlighted_group = a:group.''
        endif
    endif
    let rv = 0
    if !has_key(s:tabgroups[a:group], a:bufnr)
        let s:tabgroups[a:group][a:bufnr] =
                    \ {'added':      1,
                    \  'added_time': reltime(),
                    \  'bufnr':      a:bufnr,
                    \  'deleted':    0}
        let rv = 1
    elseif s:tabgroups[a:group][a:bufnr].deleted
        let s:tabgroups[a:group][a:bufnr].deleted = 0
        let rv = 1
    endif
    if rv
        call s:UpdateTabGroups()
    endif
    return rv
endfunction

" Sets a buffer as removed. It is only removed from the data structures after
" at least (&ut/1000) seconds.
function! DF_RemoveBufferFromGroup(bufnr, group)
    if has_key(s:tabgroups, a:group) && has_key(s:tabgroups[a:group], a:bufnr)
        let item = s:tabgroups[a:group][a:bufnr]
        let item.deleted = 1
        let item.deleted_time = reltime()
        call s:UpdateTabGroups()
        return 2
    endif
    return 0
endfunction

" Add a buffer to a group, or if it has already been added, remove it from
" that group.
function! DF_ToggleBufferInGroup(bufnr, group)
    return DF_AddBufferToGroup(a:bufnr, a:group)
                \ || DF_RemoveBufferFromGroup(a:bufnr, a:group)
endfunction

function! DF_WriteBufferGroups()
    let session_name = input('Save session as: ', s:last_session)
    if empty(session_name) | return | endif
    let s:last_session = session_name
    let ls = ['p '.getcwd()]
    for [name, group] in items(s:tabgroups)
        if name ==# '#' | continue | endif
        let prefix = name ==# s:highlighted_group ? 'G ' : 'g '
        call add(ls, prefix.name)
        for [bufnr, item] in items(group)
            let prefix = bufnr == bufnr('%') ? 'c ' : '_ '
            call add(ls, prefix.fnamemodify(bufname(item.bufnr), ':p'))
        endfor
    endfor
    call writefile(ls, fnamemodify(s:config.saved_session_directory . session_name, ':p'))
endfunction

function! DF_ReadBufferGroups()
    let sessions = glob(s:config.saved_session_directory . '*', 0, 1)
    if empty(sessions)
        echo 'No sessions saved.'
        return
    endif

    let options = []
    for i in range(len(sessions))
        call add(options, printf('%3d: %s', i+1, fnamemodify(sessions[i], ':p:t')))
    endfor

    let choice = inputlist(options)
    if choice < 1 || choice > len(options) | return | endif

    let s:last_session = fnamemodify(sessions[choice-1], ':p:t')
    let ls = readfile(sessions[choice-1])
    let s:tabgroups = {}
    let selected_group = ''
    let selected_buffer = -1

    for line in ls
        let ch = line[0]
        if ch ==# 'c' || ch ==# '_'
            exe 'edit '.line[2:]
            call DF_AddBufferToGroup(bufnr('%'), current_group)
            if ch ==# 'c' | let selected_buffer = bufnr('%') | endif
        elseif ch ==? 'g'
            let current_group = line[2:]
            if ch ==# 'G'
                let selected_group = current_group
            endif
        elseif ch ==# 'p'
            exe 'cd '.line[2:]
        else
            throw 'illegal format'
        endif
    endfor

    if !empty(selected_group)
        let s:highlighted_group = selected_group
    endif
    if selected_buffer != -1
        exe 'buffer '.selected_buffer
    endif
    call DF_Enable()
    call s:UpdateTabGroups()
endfunction

function! DF_GoToNextBuffer(forward, skip_groups)
    let groups = s:GroupsForBuffer(bufnr('%'))
    if empty(groups) | return -1 | endif

    if index(groups, s:highlighted_group) == -1
        let current_group = groups[0]
    else
        let current_group = s:highlighted_group
    endif

    let buffers_by_name = DF_GetSortedBuffers(current_group)
    let cur_buf_idx = index(buffers_by_name, bufnr('%').'')
    let next_buffer = -1

    if a:skip_groups
        if (a:forward && cur_buf_idx == (len(buffers_by_name)-1)) ||
                    \  (!a:forward && cur_buf_idx == 0)
            if !s:config.always_show_unbound_buffers && has_key(s:tabgroups, '#')
                unlet s:tabgroups['#']
            endif
            let groups_by_name = DF_GetSortedGroups()
            let cur_grp_idx = index(groups_by_name, current_group)
            let ln = len(groups_by_name)
            if a:forward
                let next_group = groups_by_name[(cur_grp_idx+1)%ln]
                let next_group_by_name = DF_GetSortedBuffers(next_group)
                let next_buffer = next_group_by_name[0]
            else
                let next_group = groups_by_name[(cur_grp_idx-1+ln)%ln]
                let next_group_by_name = DF_GetSortedBuffers(next_group)
                let next_buffer = next_group_by_name[-1]
            endif
            let s:highlighted_group = next_group
        endif
    endif

    if next_buffer == -1
        let ln = len(buffers_by_name)
        let next_buffer = buffers_by_name[((cur_buf_idx+(a:forward?1:-1))+ln) % ln]
    endif

    if next_buffer != -1 && next_buffer != bufnr('%')
        exe 'buffer '.next_buffer
    else
        call s:UpdateTabGroups()
    endif
endfunction

function! DF_GoToGroup(group, force_to_first)
    let group = a:group.''
    if !has_key(s:tabgroups, group) | return | endif

    let s:highlighted_group = group
    if a:force_to_first || !has_key(s:tabgroups[group], bufnr('%').'')
        exe 'buffer '.DF_GetSortedBuffers(group)[0]
    endif
    call s:UpdateTabGroups()
endfunction

function! DF_GetSortedGroups()
    return sort(keys(s:tabgroups), '<SID>SortGroups')
endfunction

function! DF_GetSortedBuffers(group)
    if has_key(s:tabgroups, a:group.'')
        return sort(keys(s:tabgroups[a:group.'']), '<SID>SortBuffers')
    else
        return []
    endif
endfunction

function! DF_GetHighlighed()
    return [s:highlighted_group, s:highlighted_buffer]
endfunction



augroup DistractionFree
    au!
    " Updates the highlights in the buffer group view.
    au BufEnter    * call <SID>UpdateHighlighInBufferGroups()
    " Update the green/red buffer names when these exist.
    au CursorHold  * call <SID>RefreshForTransients()
    au CursorHoldI * call <SID>RefreshForTransients()
    " Updating the statusbar is somewhat difficult in Vim.
    au WinEnter    * call <SID>ChangedWindow()
    au WinLeave    * call <SID>ChangedWindow()
    au InsertLeave * let &ro=&ro
    au CursorHold  * let &ro=&ro
    au CursorHoldI * let &ro=&ro
augroup END

function! <SID>SetBufferGroupHighlighting()
    hi TabGroupGroupPrefix     guibg=#eeeeee guifg=#eeeeee
    hi TabGroupGroupPrefixNC   guibg=#eeeeee guifg=#eeeeee
    hi TabGroupTitle           guibg=#eeeeee guifg=#ff0000 gui=bold
    hi TabGroupTitleNC         guibg=#eeeeee guifg=#000000
    hi TabGroupBufferNew       guifg=#33aa33
    hi TabGroupBufferCurrent   guifg=#000000 gui=underline
    hi TabGroupBufferCurrentNC guifg=#000000
    hi TabGroupBufferDeleted   guifg=#aa3333
    hi TabGroupBufferNC        guifg=#aaaaaa
    hi TabGroupBufferNewNC     guifg=#aaaaaa gui=italic
    hi TabGroupPrefix          guifg=bg guibg=bg
    hi NonText                 guifg=bg
endfunction
let s:config.set_buffer_groups_highlighting = function('<SID>SetBufferGroupHighlighting')

function! <SID>UpdateHighlighInBufferGroups()
    if !buflisted(bufnr('%')) | return | endif
    if has_key(s:tabgroups, '#') | unlet s:tabgroups['#'] | endif
    let groups = s:GroupsForBuffer(bufnr('%'))
    let s:tabgroups['#'] = s:UnboundBuffers()
    if empty(groups)
        let s:highlighted_group = '#'
    else
        if len(groups) == 1 || index(groups, s:highlighted_group) == -1
            let s:highlighted_group = groups[0]
        endif
    endif
    call s:UpdateTabGroups()
endfunction

function! <SID>RefreshForTransients()
    if s:transient_items_remain | call s:UpdateTabGroups() | endif
endfunction

function! <SID>ChangedWindow()
    if !exists('b:whitespacebuffer')
        let s:lastwindow = winnr()
    endif
    " TODO: use hi-link or at least some color scheme independent way.
    if winnr('$') == 3
        hi StatusLine   guifg=#000000   guibg=#ffffff  gui=none
        hi StatusLineNC guifg=#777777   guibg=#ffffff  gui=none
    else
        hi StatusLine   guifg=#ff0000   guibg=#eeeeee  gui=none
        hi StatusLineNC guifg=#666666   guibg=#eeeeee  gui=italic
    endif
    let &ro=&ro
endfunction

function! <SID>CloseWindow()
    if !exists('b:whitespacebuffer') && winnr('$') > 3 | wincmd c | endif
endfunction



function! s:UnboundBuffers()
    let unbound = {}
    let bound = []
    for group in values(s:tabgroups)
        let bound = bound + keys(group)
    endfor
    for i in range(1, bufnr('$'))
        if buflisted(i) && index(bound, i.'') == -1
            let unbound[i] = {'added':    0,
                        \     'bufnr':   i,
                        \     'deleted': 0}
        endif
    endfor
    return unbound
endfunction

function! s:GroupsForBuffer(bufnr)
    let rv = []
    for group in sort(keys(s:tabgroups))
        for bufnr in keys(s:tabgroups[group])
            if a:bufnr == bufnr
                call add(rv, group)
            endif
        endfor
    endfor
    return rv
endfunction

function! s:GetFirstLineOfBuffer(bufnr)
    " This is only used on buffer without a proper name. It is assumed these
    " are typically small.
    for line in getbufline(str2nr(a:bufnr), 1, '$')
        let stripped = substitute(substitute(line, '^\s*', '', ''), '\s*$', '', '')
        if !empty(stripped) | return stripped | endif
    endfor
    return '[Empty File]'
endfunction

function! s:GetBuferName(nr)
    let res = fnamemodify(bufname(str2nr(a:nr)), ':p:t')
    if empty(res)
        let res = printf('new:%s   %s', a:nr, s:GetFirstLineOfBuffer(a:nr))
        let s:transient_items_remain = 1
    endif
    return res
endfunction

function! <SID>SortBuffers(a, b)
    " If both buffers have an empty name, sort by buffer index.
    " Otherwise order may be undefined (depending on sorting algorithm).
    if a:a == a:b | return 0 | endif
    let aa = s:GetBuferName(a:a)
    let bb = s:GetBuferName(a:b)
    return aa ==# bb ? (a:a > a:b ? 1 : -1) : aa > bb ? 1 : -1
endfunction

function! <SID>SortGroups(a, b)
    return index(s:config.group_order, a:a) - index(s:config.group_order, a:b)
endfunction

function! s:SetWindowWidth(width)
    if winwidth('%') < a:width
        for i in range(a:width - winwidth('%'))
            wincmd >
        endfor
    else
        for i in range(winwidth('%') - a:width)
            wincmd <
        endfor
    end
endfunction

function! s:MakeWhiteSpaceBuffer()
    setlocal nonumber nowrap nobuflisted
    setlocal buftype=nofile
    " -- setlocal bufhidden=wipe
    "  Don't wipe a whitespace buffer when it hidden. Allows for re-use.
    "  Not for efficiency reasons, but to avoid constantly increasing bufnrs.
    setlocal bufhidden=hide
    setlocal noswapfile
    let b:whitespacebuffer = 1
    hi NonText guifg=bg
endfunction

function! DF_MinimalStatusLineInfo()
    if winnr('$') == 3
        if exists('b:rightwhitespacebuffer')
            if !s:config.show_buffer_grous
                return fnamemodify(bufname(winbufnr(s:lastwindow)),':p:t')
            endif
        endif
        if exists('b:leftwhitespacebuffer')
            let pattern = '%'.winwidth('.').'d'
            " Is there really no other way to get line('$') in another buffer?
            return printf(pattern, len(getbufline(winbufnr(s:lastwindow), 1, '$')))
        endif
        if winnr() != s:lastwindow
            return fnamemodify(bufname('%'),':p:t')
        endif
    else " More windows. Print statusline info locally.
        if exists('b:whitespacebuffer')
            return ' '
        else
            let total = printf('%d', line('$'))
            let prefix = repeat(' ', max([4-len(total), 0]))
            let name = fnamemodify(bufname('%'),':p:t')
            let spring = repeat(' ', winwidth('.')-len(name)-len(total)-len(prefix))
            return prefix.total.spring.name
        end
    endif
    return ''
endfunction

function! s:SetBufferGroupSyntax()
    syn clear
    syn match TabGroupGroupPrefix     "^G "
    syn match TabGroupGroupPrefixNC   "^g "
    syn match TabGroupPrefix          "^[Ccad_] "
    syn match TabGroupTitle           "^G \S\+\W*$"hs=s+2 contains=TabGroupGroupPrefix
    syn match TabGroupTitleNC         "^g \S\+\W*$"hs=s+2 contains=TabGroupGroupPrefixNC
    syn match TabGroupBufferNew       "^a .\+$"hs=s+2 contains=TabGroupPrefix
    syn match TabGroupBufferCurrent   "^C .\+$"hs=s+2 contains=TabGroupPrefix
    syn match TabGroupBufferCurrentNC "^c .\+$"hs=s+2 contains=TabGroupPrefix
    syn match TabGroupBufferDeleted   "^d .\+$"hs=s+2 contains=TabGroupPrefix
    syn match TabGroupBufferNC        "^_ .\+$"hs=s+2 contains=TabGroupPrefix
    syn match TabGroupBufferNewNC     "^_ new:\d\+   .\+$"hs=s+2 contains=TabGroupPrefix
endfunction

" Gets the seconds part of a reltime object.
" This is the first element in the list, but I think that's a private API.
function! s:SecondsSince(time)
    return str2nr(reltimestr(reltime(a:time)))
endfunction

function! s:CleanupGroups()
    for group in keys(s:tabgroups)
        for bufnr in keys(s:tabgroups[group])
            let item = s:tabgroups[group][bufnr]
            " Remove old removed items. However, don't delete the buffer that
            " is currently selected (now).
            if item.deleted && s:SecondsSince(item.deleted_time) > (&ut / 1000)
                        \ && !(group == s:highlighted_group && bufnr == bufnr('%').'')
                unlet s:tabgroups[group][item.bufnr]
            endif
        endfor
        if empty(s:tabgroups[group])
            unlet s:tabgroups[group]
        endif
    endfor
endfunction

function! s:RenderTabGroups()
    let s:transient_items_remain = 0

    for group in DF_GetSortedGroups()

        " Hide # unless that is the current group, or it is set to always show.
        if group == '#'
            if  s:highlighted_group != '#' && !s:config.always_show_unbound_buffers
                continue
            else
                " Some extra whitespace before the # group.
                if len(s:tabgroups) > 1
                    for i in range(s:config.empty_lines_before_unbound_buffer_group)
                        call append(line('$'), "")
                    endfor
                endif
            endif
        endif

        " Output group title, only when should more groups or explicitly set.
        call append(line('$'), "")
        let shown_groups = len(s:tabgroups)
        if has_key(s:tabgroups, '#') && s:highlighted_group != '#'
                    \ && !s:config.always_show_unbound_buffers
            let shown_groups = shown_groups - 1
        endif
        if shown_groups > 1 || s:config.always_show_group_titles
            let gp = group == s:highlighted_group ? 'G ' : 'g '
            call append(line('$'), gp.group.repeat(' ', 100))
        endif

        " Buffers are sorted by filename alphabetically.
        for bufnr in DF_GetSortedBuffers(group)
            let item = s:tabgroups[group][bufnr]
            let prefix = ''

            " Determine the prefix of this buffer
            if item.deleted
                let prefix = 'd'
                let s:transient_items_remain = 1
            elseif item.bufnr == s:highlighted_buffer
                let prefix = s:highlighted_group == group ? 'C' : 'c'
            elseif item.added && s:SecondsSince(item.added_time) < (&ut / 1000)
                let prefix = 'a'
                let s:transient_items_remain = 1
            else
                let prefix = '_'
            endif

            " Render the item
            call append(line('$'), printf('%s %s', prefix, s:GetBuferName(bufnr)))
        endfor
    endfor

    " Remove extra white line at top of buffer.
    normal! gg"_dd
endfunction

function! s:UpdateTabGroups()
    let s:highlighted_buffer = bufnr('%')
    let from_window = winnr()
    let right_window = 0
    for i in range(1, winnr('$'))
        if getbufvar(winbufnr(i), 'rightwhitespacebuffer')
            let right_window = i
        endif
    endfor
    if !right_window
        return
    endif
    exe right_window.'wincmd w'
    normal! gg"_dG
    call s:CleanupGroups()
    if s:config.show_buffer_grous
        call s:RenderTabGroups()
    endif
    exe from_window.'wincmd w'
    echo ''
endfunction



let s:transient_items_remain = 0
let s:lastwindow = 1
if !exists('s:last_session')      | let s:last_session = ''      | endif
if !exists('s:tabgroups')         | let s:tabgroups = {}         | endif
if !exists('s:highlighted_group') | let s:highlighted_group = '' | endif



