program simplificadormif;
Uses sysutils;

var 

//==============| Entrada |===============//
original : Text; temp:string;
//========================================//

//==============| Controle |==============//
posI,posF,ctd,qtagrup,enable : integer;
//=======================================//

//==============| Saida |===============//
novo: Text; temp2 : string;
//=====================================//

procedure a(linha:string);
var	posicao,conteudo : integer; s : integer;
begin

	s:=Pos(':',linha);
	posicao := strtoint(Copy(linha,1,(s-1)));
	conteudo := strtoint(linha[s+1]);
	
	if(conteudo <> ctd) then 
	begin 
		if(qtAgrup >= 1) then 
		begin
			temp2 := concat('[',inttostr(posI),'..',inttostr(posF),']: ', inttostr(ctd),';');
			writeln(temp2); 
			writeln(novo,temp2); qtAgrup := 0;
		end else begin 
			if(enable=1) then begin
				temp2 := concat(inttostr(posI),': ',inttostr(ctd),';');
				writeln(temp);
				writeln(novo,temp);
			end;
		end;
		ctd:= conteudo; posI := posicao; posF := posicao; 
	end else
    if(posicao <> posF) then begin qtagrup := qtagrup +1; posF := posicao; end;

end;

procedure geraCabecalho;
begin
	writeln(novo,' -- Arquivo gerado pelo simplificador de mif de autoria de Bruno César(201439002-7) --'); writeln(novo,'');
    writeln(novo,'WIDTH=1;'); 
    writeln(novo,'DEPTH=16383;'); writeln(novo,'');
    writeln(novo,'ADDRESS_RADIX=UNS;'); 
    writeln(novo,'DATA_RADIX=UNS;'); writeln(novo,'');
end;

begin
	ctd:= 0; posI:= 1; posF:= 1;enable:= 0;
	
	assign(original,'arquivo.mif');
	reset(original);
	
	assign(novo,'saida.mif');
	rewrite(novo);
	
	writeln('========| Iniciando |=======');
	
	geraCabecalho;
	
	repeat
		readln(original,temp);
		a(temp);
		enable:= 1;
	until eof(original);
	
	writeln('============================');
	
	close(original);
	close(novo);

end.
