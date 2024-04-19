/* Trabalhando com trigger e sequences
 Vamos criar uma modelagem de dados para controlar transa��es de cart�o de cr�dito

O que � uma TRIGGER?
 � um objeto criado no banco de dados composto por um bloco PL/SQL,
 e disparado automaticamente quando um evento ocorre,
 um gatilho pode ser disparado por um INSERT, UPDATE ou DELETE em uma tabela.*/

--f�rmula da trigger:

CREATE OR REPLACE TRIGGER trigger_name

  {BEFORE | AFTER} triggering_event ON table_name
  [FOR EACH ROW]
  [FOLLOWS | PRECEDES another_trigger]
  [ENABLE / DISABLE ]
  [WHEN condition]
   
DECLARE
   declaration statements;
   
BEGIN
   executable statements;
   
EXCEPTION
   exception_handling statements;

END;

/* O que � uma SEQUENCE?
 � um objeto criado no banco de dados com o objetivo de gerar uma sequencia autom�tica
 e incrementada ou dimininu�da por rotinas invocadas pelo banco de dados,
 ela pode ser compartilhada por v�rios usu�rios (owners) do banco de dados.*/
 
--f�rmula da sequence:

Create sequence nome_da_sequencia
  [increment by n] --obrigat�rio
  [start with n]   --obrigat�rio
  [maxvalue n | nomaxvalue] or [minvalue n | nominvalue] --n�o obrigat�rio
  [cycle | nocycle]    --n�o obrigat�rio
  [cache n | nocache]; --n�o obrigat�rio

--Criando as tabelas do sistema de transa��es

create table cartaocredito
   (numero_cc     number not null
   ,bandeira      varchar2(30)
   ,data_validade date
   ,codseg        number
   ,limite        number
   ,cpf           number
   ,nome          varchar2(100)
   );

create table fat_lancamentos
   (id_transacao    number --sequencial
   ,numero_cc       number
   ,data_transacao  date
   ,estabelecimento varchar2(30)
   ,valor           number
   );

create table saldo_cc
   (numero_cc   number
   ,limite_disp number
   );

--antes de inserir os dados vamos criar uma sequence

Create sequence fat_lancamento_s --S significa sequence
  increment by 1
  start with 1

select fat_lancamento_s.nextval from dual

/*Vamos ter q criar duas triggers, 
1) para alimentar o id da tabela de transa��es utilizando a nossa sequence
2) para atualizar o nosso saldo dispon�vel do cart�o de cr�dito*/

--1)

create or replace trigger fat_lancamentos_trg --TRG significa trigger
  before insert on fat_lancamentos referencing
    new as new old as old for each row --padr�o da sequence
      begin
        :new.id_transacao := fat_lancamento_s.nextval;
end;

--2)

create or replace trigger saldo_cc_trg
  after insert on cartaocredito referencing
    new as new old as old for each row
      begin
        insert into saldo_cc (numero_cc, limite_disp)
             values (:new.numero_cc, :new.limite); --(:new.numero_cc, :new.limite_credito);
end saldo_cc_trg;
--
create or replace trigger atualiza_saldo_cc_trg 
  after insert on fat_lancamentos referencing
    new as new old as old for each row
      begin
        update saldo_cc
           set limite_disp = (limite_disp - :new.valor)
        where numero_cc = :new.numero_cc;
        --
end atualiza_saldo_cc_trg;



--Testando as triggers:

select * from cartaocredito
select * from fat_lancamentos
select * from saldo_cc

/*ap�s inserir os dados em cartaocredito,
  a trigger disparar� os dados para outra tabela tamb�m
  no caso a tabela saldo_cc*/

desc cartaocredito

--inserindo dados na tabela cartaocredito

insert into cartaocredito
 (NUMERO_CC       
 ,BANDEIRA              
 ,DATA_VALIDADE               
 ,CODSEG                      
 ,LIMITE                     
 ,CPF                        
 ,NOME
 )
values
 (123456789 --NUMERO_CC       
 ,'VISA' --BANDEIRA              
 ,to_date('31/10/2035','DD/MM/YYYY') --DATA_VALIDADE               
 ,222 --CODSEG                      
 ,2000 --LIMITE                     
 ,33344455522 --CPF                        
 ,'DANIEL FERNANDES' --NOME
 );

--fazendo uma transa��o para testar a trigger

insert into fat_lancamentos
  (numero_cc
  ,data_transacao
  ,estabelecimento
  ,valor
  )
values
  (123456789
  ,sysdate
  ,'Assinatuda NETFLIX'
  ,39.90
  );
  
insert into fat_lancamentos
  (numero_cc
  ,data_transacao
  ,estabelecimento
  ,valor
  )
values
  (123456789
  ,sysdate
  ,'Mercado XYZ'
  ,150
  );

insert into fat_lancamentos
  (numero_cc
  ,data_transacao
  ,estabelecimento
  ,valor
  )
values
  (123456789
  ,sysdate
  ,'Posto Ipiranga'
  ,200
  );

--Fatura para o m�s de agosto

select sum (valor) total_fatura
  from fat_lancamentos
where numero_cc = 123456789
--and data_transacao >= to_date('01/08/2023','DD/MM/YYYY')
--and data_transacao <= to_date('31/08/2023','DD/MM/YYYY')
and data_transacao between  to_date ('01/08/2023','DD/MM/YYYY')
                        and to_date ('31/08/2023','DD/MM/YYYY')
                        
--Simulando o pagamento da fatura

--Simular o pagamento da fatura

insert into fat_lancamentos
  (numero_cc
  ,data_transacao
  ,estabelecimento
  ,valor
  )
values
  (123456789
  ,sysdate
  ,'Pagto fatura'
  ,1489.9 * -1
  );
  