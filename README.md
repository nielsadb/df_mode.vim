df_mode.vim
===========

Distraction free editing in Vim.
I wanted something that combines a clean editing view with decent buffer management.

This plug-in is currently poorly documented and not very well tested.

It is written entirely in VimScript. No external tools/libraries needed.

![Screenshot](https://raw.github.com/nielsadb/df_mode.vim/master/screenshot.png)
![Another Screenshot](https://raw.github.com/nielsadb/df_mode.vim/master/screenshot2.png)

## Some design rationale

The distraction free mode is based on iA Writer, an excellent text editor for the Mac. However, it's not quite up to the task of being a programming editor.

I want to keep this plug-in minimal yet provide standard functionality that I think is useful for most people. Using <tt>DF_GetHighlighed</tt>, <tt>DF_GetSortedGroups</tt> and <tt>DF_GetSortedBuffers </tt> you should be able to script some non-trivial things. But that's only for people who want to venture in the world of VimScript.

Switching to specific buffers is not very prominent in the feature set of this plug-in. I like to use small buffer groups, so a simple next-buffer-in-group mapping is enough for me (see example configuration below). Vim has more than enough features to switch buffers, including marks and many different plug-ins (such as bufexplorer).

When you want to use sessions, be sure to set the saved session directory (see example in the next section). I never quite learned to use Vim's own sessions, but that would not restore the buffer groups.

## Example configuration

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Distraction Free Config
    
    let g:df_session_save_directory = '~/Dropbox/Config/vim-sessions/'
    
    function! ToggleShowBufferGroups()
        let df_config = DF_GetConfig()
        let df_config.buffer_list_shown = !df_config.buffer_list_shown
        call DF_Redraw()
    endfunction
    
    function! ToggleAlwaysShowUngrouped()
        let df_config = DF_GetConfig()
        let df_config.buffer_list_always_show_ungrouped_buffers = !df_config.buffer_list_always_show_ungrouped_buffers
        call DF_Redraw()
    endfunction
    
    function! RemoveBuffersFromGroup()
        let highlighed_group = DF_GetHighlighed()[0]
        for bufnr in DF_GetSortedBuffers(highlighed_group)
            call DF_RemoveBufferFromGroup(bufnr, highlighed_group)
        endfor
    endfunction
    
    function! GoToNextBuffer(forward, skip_groups)
        if v:count == 0
            call DF_GoToNextBuffer(a:forward, a:skip_groups)
        else
            call DF_GoToGroup(v:count, 0)
        endif
    endfunction
    
    nnoremap ,d        :call DF_Enable()<CR>
    nnoremap ,u        :call ToggleShowBufferGroups()<CR>
    nnoremap ,U        :call ToggleAlwaysShowUngrouped()<CR>
    nnoremap <Space>   :<C-u>call GoToNextBuffer(1, 0)<CR>:echo<CR>
    nnoremap <S-Space> :<C-u>call GoToNextBuffer(0, 0)<CR>:echo<CR>
    " I found out that I don't use this, I jump to an explicit group.
    " nnoremap <M-Space> :<C-u>call GoToNextBuffer(1, 1)<CR>:echo<CR>
    nnoremap ,R        :call DF_ReadBufferGroups()<CR>
    nnoremap ,W        :call DF_WriteBufferGroups()<CR>
    nnoremap ,DD       :call RemoveBuffersFromGroup()<CR>
    
    for i in range(1, 5)
        exe printf("nnoremap <D-%d> :call DF_ToggleBufferInGroup(bufnr('%%'), %d)<CR>", i, i)
        " I found that M- and D- mappings are too confusing for me.
        " So I now use v:count to switch. Some people may still prefer this...
        " exe printf("nnoremap <M-%d> :call DF_GoToGroup(%d, 0)<CR>", i, i)
    endfor
    
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

Note: I find 5 groups to be more than enough. You can change the range if you feel you need more/less.

## Settings Description

For now, refer to the source file. The settings are documented first thing in the file.

## TODO

* Document all public functions.
* Make an optional feature to show (part of) the directory path of named buffers.
* Make an optional feature to show uppercase marks in each buffer.
* Maybe show the Current Working Directory somewhere.
* Remove buffers that are deleted from groups automatically (use autocmds).

