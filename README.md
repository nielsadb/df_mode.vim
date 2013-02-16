df_mode.vim
===========

Distraction free editing in Vim.

I wanted something that combines a clean editing view with decent buffer management.

This plug-in is currently poorly documented and not very well tested.

## Example configuration

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    " Distraction Free Config
    
    let g:df_saved_session_directory = '~/Dropbox/Config/vim-sessions/'
    
    function! ToggleShowBufferGroups()
        let df_config = DF_GetConfig()
        let df_config.show_buffer_grous = !df_config.show_buffer_grous
        call DF_Redraw()
    endfunction
    
    function! ToggleAlwaysShowUnbound()
        let df_config = DF_GetConfig()
        let df_config.always_show_unbound_buffers = !df_config.always_show_unbound_buffers
        call DF_Redraw()
    endfunction
    
    function! RemoveBuffersFromGroup()
        let highlighed_group = DF_GetHighlighed()[0]
        for bufnr in DF_GetSortedBuffers(highlighed_group)
            call DF_RemoveBufferFromGroup(bufnr, highlighed_group)
        endfor
    endfunction
    
    nnoremap ,d        :call DF_Enable()<CR>
    nnoremap ,U        :call ToggleAlwaysShowUnbound()<CR>
    nnoremap <Space>   :call DF_GoToNextBuffer(1, 0)<CR>:echo<CR>
    nnoremap <S-Space> :call DF_GoToNextBuffer(0, 0)<CR>
    nnoremap <M-Space> :call DF_GoToNextBuffer(1, 1)<CR>
    nnoremap ,R        :call DF_ReadBufferGroups()<CR>
    nnoremap ,W        :call DF_WriteBufferGroups()<CR>
    nnoremap ,D        :call RemoveBuffersFromGroup()<CR>
    
    for i in range(1, 5)
        exe printf("nnoremap <D-%d> :call DF_ToggleBufferInGroup(bufnr('%%'), %d)<CR>", i, i)
        exe printf("nnoremap <M-%d> :call DF_GoToGroup(%d, 0)<CR>", i, i)
    endfor
    
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

