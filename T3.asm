      assume cs:codigo,ds:dados,es:dados,ss:pilha ; define segmentos do código
CR       EQU    0DH ; constante - codigo ASCII do caractere "carriage return"
LF       EQU    0AH ; constante - codigo ASCII do caractere "line feed"
BKSPC     EQU    08H ; caractere ASCII "Backspace"
ESCP      EQU    27  ; caractere ASCII "Escape"
ENTR     EQU    13  ; caractere ASCII "Enter"

; definicao do segmento de dados do programa
dados    segment
;mensagens de systema
msgIdentificacao db     'Aluno: Victor Arnt Numero Cartao: 00291097','$' ;reutiliza
msgNomeArq       db 'Nome do arquivo: ','$'
msgFimEnter      db 'Programa Encerrado, voce clicou Enter','$'
msgErro          db 'Ops, nao encontrei o arquivo, digite novamente',CR,LF,'$'
msgAchou         db 'Acho .mov','$'
;constantes
fimlinha         db     CR,LF,'$' ;mantem
coresPrograma    db    0Fh ; fundo preto (0), texto em branco (F)
handler          dw ?
;variaveis
varNome          dw 64 dup (?)
varSuxMOV        db '.mov','$'
varBuffer        db 128 dup (?)
varAchoMov       dw ?
dados    ends

; definicao do segmento de pilha do programa
pilha    segment stack ; permite inicializacao automatica de SS:SP
         dw     128 dup(?)
pilha    ends
         
; definicao do segmento de codigo do programa
codigo   segment
inicio:  ; CS e IP sao inicializados com este endereco
         mov    ax,dados ; inicializa DS
         mov    ds,ax    ; com endereco do segmento DADOS
         mov    es,ax    ; idem em ES
; fim da carga inicial dos registradores de segmento

;TAREFA 1 DO PROGRAMA

;LIMPAR TELA 
limpaTela:
          mov   al,0        ; rolar todas as linhas da janela
          mov   bh,coresPrograma ; inserir novas linhas com este atributo
          mov   ch,0        ; linha do canto superior esquerdo da janela
          mov   cl,0        ; coluna do canto superior esquerdo da janela
          mov   dh,24       ; linha do canto inferior direito da janela
          mov   dl,79       ; coluna do canto inferior direito da janela
          mov   ah,6        ; rolar janela para cima
          int   10h         ; executa rolagem
; posiciona cursor      
          mov   dh,0        ; linha 0
          mov   dl,0        ; coluna 0
          call  poscursor   ; posiciona cursor na posicao (0,0) da tela

;NOME ALUNO

         lea    dx,msgIdentificacao        ; endereco da mensagem em DX
         mov    ah,9               ; funcao exibir mensagem no AH
         int    21h                ; chamada do DOS
; posiciona cursor      
          mov   dh,1        ; linha 0
          mov   dl,0        ; coluna 0
          call  poscursor   ; posiciona cursor na posicao (0,0) da tela

;ARQUIVOS
repete: lea    dx,msgNomeArq ; endereco da mensagem em DX
         mov    ah,9     ; funcao exibir mensagem no AH
         int    21h      ; chamada do DOS
; le nome do arquivo
         lea    di, varNome
entradaEnter: mov    ah,1
         int    21h	; le um caractere com eco

         cmp    al,ENTR   ; compara com Enter
         jne    depois 
         call   fimEnter
entrada: mov    ah,1
         int    21h	; le um caractere com eco

depois:
         cmp    al,CR   ; compara com carriage return
         je     continua

         cmp    al,BKSPC   ; compara com 'backspace'
         je     backspace

         mov    [di],al ; coloca no buffer
         inc    di
         jmp    entrada

backspace:
         cmp    di,offset varNome
         jne    adiante
         mov    dl,' '  ; avanca cursor na tela
         mov    ah,2
         int    21h
         jmp    entrada
adiante:
         mov    dl,' ' ; apaga ultimo caractere digitado
         mov    ah,2
         int    21h
         mov    dl,BKSPC ; recua cusor na tela
         mov    ah,2
         int    21h
         dec    di
         jmp    entrada

continua: 
         mov    byte ptr [di],0  ; forma string ASCIIZ com o nome do arquivo
         mov    dl,LF   ; escreve LF na tela
         mov    ah,2
         int    21h
;COMPARA SE TEM MOV
         cld
         lea    di, varNome
         mov    cx,64
         cld
         mov    al,'.'
	   mov    varAchoMov,0
	   repne  scasb
	   jne    acoplaMov	; parou sem achar nenhum caractere '.'
         mov    al,'M'
	   mov    varAchoMov,0
	   repne  scasb
	   jne    acoplaMov	; parou sem achar nenhum caractere 'M'
         mov    al,'O'
	   mov    varAchoMov,0
	   repne  scasb
	   jne     acoplaMov	; parou sem achar nenhum caractere 'O'
          mov    al,'V'
	   mov    varAchoMov,0
	   repne  scasb
	   jne    acoplaMov	; parou sem achar nenhum caractere 'V'
         jmp    ExibeNomeArq



acoplaMov:   
lea	di,varNome
mov	cx,64
cld
mov	al,20h	; codigo ascii do caractere espaço (ou usar ' ')
repne 	scasb
jne	fim	; nao achou nenhum espaço
mov	word ptr varNome,di	
dec	varNome	; corrige endereço do primeiro espaço
repe	scasb
je	fim	; so tem espaços ate o fim
mov	word ptr varSuxMOV,di
dec	varSuxMOV	; corrige endereço do primeiro caractere
mov	si,word ptr varSuxMOV	; endereço do ultimo espaço + 1
mov	di,word ptr varNome
inc	cx	; corrige contador
rep	movsb	; concatena segundo string com o primeiro
jmp ExibeNomeArq

;exibe nome arquivo
ExibeNomeArq:
      lea    dx,varNome        ; endereco da mensagem em DX
      mov    ah,9               ; funcao exibir mensagem no AH
      int    21h  
      jmp    abreArquivo 
;
; abre arquivo para leitura 
abreArquivo:
         mov    ah,3dh
         mov    al,0
         lea    dx,varNome
         int 21h
         jnc    abriu_ok
         lea    dx,msgErro  ; endereco da mensagem em DX
         mov    ah,9     ; funcao exibir mensagem no AH
         int    21h      ; chamada do DOS
         jmp    repete
;
abriu_ok: mov handler,ax
laco:    mov ah,3fh      ; le um caracter do arquivo
         mov bx,handler
         mov cx,1
         lea dx,varBuffer
         int 21h
         cmp ax,cx
         jne fim
         mov dl, varBuffer  ; escreve caracter na tela
         mov ah,2
         int 21h
;         
         mov dl, varBuffer	 ; escreve na tela at� encontrar um LF (fim de linha)
         cmp dl, LF
         jne laco
;   
         mov ah,8	 ; espera pela digitacao de uma tecla qualquer
         int 21h
         jmp laco
;

; retorno ao DOS com codigo de retorno 0 no AL (fim normal)
fim:
         mov    ax,4c00h           ; funcao retornar ao DOS no AH
         int    21h                ; chamada do DOS

poscursor proc ; posiciona o cursor na linha dada por DH e coluna dada por DL
          mov    ah,2       ; funcao posicionar cursor
          mov    bh,0       ; pagina 0 da memoria da placa de video
          int    10h        ; chama o servico do BIOS
          ret
poscursor endp



fimEnter proc ; posiciona o cursor na linha dada por DH e coluna dada por DL
      lea    dx,msgFimEnter        ; endereco da mensagem em DX
      mov    ah,9               ; funcao exibir mensagem no AH
      int    21h                ; chamada do DOS


      jmp   fim
      ret
fimEnter endp
codigo   ends

; a diretiva a seguir indica o fim do codigo fonte (ultima linha do arquivo)
; e informa que o programa deve começar a execucao no rotulo "inicio"
         end    inicio 
