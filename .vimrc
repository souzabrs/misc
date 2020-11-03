execute pathogen#infect()
syntax on
filetype plugin indent on
set omnifunc=syntaxcomplete#Complete
let g:javascript_plugin_jsdoc = 1
let g:workspace_autosave = 0
set wildmenu
set ts=2
set shiftwidth=2
set expandtab
set autoindent
set mouse=a
set nowrap
set splitright
set ruler
set incsearch
set tildeop
set listchars=tab:\|\ ,space:·,extends:»,precedes:«,nbsp:×
set foldmethod=syntax
set foldnestmax=20
"set foldlevel=0
"set foldlevelstart=-1
set foldopen=""
"set nofoldenable
set pastetoggle=<F2>
set hlsearch
colorscheme default
set bg=dark
set colorcolumn=80
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_altv = 1
let g:ale_fixers = {
 \ 'javascript': ['eslint'],
 \ 'vue': ['eslint' ],
 \ 'python': ['yapf'],
 \ 'css': ['prettier']
 \ }
"let g:ale_linters_explicit = 1

let g:AutoPairsShortcutFastWrap='<C-L>'
let g:AutoPairsMultilineClose = 0

nnoremap <Leader>f :ALEFix<CR>
nnoremap <Leader>t :silent %!prettier --stdin --stdin-filepath % <CR>``
nnoremap <Leader>p vip :'<,'>!prettier --stdin --stdin-filepath % <CR> vip=``
"vnoremap <Leader>b :'<,'>!prettier --stdin --stdin-filepath % <CR> ='] 
nnoremap <Leader>y :set list!<CR>:set number!<CR>
nnoremap p p=`]
nnoremap <c-p> p
nnoremap <Leader>j JlvF'd75<bar>bi' +<CR>'<ESC>
nnoremap <Leader>h J75<bar>bi<CR><ESC>
"break the line in the 79th column
nnoremap <Leader>b 79<bar>i<Bslash><CR><ESC>
map [[ ?{<CR>w99[{
map ][ /}<CR>b99]}
map ]] j0[[%/{<CR>
map [] k$][%?}<CR>
noremap <F4> :set hlsearch! hlsearch?<CR>
autocmd InsertEnter * if !exists('w:last_fdm') | let w:last_fdm=&foldmethod | setlocal foldmethod=manual | endif
autocmd InsertLeave,WinLeave * if exists('w:last_fdm') | let &l:foldmethod=w:last_fdm | unlet w:last_fdm | endif


augroup python_cmd
  autocmd!
  autocmd FileType python call PythonIndent()
	function! PythonIndent()
		setlocal foldmethod=indent
		setlocal foldlevel=99
	endfunction
augroup END

"set window width = 85
nnoremap <Leader>e :vertical resize 85<CR>
"go to last tab and open a new one
nnoremap <Leader>n :tabl <bar> tabe<CR>

function! FloatUp()
	norm k
	"if is not a blank line, go up till it is
	if getline(".")[0] !~ '^\s*$'
		while line(".") != 1 && getline(".")[0] !~ '^\s*$'
			norm k
		endwhile
		return
	endif
	while line(".") != 1 && getline(".")[0] =~ '^\s*$'
		norm k
	endwhile
endfunction
function! FloatDown()
	norm j
	"if is not a blank line, go down till it is
	if getline(".")[0] !~ '^\s*$'
		while line(".") != line("$") && getline(".")[0] !~ '^\s*$'
			norm j
		endwhile
		return
	endif
	while line(".") != line("$") && getline(".")[0] =~ '^\s*$'
		norm j
	endwhile
endfunction
nnoremap gk :call FloatUp()<CR>
nnoremap gj :call FloatDown()<CR>
