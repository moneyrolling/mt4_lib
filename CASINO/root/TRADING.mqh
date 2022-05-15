#define  SAME_PRICE_REENTRY true //DOES EA ALLOWED TO REENTER AT THE SAME PRICE
//extern 
string GOLD = "XAUUSD,GOLD"; //IDENTIFIER FOR GOLD, JUST ADD WITH COMMA TO SEPERATE
int slippage = 5;
int CacheMinute = 0; //how many minutes to reopen trade after last loss
//int MAX_BUY  = 1; //HOW MANY TRADES TO ALLOW FOR MAXIMUM BUY
//int MAX_SELL = 1; //HOW MANY TRADES TO ALLOW FOR MAXIMUM SELL




extern int    MAX_TRADE = 4; //default max trade number
extern double BUY_SELL_PERCENT = 50; //default buy sell ratio
double BUY_SELL_RATIO = BUY_SELL_PERCENT/100;
extern int    INP_TIME_ZONE = +2;
extern string start_time = "00:00";
extern string end_time   = "23:00"; 


bool bl_TimeAllowed()
{
    ///GMT TESTING
    int BROKER_TIMEZONE = (int)(TimeCurrent() - TimeGMT())/60/60;
    int TZ_diff         = BROKER_TIMEZONE - INP_TIME_ZONE;
    MqlDateTime desired_time_struc;
    MqlDateTime broker_time_struc;
    datetime broker_time  = TimeCurrent();
    datetime desired_time = TimeCurrent()- (TZ_diff*60*60);
    TimeToStruct(TimeCurrent(),broker_time_struc); // broker time
    TimeToStruct(desired_time ,desired_time_struc); // desired time
    //text seperation
    string sep=":";                
    ushort u_sep;              
    string start_time_arr[];
    string end_time_arr[];
    //--- Get the separator code
    u_sep=StringGetCharacter(sep,0);
    //--- Split the string to substrings
    int start_time_size = StringSplit(start_time,u_sep,start_time_arr);
    int end_time_size   = StringSplit(end_time,u_sep,end_time_arr);
    //Alert("Desired Time Hour is ",desired_time_struc.hour, " with min of ",desired_time_struc.min);
    if (start_time_size == 2 && end_time_size == 2)
    {
         if(desired_time_struc.hour > (int)start_time_arr[0])
         {
              //check end hour
              if(desired_time_struc.hour < (int)end_time_arr[0])
              {
                  return(true);
              }
              if(desired_time_struc.hour == (int)end_time_arr[0] && desired_time_struc.min <= (int)end_time_arr[1])
              {
                  Alert("B ",end_time_arr[1]);
                  return(true);
              }
         }
         if(desired_time_struc.hour == (int)start_time_arr[0] && desired_time_struc.min >= (int)start_time_arr[1])
         {
             //check end hour
             //check end hour
              if(desired_time_struc.hour < (int)end_time_arr[0])
              {
                  return(true);
              }
              if(desired_time_struc.hour == (int)end_time_arr[0] && desired_time_struc.min <= (int)end_time_arr[1])
              {
                  return(true);
              }
         }
    }
    return(false);
}

int int_InstrumentType(string strInputSymbol)
{
    //1 FX; 2 METAL; 3 INDICES
    int contract_size = (int)MarketInfo(strInputSymbol, MODE_LOTSIZE);
    int type = 0;
    switch(contract_size)
    {
        case 100000:
            type = 1;
            break;
        
        case 100:
            type = 2;
            break;
        
        case 1:
            type = 2;
            break;
    }
    return(type);
}


bool bl_IsGold (string strInputSymbol)
{
   //function is to check whether the symbol is gold
   string symbols[];
   string sep=",";
   ushort u_sep; 
   u_sep=StringGetCharacter(sep,0);
   int size=StringSplit(GOLD,u_sep,symbols);
   for(int i = 0; i < size; i++)
   {
       if(strInputSymbol == symbols[i])
       {
           return(true);
       }
   }
   return(false);
}

double pips (string symbol)
{
   double _point = MarketInfo(symbol,MODE_POINT);
   int    _digit = (int)MarketInfo(symbol,MODE_DIGITS);  
   //Print("Symbol ",symbol, " with digit ",_digit);
   if(_digit == 3 || _digit == 5) 
   {
      _point*=10;
   }
   if(bl_IsGold(symbol))
   {
     _point = _point * 10;
   }
   return(_point);
}

enum TRADE_ACTION
{
   MODE_TOPEN = 0,
   MODE_TCHNG = 1,
   MODE_TCLSE = 2,
   MODE_TDLTE = 3
};

struct TRADE_COMMAND // 
{
   int     _action; // default is setting to 0, which mean to open trade; 1 is for MODIFY; 2 is CLOSE; 3 os for delete
   int     _order_type; //0 - OP_BUY; 1 - OP_SELL; 2 - OP_BUYLIMIT; 3 - OP_SELLLIMIT; 4 - OP_BUYSTOP; 5 - OP_SELLSTOP
   string  _symbol;
   double  _lots;
   double  _entry;
   double  _sl;
   double  _tp;
   int     _magic;
   int     _ticket_number;
   string  _comment;
   //BREAKEVEN 
   int     _breakeven_mode;
   double  _breakeven_input;
   //TRAILING
   int     _trailing_mode; // 1 standard trailing by Fixed Pip, 2 trailing by User Input SL
   double  _trailing_input; //if mode is 1, the responding variable will be pip, if 2 then factor
   TRADE_COMMAND() : _action(-1),_order_type(-1),_symbol(""),_lots(0),_entry(0),_sl(0),_tp(0),_magic(0),_comment(""),
                     _breakeven_mode(0),_breakeven_input(0),
                     _trailing_mode(0),_trailing_input(0)
                     {};
};

struct TRADE_LIST
  {
   int               _order_type; //0 - OP_BUY; 1 - OP_SELL; 2 - OP_BUYLIMIT; 3 - OP_SELLLIMIT; 4 - OP_BUYSTOP; 5 - OP_SELLSTOP
   int               _ticket_number;
   string            _order_symbol;
   double            _order_lot;
   double            _open_price;
   double            _close_price;
   double            _entry;
   double            _stop_loss;
   double            _take_profit;
   double            _order_profit;
   double            _order_swap;
   double            _order_comission;
   datetime          _order_opened_time;
   datetime          _order_closed_time;
   datetime          _order_expiry;
   int               _magic_number;
   string            _order_comment;
   TRADE_LIST() : _order_type(-1),_ticket_number(0),_order_symbol(""),_order_lot(0),
                  _open_price(0),_close_price(0),_entry(0),_stop_loss(0),
                  _take_profit(0),_order_profit(0),_order_swap(0),_order_comission(0),
                  _order_opened_time(0),_order_closed_time(0),_order_expiry(0),_magic_number(0),
                  _order_comment("")  {}; //INITIALIZE DEFAULT WITH ZERO VALUE
  };
  
class clsTradeClass 
{
   public:
      clsTradeClass();
      ~clsTradeClass();
      void   Init();
      void   TradeLimitReset();//reset trade limit on each different symbol pair run
      void   Updater();
      bool   blCheckRequirement(TRADE_COMMAND &new_order);
      bool   blCheckBuy();
      bool   blCheckSell();
      bool   EnterTrade(TRADE_COMMAND &new_order);
      void   CloseTrade(TRADE_COMMAND &trade);
      void   TrailTrade(TRADE_COMMAND &trade);
      void   BreakEven(TRADE_COMMAND &trade);
      void   ModifySlTp(TRADE_COMMAND &trade);
      void   ModifyMultipleTp(TRADE_COMMAND &trade, string &tp_list[], double sl);
      void   CloseAfterBar(int intInputBar, int intInputPeriod, string strInputSymbol);
      void   UpdateMaxTrade(int intInputMaxTrade);
      int    intMaxTrade;
      int    intMaxBuy;
      int    intMaxSell;
      double dblBuySellRatio;
      bool   blMagicMatch(int intInputMagicType, int intMagic);
      //ARRAY
      TRADE_LIST        _historical_trades[];
      TRADE_LIST        _terminal_trades[];
   protected:
      void   UpdateHistory();
      void   UpdateTerminal();
      bool   blCheckTradeChanges();
      bool   blCheckDuplicate(TRADE_COMMAND &new_order);
      bool   blCheckTimeAllowed(TRADE_COMMAND &new_order);
      bool   blCheckTradeNumber(TRADE_COMMAND &new_order);
      int    intTotalBuyCount(string strSymbol, int intMagic);
      int    intTotalSellCount(string strSymbol, int intMagic);
      int    intTotalTradeByMagic(int intMagic);
      
   private:
      int    intOrderTypeCheck(int intInputType);
      int    intSlippage;
      int    intDelayTime;
      bool   blSymbolCheck(string strCounterCheckSymbol, string strInputSymbol);
      //CUSTOMIZED FUNCTION
      void   BreakEvenAtTp1();
};

clsTradeClass::clsTradeClass()
{
    this.Init();
}

clsTradeClass::~clsTradeClass(){}

void clsTradeClass::Init(){
    this.UpdateHistory();
    this.UpdateTerminal();
    this.intSlippage = slippage;
    this.intDelayTime = CacheMinute;
    this.dblBuySellRatio = BUY_SELL_RATIO;
    this.UpdateMaxTrade(MAX_TRADE); 
}

void clsTradeClass::TradeLimitReset(void)
{
    this.UpdateMaxTrade(MAX_TRADE); 
    this.dblBuySellRatio = BUY_SELL_RATIO;
}

void clsTradeClass::UpdateMaxTrade(int intInputMaxTrade)
{
    this.intMaxTrade = intInputMaxTrade;
    #ifdef BUY_SELL_BALANCE 
      
      this.intMaxBuy  = (int)(this.intMaxTrade * this.dblBuySellRatio);
      this.intMaxSell = (int)(this.intMaxTrade * this.dblBuySellRatio);
      Print("Buy Sell Balance with Max Trade ",this.intMaxTrade, " Max Buy of ",this.intMaxBuy);
      Print("Buy Sell Balance with Max Trade ",this.intMaxTrade, " Max Buy of ",this.intMaxSell);
      Print("Buy Sell Ratio is ",this.dblBuySellRatio);
      Print("Half of 2 is ",(double)2*this.dblBuySellRatio);
      if(MathMod(this.intMaxTrade,2)!=0)
      {
          this.intMaxBuy  += 1;
          this.intMaxSell += 1;
      }
      
    #else
      this.intMaxBuy  = this.intMaxTrade;
      this.intMaxSell = this.intMaxTrade;
    #endif 
    Print("Max Buy Is ",this.intMaxBuy);
    Print("Max Sell Is ",this.intMaxSell);
}

void clsTradeClass::Updater()
{
     if(this.blCheckTradeChanges())
     {
        this.UpdateHistory();
        this.UpdateTerminal();
     }
}

int clsTradeClass::intTotalBuyCount(string strSymbol, int intMagic)
{
    int size = ArraySize(this._terminal_trades);
    int count = 0;
    if(size > 0)
    {
       for(int i = 0; i < size; i++)
       {
           if(strSymbol=="")
           {
              if(this._terminal_trades[i]._order_type == 0 ||
                 this._terminal_trades[i]._order_type == 2 ||
                 this._terminal_trades[i]._order_type == 4
                )
                {count++;}
           }
           else
           {
                if(this._terminal_trades[i]._order_symbol == strSymbol)
                {
                       if(this._terminal_trades[i]._order_type == 0 ||
                          this._terminal_trades[i]._order_type == 2 ||
                          this._terminal_trades[i]._order_type == 4
                         )
                         {count++;}
                }
           }
       }
    }
    return(count);
}

int clsTradeClass::intTotalSellCount(string strSymbol, int intMagic)
{
    int size = ArraySize(this._terminal_trades);
    int count = 0;
    if(size > 0)
    {
       for(int i = 0; i < size; i++)
       {
           if(strSymbol=="")
           {
              if(this._terminal_trades[i]._order_type == 1 ||
                 this._terminal_trades[i]._order_type == 3 ||
                 this._terminal_trades[i]._order_type == 5
                )
                {count++;}
           }
           else
           {
                 if(strSymbol==this._terminal_trades[i]._order_symbol)
                 {
                    if(this._terminal_trades[i]._order_type == 1 ||
                       this._terminal_trades[i]._order_type == 3 ||
                       this._terminal_trades[i]._order_type == 5
                      )
                      {count++;}
                 }
           }
       }
    }
    return(count);
}

bool clsTradeClass::blCheckTradeNumber(TRADE_COMMAND &new_order)
{
    //TRUE MEANING ALLOWED
    if(this.intOrderTypeCheck(new_order._order_type) == 1)
    {
        #ifdef BUY_SELL_BALANCE 
           if(this.intTotalBuyCount(new_order._symbol, new_order._magic) < this.intMaxBuy)
           {
               return(true);
           }
        #else
           if(this.intTotalBuyCount(new_order._symbol, new_order._magic) + this.intTotalSellCount(new_order._symbol, new_order._magic) < this.intMaxTrade)
           {
               return(true);
           }
        #endif 
    }
    if(this.intOrderTypeCheck(new_order._order_type) == 2)
    {
        #ifdef BUY_SELL_BALANCE 
           if(this.intTotalSellCount(new_order._symbol, new_order._magic) < this.intMaxSell)
           {
               return(true);
           }
        #else
           if(this.intTotalSellCount(new_order._symbol, new_order._magic) + this.intTotalBuyCount(new_order._symbol, new_order._magic) < this.intMaxTrade)
           {
               return(true);
           }
        #endif
    }
    return(false);
}

bool clsTradeClass::blSymbolCheck(string strCounterCheckSymbol, string strInputSymbol)
{
    if(strInputSymbol == "") return(true);
    else{
        if(strInputSymbol == strCounterCheckSymbol) return(true);
    }
    return(false);
}


int clsTradeClass::intOrderTypeCheck(int intInputType)
{
    if(intInputType == 0 ||
       intInputType == 2 ||
       intInputType == 4 
      )
    {return(1);}
    if(intInputType == 1 ||
       intInputType == 3 ||
       intInputType == 5 
      )
    {return(2);}
     return(-1);
}

bool clsTradeClass::blCheckDuplicate(TRADE_COMMAND &new_order)
{
    
    if(SAME_PRICE_REENTRY) {return(false);}
    else
    {
       int size = ArraySize(this._terminal_trades);
       if(size > 0)
       {
          for(int i = 0; i < size; i++)
          {
              if(
                 this.intOrderTypeCheck(new_order._order_type) ==  this.intOrderTypeCheck(this._terminal_trades[i]._order_type)   &&
                 new_order._symbol     ==  this._terminal_trades[i]._order_symbol &&
                 new_order._magic      ==  this._terminal_trades[i]._magic_number &&
                 new_order._entry      ==  this._terminal_trades[i]._entry //&&
                 
                )
              {
                  return(true);  
              }
          }
       }
    }
    return(false);
}

bool clsTradeClass::blCheckTimeAllowed(TRADE_COMMAND &new_order)
{
    //TRUE MEANING TIME ALLOWED
    int size = ArraySize(this._historical_trades);
    if(size > 0)
    {
       for(int i = 0; i < size; i++)
       {
           if(this._historical_trades[i]._order_symbol == new_order._symbol)
           {
               if(TimeCurrent() - this._historical_trades[i]._order_closed_time <  this.intDelayTime * 60)
               {
                   return(false);
               }
           }
       }
    }
    return(true);
}

bool clsTradeClass::blCheckRequirement(TRADE_COMMAND &new_order)
{
    //PRE-CHECK CRITICAL ERROR
    
    if(new_order._entry == 0 || new_order._lots == 0 || new_order._order_type == -1 ||
       new_order._action != MODE_TOPEN
      )
    {
       Print("Trade Critical Parameter Not Complete, please check");
       return(false);
    }
     
    if(this.blCheckDuplicate(new_order) == false  &&  //no duplicate trade
       this.blCheckTradeNumber(new_order) == true &&  //trade number not exceed
       this.blCheckTimeAllowed(new_order) == true     //time allowed
      )
    {
        //Print(new_order._symbol," Checking Order Type ",new_order._order_type, " with price of ",new_order._entry);
        return(true);
    }
    return(false);
}

bool clsTradeClass::EnterTrade(TRADE_COMMAND &new_order)
{
    this.Updater();
    //Print("A");
    if(this.blCheckRequirement(new_order))
    {    
         //Print("B");
         //return;
         //Print(new_order._symbol," Checking Order Type ",new_order._order_type);
         //return;
         if(this.intOrderTypeCheck(new_order._order_type)==1)
         {    
              /*
              if(DMA_MODE)
              {
                  if(!OrderSend(new_order._symbol,OP_BUY,new_order._lots,MarketInfo(new_order._symbol,MODE_ASK),this.intSlippage,new_order._sl,new_order._tp,new_order._comment,new_order._magic))
                  {
                       Print("DMA Buy Market Order Placed Failed with Error Code ",GetLastError());
                  }
                  else {return(true);}
              }
              */
              //else
              //{
         
                 if(new_order._entry > MarketInfo(new_order._symbol,MODE_ASK))
                 {
                     if(!OrderSend(new_order._symbol,OP_BUYSTOP,new_order._lots,new_order._entry,this.intSlippage,new_order._sl,new_order._tp,new_order._comment,new_order._magic))
                     {
                         Print("Buy Stop Order Placed Failed with Error Code ",GetLastError());
                     }
                     else {return(true);}
                 }
                 else
                 {
                     if(new_order._entry == MarketInfo(new_order._symbol,MODE_ASK))
                     {  
                        if(!OrderSend(new_order._symbol,OP_BUY,new_order._lots,new_order._entry,this.intSlippage,new_order._sl,new_order._tp,new_order._comment,new_order._magic))
                        {
                             Print("Buy Market Order Placed Failed with Error Code ",GetLastError());
                        }
                        else {return(true);}
                     }
                     else
                     {
                           if(new_order._entry < MarketInfo(new_order._symbol,MODE_ASK))
                           {  
                              if(!OrderSend(new_order._symbol,OP_BUYLIMIT,new_order._lots,new_order._entry,this.intSlippage,new_order._sl,new_order._tp,new_order._comment,new_order._magic))
                              {  
                                  Print("Buy Limit Order Placed Failed with Error Code ",GetLastError());
                              }
                              else {return(true);}
                           }
                     }
                 }
              //}
         }
         else
         {
               if(this.intOrderTypeCheck(new_order._order_type)==2)
               {
                    /*
                    if(DMA_MODE)
                    {
                       if(!OrderSend(new_order._symbol,OP_SELL,new_order._lots,MarketInfo(new_order._symbol,MODE_BID),this.intSlippage,new_order._sl,new_order._tp,new_order._comment,new_order._magic))
                        {
                             Print("DMA Sell Market Order Placed Failed with Error Code ",GetLastError());
                        }
                        else {return(true);}
                    }
                    */
                    //else
                    //{
                       if(new_order._entry > MarketInfo(new_order._symbol,MODE_BID))
                       {
                           if(!OrderSend(new_order._symbol,OP_SELLLIMIT,new_order._lots,new_order._entry,this.intSlippage,new_order._sl,new_order._tp,new_order._comment,new_order._magic))
                           {
                               Print("Sell Limit Order Placed Failed with Error Code ",GetLastError());
                           }
                           else {return(true);}
                       }
                       else
                       {
                           if(new_order._entry == MarketInfo(new_order._symbol,MODE_BID))
                           {
                              if(!OrderSend(new_order._symbol,OP_SELL,new_order._lots,new_order._entry,this.intSlippage,new_order._sl,new_order._tp,new_order._comment,new_order._magic))
                              {
                                   Print("Sell Market Order Placed Failed with Error Code ",GetLastError());
                              }
                              else {return(true);}
                           }
                           else
                           {
                                 if(new_order._entry < MarketInfo(new_order._symbol,MODE_BID))
                                 {
                                    if(!OrderSend(new_order._symbol,OP_SELLSTOP,new_order._lots,new_order._entry,this.intSlippage,new_order._sl,new_order._tp,new_order._comment,new_order._magic))
                                    {
                                        Print("Sell Stop Order Placed Failed with Error Code ",GetLastError());
                                    }
                                    else {return(true);}
                                 }
                           }
                       }
                    //}
               }
         }
    }
    return(false);
}

void clsTradeClass::UpdateHistory()
{
     ArrayFree(this._historical_trades);
      for(int i = OrdersHistoryTotal(); i >= 0 ; i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
           {
            int size = ArraySize(this._historical_trades);
            ArrayResize(this._historical_trades,ArraySize(this._historical_trades)+1);
            this._historical_trades[size]._order_type        = OrderType();
            this._historical_trades[size]._ticket_number     = OrderTicket();
            this._historical_trades[size]._order_symbol      = OrderSymbol();
            this._historical_trades[size]._order_lot         = OrderLots();
            this._historical_trades[size]._open_price        = OrderOpenPrice();
            this._historical_trades[size]._close_price       = OrderClosePrice();
            this._historical_trades[size]._entry             = OrderOpenPrice();
            this._historical_trades[size]._stop_loss         = OrderStopLoss();
            this._historical_trades[size]._take_profit       = OrderTakeProfit();
            this._historical_trades[size]._order_profit      = OrderProfit();
            this._historical_trades[size]._order_swap        = OrderSwap();
            this._historical_trades[size]._order_comission   = OrderCommission();
            this._historical_trades[size]._order_opened_time = OrderOpenTime();
            this._historical_trades[size]._order_closed_time = OrderCloseTime();
            this._historical_trades[size]._order_expiry      = OrderExpiration();
            this._historical_trades[size]._magic_number      = OrderMagicNumber();
            this._historical_trades[size]._order_comment     = OrderComment();
           }
        }
}

void clsTradeClass::UpdateTerminal()
{
    ArrayFree(this._terminal_trades);
      for(int i = OrdersTotal(); i >= 0 ; i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
           {
            int size = ArraySize(this._terminal_trades);
            ArrayResize(this._terminal_trades,ArraySize(this._terminal_trades)+1);
            this._terminal_trades[size]._order_type        = OrderType();
            this._terminal_trades[size]._ticket_number     = OrderTicket();
            this._terminal_trades[size]._order_symbol      = OrderSymbol();
            this._terminal_trades[size]._order_lot         = OrderLots();
            this._terminal_trades[size]._open_price        = OrderOpenPrice();
            this._terminal_trades[size]._close_price       = OrderClosePrice();
            this._terminal_trades[size]._entry             = OrderOpenPrice();
            this._terminal_trades[size]._stop_loss         = OrderStopLoss();
            this._terminal_trades[size]._take_profit       = OrderTakeProfit();
            this._terminal_trades[size]._order_profit      = OrderProfit();
            this._terminal_trades[size]._order_swap        = OrderSwap();
            this._terminal_trades[size]._order_comission   = OrderCommission();
            this._terminal_trades[size]._order_opened_time = OrderOpenTime();
            this._terminal_trades[size]._order_closed_time = OrderCloseTime();
            this._terminal_trades[size]._order_expiry      = OrderExpiration();
            this._terminal_trades[size]._magic_number      = OrderMagicNumber();
            this._terminal_trades[size]._order_comment     = OrderComment();
           }
        }
}

bool clsTradeClass::blCheckTradeChanges()
{
   static int total_hist_trade = OrdersHistoryTotal();
   static int total_live_trade = OrdersTotal();
   if(OrdersHistoryTotal() != total_hist_trade)
   {
     total_hist_trade = OrdersHistoryTotal();
     return(true);
   }
   if(OrdersTotal() != total_live_trade)
   {
     total_live_trade = OrdersTotal();
     return(true);
   }
   return(false);
}


bool clsTradeClass::blMagicMatch(int intInputMagicType, int intMagic)
{
   //( -1 = Both manual and EA, 0 = Manual, 1 = EA)
   switch(intInputMagicType)
   {
        case -1: 
            return(true);
            break;
        case 0:
            if(intMagic == 0)
            {
                return(true);
            }
            break;
        case 1:
            if(intMagic > 0)
            {
                return(true);
            }
            break;
   }
   return(false);
}

//example use for BREAKEVEN
//trade._action = MODE_TCHNG; trade._breakeven_mode = 1; trade._breakeven_input = 20; trade._symbol = "" //to loop all


void clsTradeClass::BreakEven(TRADE_COMMAND &trade)
{
    //Print("Breakeven Mode is ",trade._breakeven_mode);
   //pre-evaluation for critical error
   if(trade._action != MODE_TCHNG ||
      trade._breakeven_mode  == 0 ||
      trade._breakeven_input == 0 ||
      trade._symbol         == "" 
     )
     {
         Print("Please Check with the Breakeven Input Before Proceed");
         return;
     }
   
   for(int i = 0; i < ArraySize(this._terminal_trades); i++)
   {
       if(this.blSymbolCheck(this._terminal_trades[i]._order_symbol,trade._symbol))
       {
            //Print("AA");
           double latest_price;
           switch(this._terminal_trades[i]._order_type)
           {
               case 0:  // buy
                  //Print("BB");
                  latest_price = MarketInfo(this._terminal_trades[i]._order_symbol,MODE_BID);
                  switch(trade._breakeven_mode)
                  {
                      case 1 :  // by pip
                         //Print("CC");
                         if(latest_price - this._terminal_trades[i]._open_price > trade._breakeven_input * pips(this._terminal_trades[i]._order_symbol) &&
                            this._terminal_trades[i]._stop_loss < this._terminal_trades[i]._entry
                           )
                         {
                                //Print("DD");
                                if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._open_price,this._terminal_trades[i]._take_profit,
                                            this._terminal_trades[i]._order_expiry))
                                {
                                      Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                }
                         }
                         break;
                      
                      case 2 :  // by factor
                         if(latest_price - this._terminal_trades[i]._open_price > trade._breakeven_input * (this._terminal_trades[i]._open_price - this._terminal_trades[i]._stop_loss) &&
                            this._terminal_trades[i]._stop_loss < this._terminal_trades[i]._entry
                           )
                         {
                                if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._open_price,this._terminal_trades[i]._take_profit,
                                            this._terminal_trades[i]._order_expiry))
                                {
                                      Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                }
                         }
                         break; 
                      
                      case 3 : //BY TP 3
                         if(latest_price >= StringToDouble(this._terminal_trades[i]._order_comment) &&
                            this._terminal_trades[i]._stop_loss < this._terminal_trades[i]._entry
                           )
                         {
                                if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._open_price,this._terminal_trades[i]._take_profit,
                                            this._terminal_trades[i]._order_expiry))
                                {
                                      Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                }
                         }
                         break; 
                         
                      case 4 : //BY PERCENTAGE
                      //here must be a break even option(true/false) in %, if set to 30% then the EA will adjust the SL to break even when price is 30% up from the open price and 70% away frm the TP
                         if(latest_price - this._terminal_trades[i]._open_price > trade._breakeven_input * 0.01 * (this._terminal_trades[i]._take_profit - this._terminal_trades[i]._open_price) &&
                            this._terminal_trades[i]._stop_loss < this._terminal_trades[i]._entry
                           )
                         {
                                if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._open_price,this._terminal_trades[i]._take_profit,
                                            this._terminal_trades[i]._order_expiry))
                                {
                                      Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                }
                         }
                         break;  
                          
                         
                    
                  }
                  //if(latest_price - this._terminal_trades[i]._open_price 
                  break;
               case 1:  // sell
                  latest_price = MarketInfo(this._terminal_trades[i]._order_symbol,MODE_ASK);
                  switch(trade._breakeven_mode)
                  {
                      case 1 :  // by pip
                         if(this._terminal_trades[i]._open_price - latest_price > trade._breakeven_input * pips(this._terminal_trades[i]._order_symbol) &&
                            this._terminal_trades[i]._stop_loss > this._terminal_trades[i]._entry
                           )
                         {
                                if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._open_price,this._terminal_trades[i]._take_profit,
                                            this._terminal_trades[i]._order_expiry))
                                {
                                      Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                }
                         }
                         break;
                      
                      case 2 :  // by factor
                         if(this._terminal_trades[i]._open_price - latest_price > trade._breakeven_input * (this._terminal_trades[i]._stop_loss - this._terminal_trades[i]._open_price ) &&
                            this._terminal_trades[i]._stop_loss > this._terminal_trades[i]._entry
                           )
                         {
                                if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._open_price,this._terminal_trades[i]._take_profit,
                                            this._terminal_trades[i]._order_expiry))
                                {
                                      Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                }
                         }
                         break; 
                      
                      case 3:  // by TP1
                         if(latest_price <= StringToDouble(this._terminal_trades[i]._order_comment) &&
                            this._terminal_trades[i]._stop_loss > this._terminal_trades[i]._entry
                           )
                         {
                                if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._open_price,this._terminal_trades[i]._take_profit,
                                            this._terminal_trades[i]._order_expiry))
                                {
                                      Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                }
                         }
                         break; 
                         
                     case 4 :  // by percentage here must be a break even option(true/false) in %, if set to 30% then the EA will adjust the SL to break even when price is 30% up from the open price and 70% away frm the TP
                         if(this._terminal_trades[i]._open_price - latest_price > trade._breakeven_input * 0.01 * (this._terminal_trades[i]._open_price - this._terminal_trades[i]._take_profit ) &&
                            this._terminal_trades[i]._stop_loss > this._terminal_trades[i]._entry
                           )
                         {
                                if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._open_price,this._terminal_trades[i]._take_profit,
                                            this._terminal_trades[i]._order_expiry))
                                {
                                      Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                }
                         }
                         break; 
                      
                         
                    
                  }
                  break;
           }
           
       }
   }
}




void clsTradeClass::CloseAfterBar(int intInputBar,int intInputPeriod, string strInputSymbol)
{
      for(int i = 0; i < ArraySize(this._terminal_trades); i++)
      {
          if(this.blSymbolCheck(this._terminal_trades[i]._order_symbol,strInputSymbol))
          {
               if(TimeCurrent() - this._terminal_trades[i]._order_opened_time >= intInputBar * intInputPeriod * 60)
               {
                    switch(this._terminal_trades[i]._order_type)
                    {
                          case 0:
                             if(!OrderClose(
                                          this._terminal_trades[i]._ticket_number,
                                          this._terminal_trades[i]._order_lot,
                                          MarketInfo(this._terminal_trades[i]._order_symbol,MODE_BID),
                                          slippage
                                        ))
                                {Print("Failed to Close Buy Trade With Error Code ",GetLastError());}
                             break;
                         
                         case 1:
                             if(!OrderClose(
                                          this._terminal_trades[i]._ticket_number,
                                          this._terminal_trades[i]._order_lot,
                                          MarketInfo(this._terminal_trades[i]._order_symbol,MODE_ASK),
                                          slippage
                                        ))
                                {Print("Failed to Close Sell Trade With Error Code ",GetLastError());}
                             break;
                    }
               }
          }
      }
}


void clsTradeClass::CloseTrade(TRADE_COMMAND &trade)   //by magic number
{
     //Critical Error Check
     if(trade._action != MODE_TCLSE ||
        trade._symbol == ""         ||
        trade._order_type == -1     ||
        trade._magic  == 0
       )
     {
         Print("Trade Close Input Error, Kindly Check");
         return;
     }
     for(int i = 0; i < ArraySize(this._terminal_trades); i++)
     {
         if(this._terminal_trades[i]._order_symbol == trade._symbol &&
            this._terminal_trades[i]._magic_number == trade._magic
            )
         {
              if(this.intOrderTypeCheck(this._terminal_trades[i]._order_type) ==
                 this.intOrderTypeCheck(this._terminal_trades[i]._order_type)
                )
              {
                  switch(this._terminal_trades[i]._order_type)
                  {
                       case 0: //BUY ORDER
                           if(!OrderClose(this._terminal_trades[i]._ticket_number,
                                      this._terminal_trades[i]._order_lot,
                                      MarketInfo(this._terminal_trades[i]._order_symbol,MODE_BID),
                                      slippage))
                                      {Print(" Close Buy Ticket ",this._terminal_trades[i]._ticket_number,
                                             " with error code of ",GetLastError());}         
                           break;
                       case 1: //SELL ORDER
                           if(!OrderClose(this._terminal_trades[i]._ticket_number,
                                      this._terminal_trades[i]._order_lot,
                                      MarketInfo(this._terminal_trades[i]._order_symbol,MODE_ASK),
                                      slippage))
                                      {Print(" Close Sell Ticket ",this._terminal_trades[i]._ticket_number,
                                             " with error code of ",GetLastError());}   
                           break;
                       case 2: //BUY LIMIT ORDER
                           if(!OrderDelete(this._terminal_trades[i]._ticket_number))
                           {
                                Print("Failed Delete Buy Pending Order with Error Code ",GetLastError());
                           }
                           break;
                       case 3: //SELL LIMIT ORDER
                           if(!OrderDelete(this._terminal_trades[i]._ticket_number))
                           {
                                Print("Failed Delete Sell Pending Order with Error Code ",GetLastError());
                           }
                           break;
                       case 4: //BUY STOP ORDER
                           if(!OrderDelete(this._terminal_trades[i]._ticket_number))
                           {
                                Print("Failed Delete Buy Stop Order with Error Code ",GetLastError());
                           }
                           break;
                       case 5:
                           if(!OrderDelete(this._terminal_trades[i]._ticket_number))
                           {
                                Print("Failed Delete Sell Stop Order with Error Code ",GetLastError());
                           }
                           break;
                           
                  }
              }
         }
     }
}


void clsTradeClass::TrailTrade(TRADE_COMMAND &trade)
{
     //Critical Error Check
     if(trade._action != MODE_TCHNG ||
        trade._trailing_input == 0  ||
        trade._trailing_mode  == 0  ||
        trade._symbol         == "" 
       )
     {
         Print("Trade Trail Input Error, Kindly Check");
     }
     
     for(int i = 0; i < ArraySize(this._terminal_trades); i++)
     {
         if(this._terminal_trades[i]._order_symbol == trade._symbol //&&
            //this._terminal_trades[i]._order_type   == trade._order_type
           )
         {
               //Print("AA");
               double new_sl = 0;
               switch(this._terminal_trades[i]._order_type)
               {
                    case 0: //BUY ORDER
                        //Print("BB");
                        switch(trade._trailing_mode)
                        {
                              case 1://fix trailing pip
                                 //Print("CC");
                                 new_sl = MarketInfo(this._terminal_trades[i]._order_symbol,MODE_BID) - (trade._trailing_input * pips(this._terminal_trades[i]._order_symbol));
                                 if(new_sl > this._terminal_trades[i]._stop_loss || 
                                    this._terminal_trades[i]._stop_loss == 0
                                   )
                                   {    //Print("DD");
                                        if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                                    this._terminal_trades[i]._open_price,
                                                    new_sl,
                                                    this._terminal_trades[i]._take_profit,
                                                    this._terminal_trades[i]._order_expiry
                                                    ))
                                        {
                                             Print("Modify Trailing Buy Ticket ",this._terminal_trades[i]._ticket_number,
                                                   " with error code of ",GetLastError());
                                        }
                                   }
                                    
                                 break;
                              case 2://user predefined sl
                                 new_sl = trade._trailing_input;
                                 if(new_sl > this._terminal_trades[i]._stop_loss ||
                                    this._terminal_trades[i]._stop_loss == 0
                                   )
                                   {
                                        if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                                    this._terminal_trades[i]._open_price,
                                                    new_sl,
                                                    this._terminal_trades[i]._take_profit,
                                                    this._terminal_trades[i]._order_expiry
                                                    ))
                                        {
                                             Print("Modify Trailing Buy Ticket ",this._terminal_trades[i]._ticket_number,
                                                   " with error code of ",GetLastError());
                                        }
                                   }
                                 break;
                               
                               case 3://user predefined percentage trailing
                                 new_sl = NormalizeDouble(MarketInfo(this._terminal_trades[i]._order_symbol,MODE_BID)  * MathAbs(trade._trailing_input * 0.01 - 1),(int)MarketInfo(this._terminal_trades[i]._order_symbol,MODE_DIGITS));
                                 //Print("Buy Current Sl is ",this._terminal_trades[i]._stop_loss);
                                 //Print("Buy new Sl is ",new_sl);
                                 if(new_sl > this._terminal_trades[i]._stop_loss ||
                                    this._terminal_trades[i]._stop_loss == 0
                                   )
                                   {
                                        Print("Trailing new sl is ",new_sl);
                                        if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                                    this._terminal_trades[i]._open_price,
                                                    new_sl,
                                                    this._terminal_trades[i]._take_profit,
                                                    this._terminal_trades[i]._order_expiry
                                                    ))
                                        {
                                             Print("Modify Trailing Buy Ticket ",this._terminal_trades[i]._ticket_number,
                                                   " with error code of ",GetLastError());
                                        }
                                   }
                                 break;
                        }
                        break;
                    case 1: //SELL ORDER
                        switch(trade._trailing_mode)
                        {
                              case 1://fix trailing pip
                                 new_sl = MarketInfo(this._terminal_trades[i]._order_symbol,MODE_ASK) + (trade._trailing_input * pips(this._terminal_trades[i]._order_symbol));
                                 if(new_sl < this._terminal_trades[i]._stop_loss ||
                                    this._terminal_trades[i]._stop_loss == 0
                                   )
                                   {
                                        if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                                    this._terminal_trades[i]._open_price,
                                                    new_sl,
                                                    this._terminal_trades[i]._take_profit,
                                                    this._terminal_trades[i]._order_expiry
                                                    ))
                                        {
                                             Print("Modify Trailing Sell Ticket ",this._terminal_trades[i]._ticket_number,
                                                   " with error code of ",GetLastError());
                                        }
                                   }
                                    
                                 break;
                              case 2://user predefined sl
                                 new_sl = trade._trailing_input;
                                 if(new_sl < this._terminal_trades[i]._stop_loss ||
                                    this._terminal_trades[i]._stop_loss == 0
                                   )
                                   {
                                        if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                                    this._terminal_trades[i]._open_price,
                                                    new_sl,
                                                    this._terminal_trades[i]._take_profit,
                                                    this._terminal_trades[i]._order_expiry
                                                    ))
                                        {
                                             Print("Modify Trailing Sell Ticket ",this._terminal_trades[i]._ticket_number,
                                                   " with error code of ",GetLastError());
                                        }
                                   }
                                 break;
                                 
                              case 3://user predefined percentage trailing
                                 new_sl = NormalizeDouble(MarketInfo(this._terminal_trades[i]._order_symbol,MODE_ASK)  * MathAbs(trade._trailing_input * 0.01 + 1),(int)MarketInfo(this._terminal_trades[i]._order_symbol,MODE_DIGITS));
                                 Print("Sell new Sl is ",new_sl);
                                 if(new_sl < this._terminal_trades[i]._stop_loss ||
                                    this._terminal_trades[i]._stop_loss == 0
                                   )
                                   {
                                        if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                                    this._terminal_trades[i]._open_price,
                                                    new_sl,
                                                    this._terminal_trades[i]._take_profit,
                                                    this._terminal_trades[i]._order_expiry
                                                    ))
                                        {
                                             Print("Modify Trailing Sell Ticket ",this._terminal_trades[i]._ticket_number,
                                                   " with error code of ",GetLastError());
                                        }
                                   }
                                    
                                 break;
                        }
                        break;
               }
         }
     }

}


void clsTradeClass::ModifySlTp(TRADE_COMMAND &trade)
{
     //Critical Error Check
     if(trade._action != MODE_TCHNG ||
        trade._magic  == 0  
       )
     {
         Print("Trade Modify Critical Input Error, Kindly Check");
     }
     if(trade._sl  == 0 &&
        trade._tp  == 0  
       )
     {
         Print("Please Edit Something For Modification");
     }
     
     
      for(int i = 0; i < ArraySize(this._terminal_trades); i++)
      {
          if(this._terminal_trades[i]._magic_number == trade._magic)
          {
                if(trade._sl != 0 && trade._sl != this._terminal_trades[i]._stop_loss)
                {
                      if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                  this._terminal_trades[i]._open_price,
                                  trade._sl,
                                  this._terminal_trades[i]._take_profit,
                                  this._terminal_trades[i]._order_expiry
                                 ))
                      {
                           Print(" Failed to modify Sl for Ticket ",this._terminal_trades[i]._ticket_number);
                      }
                }
                
                if(trade._tp != 0 && trade._tp != this._terminal_trades[i]._take_profit)
                {
                      if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                  this._terminal_trades[i]._open_price,
                                  this._terminal_trades[i]._stop_loss,
                                  trade._tp,
                                  this._terminal_trades[i]._order_expiry
                                 ))
                      {
                           Print(" Failed to modify TP for Ticket ",this._terminal_trades[i]._ticket_number);
                      }
                }
          }
      }
     
}

int  clsTradeClass::intTotalTradeByMagic(int intMagic)
{
     int count = 0;
     for(int i = 0; i < ArraySize(this._terminal_trades); i++)
     {
       if(this._terminal_trades[i]._magic_number == intMagic)
       {
             count++;
       }
     }
     return(count);
}

void  clsTradeClass::ModifyMultipleTp(TRADE_COMMAND &trade, string &tp_list[],double sl)
{
     int no_of_trade = this.intTotalTradeByMagic(trade._magic);
     int j = 0;
     for(int i = 0; i < ArraySize(this._terminal_trades); i++)
     {
       if(this._terminal_trades[i]._magic_number == trade._magic)
       {   
           if(no_of_trade == ArraySize(tp_list))
           {
            if((double)tp_list[j] != 0 && (double)tp_list[j] != this._terminal_trades[i]._take_profit)
            {
                  if(!OrderModify(this._terminal_trades[i]._ticket_number,
                               this._terminal_trades[i]._open_price,
                               this._terminal_trades[i]._stop_loss,
                               (double)tp_list[j],
                               this._terminal_trades[i]._order_expiry
                              ))
                   {
                        Print(" Failed to modify Multiple TP for Ticket ",this._terminal_trades[i]._ticket_number);
                   }
                   if(j < ArraySize(tp_list)) j++;
            }
           }
           else
           {
               if(no_of_trade == 4 && ArraySize(tp_list) == 3)
               {
                   
                   if((double)tp_list[j] != 0 && (double)tp_list[j] != this._terminal_trades[i]._take_profit)
                   {
                        
                        if(!OrderModify(this._terminal_trades[i]._ticket_number,
                               this._terminal_trades[i]._open_price,
                               this._terminal_trades[i]._stop_loss,
                               (double)tp_list[j],
                               this._terminal_trades[i]._order_expiry
                              ))
                         {
                              Print(" Failed to modify Multiple TP for Ticket ",this._terminal_trades[i]._ticket_number);
                         }
                         if(i != 0 && j < 2) j++;
                         //Print("J is ",j,"Next tp is ",tp_list[j]);
                   }
               }
               else
               {
                   if(no_of_trade == 4 && ArraySize(tp_list) == 2)
                  {
                      double tp = i < 2 ? (double)tp_list[0] : (double)tp_list[1];
                      if((double)tp != 0 && (double)tp != this._terminal_trades[i]._take_profit)
                      {
                           
                           if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                  this._terminal_trades[i]._open_price,
                                  this._terminal_trades[i]._stop_loss,
                                  (double)tp,
                                  this._terminal_trades[i]._order_expiry
                                 ))
                            {
                                 Print(" Failed to modify Multiple TP for Ticket ",this._terminal_trades[i]._ticket_number);
                            }
                           
                      }
                  }
               }
           }
           
           //j = j >= ArraySize(tp_list) ? j : j++;
       }
     }
}

