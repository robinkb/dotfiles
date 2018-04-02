" Based on the Ultimate Vimrc
" https://github.com/amix/vimrc

" General, portable settings
function! Main()

    " Load plugs at the beginning to avoid overwriting my settings
    " $__hostname is set by bashrc to the home machine
    if $__hostname == $HOSTNAME
        if empty(glob('~/.vim/autoload/plug.vim'))
            silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
                        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
            autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
        endif

        call Plugs()
    endif

    " Enable using the mouse for stuff
    set mouse=a

    " Set how many lines Vim remembers
    set history=500

    " Enable filetype plugins
    filetype plugin on
    filetype indent on

    " 7 lines before and after cursor
    set so=7

    " Enable Wildmenu, which does commandline autocompletion
    set wildmenu
    set wildmode=longest:full,full

    " Always show current position
    set ruler

    " Highlight search results
    set hlsearch

    " Search with every keystroke
    set incsearch

    " Mark matching brackets
    set showmatch

    " Show line numbers
    set number

    " Enable syntax highlighting
    syntax enable

    " Force enable 256 colors
    set t_Co=256

    " Colorscheme for dark backgrounds
    set background=dark

    " Sane indentation handling
    set expandtab
    set smarttab

    set shiftwidth=4
    set tabstop=4

    set ai " Auto indent
    set si " Smart indent

    " Use two spaces for YAML
    autocmd Filetype yaml setlocal tabstop=2 shiftwidth=2

    " Swapfile under /tmp instead of working directory
    set swapfile
    set dir=/tmp

    " Show mode in the commandline
    set modeline

    " Use 'unnamedplus' clipboard buffer, allows yanking to clipboard
    set clipboard=unnamedplus

    " Better window navigation
    nnoremap <C-j> <C-w>j
    nnoremap <C-k> <C-w>k
    nnoremap <C-h> <C-w>h
    nnoremap <C-l> <C-w>l

    nnoremap <Leader>id :call IDE()<CR>

    " Delete, not cut (use x for cutting)
    nnoremap d "_d
    vnoremap d "_d

    call Statusline()
endfunction

" The Statusline should be portable
function! Statusline()
    " Always show statusline
    set laststatus=2

    " Define custom highlight groups
    highlight _Buffer       ctermfg=232 ctermbg=004 cterm=bold
    highlight _File         ctermfg=244 ctermbg=235 cterm=bold
    highlight _Encoding     ctermfg=246 ctermbg=237 cterm=bold
    highlight _Percent      ctermfg=248 ctermbg=238 cterm=bold
    highlight _Position     ctermfg=250 ctermbg=239 cterm=bold

    set statusline=
    set statusline+=%#_Buffer#\ %n\                     " Buffer number
    set statusline+=%#_File#\ %f\ %r%w                  " Path to file, and flags: ro,preview
    set statusline+=%=                                  " Shift to right side
    set statusline+=\ %{fugitive#statusline()}            " Current branch
    set statusline+=%#_Encoding#\ %y                    " Type of file, eg. [vim]
    set statusline+=\ %{&fileencoding?&fileencoding:&encoding}
    set statusline+=\ [%{&fileformat}\]
    set statusline+=\ %#_Percent#
    set statusline+=\ %4P\                              " Line in file by percentage
    set statusline+=\ %#_Position#
    set statusline+=\ %(%4l:%-4c%)                      " Line:Column

    nmap bd :b#<bar>bd#<CR>
endfunction

function! Plugs()
    " Load plugs
    call plug#begin('~/.vim/plugged')
    Plug 'morhetz/gruvbox'                              " Neat color scheme
    Plug 'vim-syntastic/syntastic'                      " Syntaxchecking and such
    Plug 'rust-lang/rust.vim'                           " RustLang
    Plug 'tpope/vim-fugitive'                           " Git Commands (Gblame, Gdiff, ...)
    Plug 'airblade/vim-gitgutter'                       " Show git status in the gutter
    Plug 'scrooloose/nerdtree'                          " File explorer
    Plug 'Xuyuanp/nerdtree-git-plugin'                  " Show git status in NERDTree
    Plug 'scrooloose/nerdcommenter'                     " Awesome comments
    Plug 'kannokanno/previm'                            " Markdown previews
    Plug 'ap/vim-buftabline'                            " Show buffers in the tabline
    Plug 'qpkorr/vim-bufkill'                           " Sane buffer management
    Plug 'actionshrimp/vim-xpath'                       " XPath query
    call plug#end()

    " Configure plugs
    call Gruvbox()
    call Syntastic()
    call RustLang()
    call NERDTree()
    call NERDCommenter()
    call Fugitive()
    call Previm()
    call Buftabline()
    call Bufkill()
endfunction

function! Gruvbox()
    let g:gruvbox_contrast_dark = "hard"
    let g:gruvbox_contrast_light = "hard"
    colorscheme gruvbox
endfunction

function! Syntastic()
    let g:syntastic_always_populate_loc_list = 1
    let g:syntastic_auto_loc_list = 1
    let g:syntastic_check_on_open = 1
    let g:syntastic_check_on_wq = 1
endfunction

function! RustLang()
    let g:rustfmt_autosave = 1
endfunction

function! NERDTree()
    let g:NERDTreeChDirMode = 2
    let g:NERDTreeMouseMode = 3
    let g:NERDTreeMinimalUI = 1
endfunction

function! NERDCommenter()
    let g:NERDSpaceDelims = 1
    let g:NERDDefaultAlign = 'left'
endfunction

function! Fugitive()
    nnoremap <Leader>gs :Gstatus<CR>
    nnoremap <Leader>gc :Gcommit<CR>
    nnoremap <Leader>gw :Gwrite<CR>
    nnoremap <Leader>gp :Gpush<CR>
    nnoremap <Leader>gl :Gpull<CR>
endfunction

function! Previm()
    let g:previm_open_cmd = 'firefox'
endfunction

function! Buftabline()
    set hidden
    nnoremap <C-N> :bnext<CR>
    nnoremap <C-P> :bprev<CR>
endfunction

function! Bufkill()
    map <C-c> :BD<cr>
endfunction

" TODO: Assign a keybinding to this
function! OpenTerminal()
    set splitbelow
    call term_start( "bash", {"term_finish":"close","term_rows":"12"} )
    setlocal wfh
    setlocal nobuflisted
    setlocal nonumber
    set nosplitbelow
endfunction

function! IDE()
    NERDTree
    wincmd p
    call OpenTerminal()
    wincmd p
endfunction

" Set space as leader key
let mapleader=' '

call Main()
