//+------------------------------------------------------------------+
//|                                                EAGhost.mq5       |
//|                                                Master Forex Group|
//+------------------------------------------------------------------+
#property copyright "MASTER FOREX Group"
#property version   "1.0"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <MQLMySQL.mqh>
#include <comment.mqh>

 // --Variáveis de conexão com banco de MySQL------------------------
 input string Host             = "localhost";                // Endereço de localização do sistema de banco de dados
 input string User             = "root";                     // Usuário padrão do banco de dados
 input string Password         = "";                         // Senha padrão do banco de dados
 input string Database         = "mysql";                    // Banco de dados "Default"
 input string Socket           = "0";                        // Soquete padrão do banco de dados
 input int    Port             = "3306";                     // Porta padrão do utilizada pelo banco de dados
       string ClientFlag       = "CLIENT_MULTI_STATEMENTS";  // Permição para enviar multiplas query
       int    DB;

 
//-- Cria o banco de dados caso não exista---------------------------
 string MySQL_CreateDB            = "CREATE DATABASE IF NOT EXISTS GhostSystem;";
 string MySQL_UseDB               = "USE GhostSystem;";
 string MySQL_CreateTB; 
//--------------------------------------------------------------------

//--Variáveis do painel de ordens e requisições de tick---------------                
input int             _INPvolHIGH          = 25;              // Highlighted Volume
input color           _INPbuyLetterTS      = clrForestGreen;  // Buy Color
input color           _INPsellLetterTS     = clrFireBrick;    // Sell Color
input color           _INPbuyHighL         = clrGold;         // Buy Highlighted Volume Color
input color           _INPsellHighL        = clrDarkOrange;   // Sell Highlighted Volume Color
input color           _INPbetweenTS        = clrSteelBlue;    // Spread Color
input color           _INPchangeTickTS     = clrDimGray;      // Bid/Ask Color
input color           _INPcolorDefaultB    = Red;             // Window Border Color
input color           _INPcolorDefault     = Red;             // Window Color
input uchar           _alpha               = 224;             // Window Transparency
input int             _INPfsize            = 20;              // Font Size
input string          _INPfont             = "Verdana";       // Font
input double          _INPfontInterval     = 1;               // Font Interval
input int             _INPticks            = 1;               // Number of Requested Ticks
input ulong           _INPFilter           = 0;               // Show Volume > ?
//----------------------------------------------------------------------

string                 typeTrade;
color                  clrAgr;                                // allow 2 indicator per window
string                 now; 
int                    panelXX     =  4;
int                    panelYY     =  4;
int                    contador    =  0;


CComment timesandsales; // Instânciando objeto

//Inicialização
int OnInit(){

//-- Atributos de conexão com o MySQL-------------------------------- 
 Alert ("ATRIBUTOS DE CONEXÃO: Endereço de Acesso: ",Host, ", Usuário: ", User, ", Banco de Dados: ",Database);
 
 DB = MySqlConnect(Host, User, Password, Database, Port, Socket, ClientFlag);
 
 if (DB == -1){
 Alert ("Falha na conexão! Erro: "+MySqlErrorDescription);//Retorna erro caso não ocorra conexão
 } 
 else { 
 Alert ("GhostSystem conectado com o banco de dados MySQL");
 } 
 //------------------------------------------------------------------
 
 
 MySqlExecute(DB,MySQL_CreateDB); //Criando o banco de dados caso não exista
 MySqlExecute(DB,MySQL_UseDB);    //Selecionando o banco de dados recém criado
 
 
      now = TimeToString(TimeCurrent());
      timesandsales.Create("GhostSystem"+now,panelXX,panelYY);
      timesandsales.SetColor(_INPcolorDefaultB,_INPcolorDefault,_alpha);
      timesandsales.SetFont(_INPfont,_INPfsize,false,_INPfontInterval);
      timesandsales.SetGraphMode(true);
      timesandsales.SetText(0,"Sem dados no momento",_INPchangeTickTS);
      

//DEFINE FREQUÊNCIA DE TIMER
   EventSetTimer(1);
   return(0);
  }
  
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
 void OnDeinit(const int reason) {
 MySqlDisconnect(DB);
 Alert ("Conexão com MySQL finalizada com sucesso.");
 
 timesandsales.Destroy();  
 }


 int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
  
     
//-- Obtendo data atual para criação  da tabela no MySQL-------------------------------- 
 datetime    tm=TimeCurrent();
 MqlDateTime stm;
 TimeToStruct(tm,stm);

 string Data = "_" + stm.day+ "_" + stm.mon + "_" + stm.year; // Concatenação pra montagem de data no padrão Brasileiro
 MySQL_CreateTB = "CREATE TABLE IF NOT EXISTS DataMarket" + Data + "( ID INT AUTO_INCREMENT PRIMARY KEY, ATIVO VARCHAR(6), ORDEM VARCHAR(4),DATAHORA DATETIME,COTACAO VARCHAR(8),VOLUME INT);"; // Variavel para criação da tabela
//--------------------------------------------------------------------------------------

 
  
  
//-- Requisitando Ticks-----------------------------------------------------------------
 MqlTick tick_array[];
 int copied = CopyTicks(Symbol(),tick_array,COPY_TICKS_ALL,0,_INPticks);
 ArraySetAsSeries(tick_array,true);
//--------------------------------------------------------------------------------------


//-- Verificando tick existêcia de ticks------------------------------------------------
   if(copied>0){
//--------------------------------------------------------------------------------------   
   
//-- Criando nova tabela MarketData com recebimento de primeiro tick do dia-------------
   MySqlExecute(DB,MySQL_UseDB);
   MySqlExecute(DB,MySQL_CreateTB);
   if(MySqlExecute(DB,MySQL_CreateTB)==1){
   //Alert("Tabela MarketData"+Data+"criada com sucesso");
   };
//-------------------------------------------------------------------------------------- 
 
   int line = 0;    
//-- recebendo, plotando e exportando os ticks para MySQL-------------------------------    
    
      for (int i=0;i<_INPticks; i++){
               MqlTick tick   = tick_array[i];
               bool buy       =((tick.flags&TICK_FLAG_BUY)==TICK_FLAG_BUY);
               bool sell      =((tick.flags&TICK_FLAG_SELL)==TICK_FLAG_SELL);
               bool between   = tick.flags == 24 && tick.last < tick.ask && tick.last > tick.bid;
               
               if ( tick.volume <= _INPFilter ){
                  continue;
               } 

                  if(buy){ 
                         typeTrade = "BUY "; 
                         if(tick.volume >= (double)_INPvolHIGH) clrAgr = _INPbuyHighL; 
                            else{
                                clrAgr = _INPbuyLetterTS;
                                }
               }
                  
               else if(sell){    
               typeTrade = "SELL"; if(tick.volume >= (double)_INPvolHIGH) clrAgr = _INPsellHighL; else clrAgr = _INPsellLetterTS;
               }
               
                     else if(between==0)
                            {
                            typeTrade = "SPR "; clrAgr = _INPbetweenTS;
                            }
                            else{
                                typeTrade = "        "; clrAgr = _INPchangeTickTS;
                                }

                                     timesandsales.SetText(line++,TimeToString(tick.time,TIME_MINUTES|TIME_SECONDS)+"    "+
                                                                  DoubleToString(tick.last,Digits())+"    "+typeTrade+"    "+
                                                                  IntegerToString(tick.volume,1,'0'),clrAgr);             
                                                                             
//-- Envia os dados do times and trades para tabela no banco de dados-------------------                                                                 
                                         string MySQL_InsertTable  = "INSERT INTO DataMarket" + Data + "VALUES (DEFAULT, '"+Symbol()+"', '"+typeTrade+"', '"+tick.time+"', '"+tick.last+"', '"+tick.volume+"');";
                                                MySqlExecute(DB,MySQL_InsertTable);                                                             
//--------------------------------------------------------------------------------------  
                                                                                                                                              
                                                                  } //--Fim do for


              
                  timesandsales.SetText(_INPticks,"",_INPchangeTickTS);
                  timesandsales.Show();
                  ZeroMemory(tick_array);
                  }//--Fim do bloco IF principal
                
                  
//--Reporta erro em caso de não recebimento dos dados do Times and Trades----------------
                     else 
                        {
                        timesandsales.SetText(0,"Waiting for update or",_INPchangeTickTS);
                        timesandsales.SetText(1,"data could not be loaded (CHECK EXPERT TAB)",_INPchangeTickTS);
                        timesandsales.SetText(2," ",_INPchangeTickTS);
                        timesandsales.Show();
                        } 
//--------------------------------------------------------------------------------------

      return(rates_total);
}//Fim da função OnCalculate


void OnChartEvent(const int    id,
                  const long   &lparam,
                  const double &dparam,
                  const string &sparam){
   int res=timesandsales.OnChartEvent(id,lparam,dparam,sparam);
//--- move panel event
       if(res==EVENT_MOVE)
          return;
//--- change background color
          if(res==EVENT_CHANGE)
             timesandsales.Show(); 
}