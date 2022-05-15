#property strict

#define SOCKET_LIBRARY_USE_EVENTS

string GetSymbol(string ori_s) {
   //do some replacing
   string s = ori_s;
   int open_end  = StringReplace(s,"{{","");
   int close_end = StringReplace(s,"}}","");
   /*
   if(open_end >= 0 && close_end >= 0) {Alert("Symbol is ",s);}
   string x=StringSubstr(s,0,6);
   for(int i=0;i<SymbolsTotal(false);i++) {
      string y=StringSubstr(SymbolName(i,false),0,6);
      if(x==y) {return(SymbolName(i,false));}
   }*/
   return(s);
}

#include "SOCKET.mqh"
#include "01bot.mqh"
//#include "MONEY_MANAGEMENT.mqh"
ServerSocket * glbServerSocket = NULL;
// Array of current clients
ClientSocket * glbClients[];

//input double TakeProfit = 20;
//input double StopLoss = 20;
input bool CloseOnReversal = true;
input double LotSize = 0.01;
input int    Max_Buy  = 1;
input int    Max_Sell = 1;
input double TP_Pip = 10;
input double SL_Money_Value = 200;
input double TP_Money_Value = 400;
input double Take_Partial_Percent = 10;
//input double Take_Partial_Money_Value = 200;
input double Take_Partial_Ratio = 0.5;
input int MagicNumber = 23456;
input string   Hostname = "18.117.238.246";    // Server hostname or IP address
input ushort   ServerPort = 80;        // Server port
#define TIMER_FREQUENCY_MS    50
#define HEXCHAR_TO_DECCHAR(h)  (h<=57 ? (h-48) : (h-55))
bool HexToArray(string str,uchar &arr[]) {
   int strcount = StringLen(str);
   int arrcount = ArraySize(arr);
   if(arrcount < strcount / 2) return(false);
   uchar tc[];
   StringToCharArray(str,tc);
   int i=0, j=0;
   for(i=0; i<strcount; i+=2)
     {
      uchar tmpchr=(HEXCHAR_TO_DECCHAR(tc[i])<<4)+HEXCHAR_TO_DECCHAR(tc[i+1]);
      arr[j]=tmpchr;
      j++;
     }
   return(true);
}

double DailyEquity=0;
double CurrentDay=-1;
double CurrentMin=-1;

bool ObjectsCreated=false;
bool glbCreatedTimer = false;
double xecn;
bool disconnected=true;
void SocketInit()
{
   if (glbServerSocket) {
      Print("Reloading EA with existing server socket");
   } else {
      glbServerSocket = new ServerSocket(ServerPort, false);
      
      if (glbServerSocket.Created()) {
         Print("Server socket created");
         glbCreatedTimer = EventSetMillisecondTimer(TIMER_FREQUENCY_MS);
         //SendSignal(keystr);
      }
      else {
         Print("Client connection failed");
         delete glbServerSocket;
         disconnected=true;
      }
      
   }
   xecn=1; if(Digits==5||Digits==3){xecn=10;}
}

void SocketDeinit (const int reason)
{
   switch (reason) {
      case REASON_CHARTCHANGE:
         break;
         
      default:
         glbCreatedTimer = false;
         // Delete all clients currently connected
         for (int i = 0; i < ArraySize(glbClients); i++) {
            delete glbClients[i];
         }
         ArrayResize(glbClients, 0);
         delete glbServerSocket;
         glbServerSocket = NULL;
         glbCreatedTimer = false;
         
         Print("Server socket terminated");
         break;
   }
}

void AcceptNewConnections()
{
   // Keep accepting any pending connections until Accept() returns NULL
   ClientSocket * pNewClient = NULL;
   do {
      pNewClient = glbServerSocket.Accept();
      if (pNewClient != NULL) {
         int sz = ArraySize(glbClients);
         ArrayResize(glbClients, sz + 1);
         glbClients[sz] = pNewClient;
         Print("New client connection");
      }
      
   } while (pNewClient != NULL);
}

void OnTimer()
{
   if(!disconnected)
   {
      AcceptNewConnections();
      for (int i = ArraySize(glbClients) - 1; i >= 0; i--) {
         HandleSocketIncomingData(i);
      }
   }
   //HandleSocketIncomingData();

}

void HandleSocketIncomingData(int idxClient)
{
   ClientSocket * pClient = glbClients[idxClient];
   bool bForceQuit = false; // Client has sent a "quit" message
   string strCommand;
   if (disconnected) {
      //glbClientSocket = new ClientSocket(Hostname,ServerPort);
      if (CheckPointer(pClient)==POINTER_DYNAMIC && pClient.IsSocketConnected()) {
         Print("Client connection succeeded");
         glbCreatedTimer = EventSetMillisecondTimer(TIMER_FREQUENCY_MS);
         //pClient.Send(keystr+"\r\n"); //CHANGE
         //SendSignal(keystr);
         disconnected=false;
      } else {
         Print("Client connection failed");
         delete pClient;
         disconnected=true;
      }
   }
   if(disconnected==true) {return;}
   if(CheckPointer(pClient) != POINTER_INVALID)
   {
      string strCommand;
      do {
         strCommand = pClient.Receive("\r\n");
         if(strCommand!="") {Alert(strCommand);}
         string cmd[];
         StringSplit(strCommand,':',cmd);
         
         if(ArraySize(cmd)>1 && cmd[0]=="BUY") {
            string symbol = GetSymbol(cmd[1]);
            clsInstrumentType INST(symbol);
            string final_name = INST.strFinalName;
            //if(final_name != ChartSymbol()) return;
            //if(MM.dblContractSize(symbol)==0) symbol = symbol+POSTFIX;
            Alert("BUY Trade To Open is ",final_name);
            Alert("BUY Command is ",strCommand);
            Print(strCommand);
            MqlTick tick;
            SymbolInfoTick(final_name,tick);
            double xAsk=tick.ask;
            double xBid=tick.bid;
            TRADE_COMMAND buy_command;
            buy_command._symbol = final_name;
            buy_command._magic = MagicNumber;
            buy_command._sl = 0;//FRACTREND_1.dblBuyDnRange - sl_x_pip * pips(strSymbol);
            EnterBuy(buy_command);
            
            /*
            //use crude for pip
            double new_adjusted_lots = LotSize;
            int sl_pip = MM.intSlPipPerPerMoney(SL_Money_Value,symbol,new_adjusted_lots);
            new_adjusted_lots = LotSize;
            int tp_pip = MM.intSlPipPerPerMoney(TP_Money_Value,symbol,new_adjusted_lots);
            double sl=xBid - sl_pip * pips(symbol);//(StopLoss*SymbolInfoDouble(symbol,SYMBOL_POINT)*xecn);
            double tp=xBid + tp_pip * pips(symbol);//(TakeProfit*SymbolInfoDouble(symbol,SYMBOL_POINT)*xecn);
            if(CloseOnReversal) {
               CloseAll(2,final_name);
            }
            
            Alert("Pre-enter Trade Buy Trade Number is ",trade_number(1,symbol));
            if(trade_number(1,final_name) < Max_Buy) OrderSend(final_name,OP_BUY,new_adjusted_lots,xAsk,20,sl,tp,"",MagicNumber);
            */
         }
         if(ArraySize(cmd)>1 && cmd[0]=="SELL") {
            string symbol = GetSymbol(cmd[1]);
            clsInstrumentType INST(symbol);
            string final_name = INST.strFinalName;
            //if(final_name != ChartSymbol()) return;
            //if(MM.dblContractSize(symbol)==0) symbol = symbol+POSTFIX;
            Alert("SELL Trade To Open is ",final_name);
            Alert("SELL Command is ",strCommand);
            Print(strCommand);
            MqlTick tick;
            SymbolInfoTick(final_name,tick);
            double xAsk=tick.ask;
            double xBid=tick.bid;
            TRADE_COMMAND sell_command;
            sell_command._symbol = final_name;
            sell_command._magic = MagicNumber;
            sell_command._sl = 0;//FRACTREND_1.dblBuyDnRange - sl_x_pip * pips(strSymbol);
            EnterSell(sell_command);
            /*
            //use crude for pip
            double new_adjusted_lots = LotSize;
            int sl_pip = MM.intSlPipPerPerMoney(SL_Money_Value,symbol,new_adjusted_lots);
            new_adjusted_lots = LotSize; //aim to reset to 0
            int tp_pip = MM.intSlPipPerPerMoney(TP_Money_Value,symbol,new_adjusted_lots);
            double sl=xAsk + sl_pip * pips(symbol);//(StopLoss*SymbolInfoDouble(symbol,SYMBOL_POINT)*xecn);
            double tp=xAsk - tp_pip * pips(symbol);//(TakeProfit*SymbolInfoDouble(symbol,SYMBOL_POINT)*xecn);
            if(CloseOnReversal) {
               CloseAll(1,final_name);
            }
            
            //Alert("SELL SL PIP is ",sl_pip);
            //Alert("SELL TP PIP is ",tp_pip);
            Alert("Pre-enter Trade Sell Trade Number is ",trade_number(2,final_name));
            if(trade_number(2,final_name) < Max_Sell)  OrderSend(final_name,OP_SELL,new_adjusted_lots,xBid,20,sl,tp,"",MagicNumber);
            */
         }
         if(ArraySize(cmd)>1 && cmd[0]=="CLOSE") {
            /*
            for(int i=0;i<OrdersTotal();i++) {
               bool b=OrderSelect(i,SELECT_BY_POS);
               if(b && OrderType()==OP_BUY && OrderMagicNumber()==MagicNumber && (cmd[1]=="BUY" || cmd[1]=="SELL")) {
                  OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),30);
               }
               if(b && OrderType()==OP_SELL && OrderMagicNumber()==MagicNumber && (cmd[1]=="SELL" || cmd[1]=="SELL")) {
                  OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),30);
               }
            }
            */
         }
      } while (strCommand != "");
      if (!pClient.IsSocketConnected() || bForceQuit) {
         Print("Relay has disconnected");
         delete pClient;
         disconnected=true;
      }
   }
}

void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   if (id == CHARTEVENT_KEYDOWN) {    
      if (lparam == glbServerSocket.GetSocketHandle()) {
         // Activity on server socket. Accept new connections
         Print("New server socket event - incoming connection");
         AcceptNewConnections();

      } else {
         // Compare lparam to each client socket handle
         for (int i = 0; i < ArraySize(glbClients); i++) {
            if (CheckPointer(glbClients[i]) != POINTER_INVALID &&  lparam == glbClients[i].GetSocketHandle()) {
               HandleSocketIncomingData(i);
               return; // Early exit
            }
         }
      }
      /*
      if (lparam == glbClientSocket.GetSocketHandle()) {
         HandleSocketIncomingData();
      } else {
      }
      */
   }
   
}

double dblAverageEntryPrices(int magic, int order_type, string symbol)
{
    //OUTPUT : 0 / Entry Price
    double sum_entry = 0;
    int    total_entry = 0;
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
           if(
              TRADE._terminal_trades[i]._active       == true      &&
              TRADE._terminal_trades[i]._order_symbol == symbol &&
              TRADE._terminal_trades[i]._order_type   == order_type
             )
           {
                 sum_entry += TRADE._terminal_trades[i]._entry;
                 total_entry++;
           }
    }
    if(total_entry==0) return(0);
    return(sum_entry/total_entry);
}

void CloseAll(string symbol)
{
     TRADE_COMMAND BUY_CLOSE;
     BUY_CLOSE._action = MODE_TCLSE;
     BUY_CLOSE._symbol = symbol;
     BUY_CLOSE._order_type = 0;
     BUY_CLOSE._magic  = 0;
     
     
     TRADE_COMMAND SELL_CLOSE;
     SELL_CLOSE._action = MODE_TCLSE;
     SELL_CLOSE._symbol = symbol;
     SELL_CLOSE._order_type = 1;
     SELL_CLOSE._magic  = 0;
     //Print("Prepare Close Here");
     TRADE.CloseTradeAction(BUY_CLOSE);
     TRADE.CloseTradeAction(SELL_CLOSE);
}

void ChangeTp()
{
    for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
    {
        //Print("Monitoring Sl Tp");
        if(TRADE._terminal_trades[i]._active == true)
        {
            double buy_tp_price  = dblAverageEntryPrices(TRADE._terminal_trades[i]._magic_number,0,TRADE._terminal_trades[i]._order_symbol) + TP_Pip * pips(TRADE._terminal_trades[i]._order_symbol);
            double sell_tp_price = dblAverageEntryPrices(TRADE._terminal_trades[i]._magic_number,1,TRADE._terminal_trades[i]._order_symbol) - TP_Pip * pips(TRADE._terminal_trades[i]._order_symbol);
            if(buy_tp_price != 0 && TRADE._terminal_trades[i]._order_type == 0 && TRADE._terminal_trades[i]._take_profit != buy_tp_price)
            {
                 TRADE._terminal_trades[i]._take_profit = buy_tp_price;
            }
            if(sell_tp_price != 0 && TRADE._terminal_trades[i]._order_type == 0 && TRADE._terminal_trades[i]._take_profit != sell_tp_price)
            {
                 TRADE._terminal_trades[i]._take_profit = sell_tp_price;
            }
        }
    }
}

void MonitorTp(bool long_allowed=true, bool short_allowed=true)
{
    TRADE_LIST trade_to_reverse_list[];
    //Print("Check Monitor SL TP");
    //if(this.StealthMode == true)
    //{
         //LOOP AGAIN TO CHECK THE ORDER STOP LOSS IF IN STEALTH MODE
         for(int i = 0; i < ArraySize(TRADE._terminal_trades); i++)
         {
              //Print("Monitoring Sl Tp");
              if(TRADE._terminal_trades[i]._active == true)
              {
                    if(Use_MM)
                    {
                       
                        //if(money_management_mode==YOAV_MODE)this.YoavTrade(this._terminal_trades[i]);
                        
                    }
                    //Check Active Trade Stop Loss TP
                    if(TRADE._terminal_trades[i]._order_type == 0) //buy trade
                    {
                         if(long_allowed == false) return;
                         if( TRADE._terminal_trades[i]._take_profit > 0 &&
                             MarketInfo(TRADE._terminal_trades[i]._order_symbol,MODE_BID) >= TRADE._terminal_trades[i]._take_profit
                           )
                         {
                               //double win_profit  = TRADE.dblTotalWinningProfit(TRADE._terminal_trades[i]._order_symbol,0);
                               //double loss_profit = TRADE.dblTotalLossingProfit(TRADE._terminal_trades[i]._order_symbol,0);
                               //if(win_profit > InpMultFloatLossReturn * MathAbs(loss_profit)) 
                               //{
                                  if(!OrderClose(TRADE._terminal_trades[i]._ticket_number,TRADE._terminal_trades[i]._order_lot,
                                                MarketInfo(TRADE._terminal_trades[i]._order_symbol,MODE_BID),TRADE.intSlippage))
                                  {
                                      Alert("Failed to Close BUY Trade of Ticket ID ",TRADE._terminal_trades[i]._ticket_number);
                                  }
                                  /*
                                  if(TRADE._terminal_trades[i]._ticket_number == 15)
                                  {
                                     Alert("Win Profit is ",win_profit);
                                     Alert("Loss Profit is ",loss_profit);
                                     ExpertRemove();
                                  }
                                  */
                                  else
                                  {
                                    Alert("Buy Trade Close Due To Profit with Tp of ",TRADE._terminal_trades[i]._take_profit);
                                    TRADE._terminal_trades[i]._active = false;
                                    CloseAll(TRADE._terminal_trades[i]._order_symbol); //HERE
                                  }
                              //} 
                         
                         }
                         
                    }
                    if(TRADE._terminal_trades[i]._order_type == 1) //sell trade
                    {
                         if(short_allowed == false) return;
                         if(  
                              TRADE._terminal_trades[i]._take_profit > 0 &&
                              MarketInfo(TRADE._terminal_trades[i]._order_symbol,MODE_ASK) <= TRADE._terminal_trades[i]._take_profit
                           )
                         {
                               
                               //double win_profit  = TRADE.dblTotalWinningProfit(TRADE._terminal_trades[i]._order_symbol,0);
                               //double loss_profit = TRADE.dblTotalLossingProfit(TRADE._terminal_trades[i]._order_symbol,0);
                               //if(win_profit > InpMultFloatLossReturn * MathAbs(loss_profit)) 
                               //{
                                  if(!OrderClose(TRADE._terminal_trades[i]._ticket_number,TRADE._terminal_trades[i]._order_lot,
                                             MarketInfo(TRADE._terminal_trades[i]._order_symbol,MODE_ASK),TRADE.intSlippage))
                                    {
                                         Alert("Failed to Close SELL Trade of Ticket ID ",TRADE._terminal_trades[i]._ticket_number);
                                    }
                                  else
                                  {
                                     Alert("Sell Trade Close Due To Profit with Tp of ",TRADE._terminal_trades[i]._take_profit);
                                    TRADE._terminal_trades[i]._active = false;
                                    CloseAll(TRADE._terminal_trades[i]._order_symbol); //HERE
                                  }
                                  /*
                                  if(TRADE._terminal_trades[i]._ticket_number == 15)
                                  {
                                     Alert("Win Profit is ",win_profit);
                                     Alert("Loss Profit is ",loss_profit);
                                     ExpertRemove();
                                  }
                                  */
                               //}
                         }
                         
                    }
              }
         }
    //}
    
    
    
}


double dblPyramidLots(TRADE_COMMAND &trade, double pos_dev_pip=20, double neg_dev_pip=20)
{
    //OUTPUT : DBL_MIN / Lots Value
    int    type = trade._order_type;
    double lot = trade._lots;
    double avg_price = dblAverageEntryPrices(trade._magic,type,trade._symbol);
    if(avg_price == 0) return(lot); //return to init lot for first trade
    double diff = MathAbs(trade._entry - avg_price)/pips(trade._symbol);
    if(type == 0)
    {
         if(trade._entry < avg_price && diff > neg_dev_pip) return(0);
         if(trade._entry > avg_price && diff > pos_dev_pip) return(0);
    }
    if(type == 1)
    {
         //Print("Sell Entry is ",trade._entry);
         //Print("Sell Average Entry is ",avg_price);
         //Print("Sell Diff is ",diff);
         if(trade._entry < avg_price && diff > pos_dev_pip) return(0);
         if(trade._entry > avg_price && diff > neg_dev_pip) return(0);
    }
    return(lot);
}

void EnterBuy(TRADE_COMMAND &signal)
{
    //if(TRADE.intTotalBuyCount(signal._symbol,signal._magic) >= 1) return; //HERE
    if(Single_Direction && TRADE.intTotalSellCount(signal._symbol,signal._magic) > 0) return;
    signal._action  = MODE_TOPEN;
    double ask = MarketInfo(signal._symbol,MODE_ASK);
    signal._entry   = ask;
    signal._sl      = signal._sl == 0 ? ask - sl_x_pip * pips(signal._symbol) : signal._sl;
    Print("Buy strategy stop loss is ",signal._sl);
    signal._order_type = 0;
    double sl_point = signal._entry - signal._sl;
    double sl_pip   = sl_point / pips(signal._symbol);
    // HERE signal._lots    = dblMaxLotInLoss(signal._magic) == DBL_MIN ? dblLotCalculate() : dblMaxLotInLoss(signal._magic) * reverse_multiplier;//Lot_Mode == 1 ? fix_lot_size : Lot_Mode == 2 ? MM.dblLotSizePerMoney(money_size,this.strSymbol,sl_pip) :MM.dblLotSizePerRisk(this.strSymbol,sl_pip);
    signal._lots    = Lot_Mode == 1 ? fix_lot_size : Lot_Mode == 2 ? MM.dblLotSizePerMoney(money_size,signal._symbol,sl_pip) : Lot_Mode == 3 ? MM.dblLotSizePerRisk(signal._symbol,sl_pip) : Lot_Mode == 4 ? MM.dblKellyLot(signal._symbol,signal._magic,sl_pip) : MM.dblLot2k(signal._symbol);
    //addon pyramid
    if(Use_Pyramid) signal._lots    = dblPyramidLots(signal,Pyramid_Pos_Pip,Pyramid_Neg_Pip);
    if(signal._lots == 0) return;
    // HERE
    //if (signal._lots > 0.5) return;
    signal._saved_lot = signal._lots;
    signal._tp      = signal._tp == 0;// ? signal._entry + RR_Ratio * sl_point : signal._tp;
    //signal._sl      = 0;
    TRADE.EnterTrade(signal,true);
}

void EnterSell(TRADE_COMMAND &signal)
{
    //if(TRADE.intTotalSellCount(signal._symbol,signal._magic) >= 1) return; //HERE
    if(Single_Direction && TRADE.intTotalBuyCount(signal._symbol,signal._magic) > 0) return;
    signal._action  = MODE_TOPEN;
    double bid = MarketInfo(signal._symbol,MODE_BID);
    signal._entry   = bid;
    Print("Initial signal sl is ",signal._sl);
    signal._sl      = signal._sl == 0 ? bid + sl_x_pip * pips(signal._symbol) : signal._sl;
    Print("Sell 1 pip is ",pips(signal._symbol));
    Print("Sell bid + sl is ",bid + sl_x_pip * pips(signal._symbol));
    Print("Sell strategy stop loss is ",signal._sl);
    signal._order_type = 1;
    double sl_point = signal._sl - signal._entry;
    double sl_pip   = sl_point / pips(signal._symbol);
    // HERE signal._lots    = dblMaxLotInLoss(signal._magic) == DBL_MIN ? dblLotCalculate() : dblMaxLotInLoss(signal._magic) * reverse_multiplier;//Lot_Mode == 1 ? fix_lot_size : Lot_Mode == 2 ? MM.dblLotSizePerMoney(money_size,this.strSymbol,sl_pip) :MM.dblLotSizePerRisk(this.strSymbol,sl_pip);
    signal._lots    = Lot_Mode == 1 ? fix_lot_size : Lot_Mode == 2 ? MM.dblLotSizePerMoney(money_size,signal._symbol,sl_pip) : Lot_Mode == 3 ? MM.dblLotSizePerRisk(signal._symbol,sl_pip) : Lot_Mode == 3 ? MM.dblKellyLot(signal._symbol,signal._magic,sl_pip) : MM.dblLot2k(signal._symbol);
    //addon pyramid
    if(Use_Pyramid) signal._lots    = dblPyramidLots(signal,Pyramid_Pos_Pip,Pyramid_Neg_Pip);
    if(signal._lots == 0) return;
    // HERE
    //if (signal._lots > 0.5) return;
    signal._saved_lot = signal._lots;
    signal._tp      = signal._tp == 0;// ? signal._entry - RR_Ratio * sl_point : signal._tp;
    //signal._sl      = 0;
    TRADE.EnterTrade(signal,true);
}

void TV_run()
{
    if (!glbCreatedTimer) glbCreatedTimer = EventSetMillisecondTimer(TIMER_FREQUENCY_MS);
    ChangeTp();
    MonitorTp();
}
