         assume cs:codigo,ds:dados,es:dados,ss:pilha

CR        EQU    0DH ; caractere ASCII "Carriage Return" 
LF        EQU    0AH ; caractere ASCII "Line Feed"
BKSPC     EQU    08H ; caractere ASCII "Backspace"
ESCP      EQU    27  ; caractere ASCII "Escape"
ENTER     EQU    13  ; caractere ASCII "Enter"

; SEGMENTO DE DADOS DO PROGRAMA
dados     segment
nome      db 64 dup (?)
buffer    db 128 dup (?)
pede_nome db 'Nome do arquivo: ','$'
erro      db 'Erro! Repita.',CR,LF,'$'
msg_final db 'Fim do programa.',CR,LF,'$'
handler   dw ?
dados     ends

; SEGMENTO DE PILHA DO PROGRAMA
pilha    segment stack ; permite inicializacao automatica de SS:SP
         dw     128 dup(?)
pilha    ends
         
; SEGMENTO DE C�DIGO DO PROGRAMA
codigo   segment
inicio:         ; CS e IP sao inicializados com este endereco
         mov    ax,dados           ; inicializa DS
         mov    ds,ax              ; com endereco do segmento DADOS
         mov    es,ax              ; idem em ES
; fim da carga inicial dos registradores de segmento
;
; pede nome do arquivo
de_novo: lea    dx,pede_nome ; endereco da mensagem em DX
         mov    ah,9     ; funcao exibir mensagem no AH
         int    21h      ; chamada do DOS
; le nome do arquivo
         lea    di, nome
entrada: mov    ah,1
         int    21h	; le um caractere com eco

         cmp    al,ENTER   ; compara com carriage return
         jne    depois 
         jmp    terminar
depois:
         cmp    al,CR   ; compara com carriage return
         je     continua

         cmp    al,BKSPC   ; compara com 'backspace'
         je     backspace

         mov    [di],al ; coloca no buffer
         inc    di
         jmp    entrada

backspace:
         cmp    di,offset nome
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
;
; abre arquivo para leitura 
         mov    ah,3dh
         mov    al,0
         lea    dx,nome
         int 21h
         jnc    abriu_ok
         lea    dx,erro  ; endereco da mensagem em DX
         mov    ah,9     ; funcao exibir mensagem no AH
         int    21h      ; chamada do DOS
         jmp    de_novo
;
abriu_ok: mov handler,ax
laco:    mov ah,3fh      ; le um caracter do arquivo
         mov bx,handler
         mov cx,1
         lea dx,buffer
         int 21h
         cmp ax,cx
         jne fim
         mov dl, buffer  ; escreve caracter na tela
         mov ah,2
         int 21h
;         
         mov dl, buffer	 ; escreve na tela at� encontrar um LF (fim de linha)
         cmp dl, LF
         jne laco
;   
         mov ah,8	 ; espera pela digitacao de uma tecla qualquer
         int 21h
         jmp laco
;
fim:     mov ah,3eh	 ; fecha arquivo
         mov bx,handler
         int 21h
;      
         lea    dx,msg_final ; endereco da mensagem em DX
         mov    ah,9     ; funcao exibir mensagem no AH
         int    21h      ; chamada do DOS
terminar:
         mov    ax,4c00h ; funcao retornar ao DOS no AH
                         ; codigo de retorno 0 no AL
         int    21h      ; chamada do DOS
codigo   ends
         end    inicio
