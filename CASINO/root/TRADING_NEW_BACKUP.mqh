#define  SAME_PRICE_REENTRY true //DOES EA ALLOWED TO REENTER AT THE SAME PRICE
#define  COVERALL true //COVER AND MONITOR ALL TRADES (OPEN BY EA AND OTHERS)
//#define STEALTH_MODE
#include "MASTER_CONFIG.mqh"
#include "TRADE_CONFIG.mqh"
#include "READ_WRITE.mqh"
#include "MONEY_MANAGEMENT.mqh"
clsConfig *READ;
enum MM_MODE
{
   RECOVER_MODE  = 0,
   REVERSE_MODE  = 1,
   REVERSE_JIE   = 2,
   ROULETTE_MODE = 3,
   GRID_MODE     = 4,
   ANGRY_MARTIN  = 5
};


int slippage = 5;
int CacheMinute = 0; //how many minutes to reopen trade after last loss
//int MAX_BUY  = 1; //HOW MANY TRADES TO ALLOW FOR MAXIMUM BUY
//int MAX_SELL = 1; //HOW MANY TRADES TO ALLOW FOR MAXIMUM SELL

extern int    MAX_TRADE = 2; //default max trade number
extern double BUY_SELL_PERCENT = 50; //default buy sell ratio
double BUY_SELL_RATIO = BUY_SELL_PERCENT/100;
extern bool    Use_MM = true;
extern MM_MODE money_management_mode = GRID_MODE;
extern bool    mm_forced_close = false;
extern int     mm_max_trade = 4;
extern double reverse_multiplier = 2;
extern double Reverse_RR_Ratio = 1;
extern int    reverse_min_vol_point = 80;
extern int    MAX_GRID_SET_ALLOWED = 1;
extern int    ANGRY_DISTANCE = 30;
extern bool   Use_Compound_Lots = true;
extern bool   Use_Hedge_Close = true;
extern double HEDGE_CRITICAL_LOT_RATIO = 0.5;
extern double HEDGE_CLOSE_MIN_PROFIT_PERCENT = 1;

int    INP_TIME_ZONE = +2;
string start_time = "00:00";
string end_time   = "23:00"; 



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
                  //Alert("B ",end_time_arr[1]);
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

enum TRADE_ACTION
{
   MODE_TOPEN = 0,
   MODE_TCHNG = 1,
   MODE_TCLSE = 2,
   MODE_TDLTE = 3
};




  
class clsTradeClass 
{
   public:
      clsTradeClass();
      ~clsTradeClass();
      void   Init();
      void   TradeLimitReset();//reset trade limit on each different symbol pair run
      void   Updater();
      bool   blCheckRequirement(TRADE_COMMAND &new_order, bool special_mm_mode = false);
      bool   blCheckBuy();
      bool   blCheckSell();
      bool   EnterTrade(TRADE_COMMAND &new_order, bool special_mm_mode = false);
      bool   CloseTrade(TRADE_COMMAND &trade, bool special_mm=false);
      bool   CloseByTicket(int ticket);
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
      double dblPredictedATR();
      double dblCompoundLots(string symbol, int sl_point, int max_cons_loss, double percent_risk);
      //ARRAY
      TRADE_LIST        _historical_trades[];
      TRADE_LIST        _terminal_trades[];
   protected:
      void   UpdateHistory();
      void   UpdateTerminal();
      bool   blCheckTradeClose();
      bool   blCheckDuplicate(TRADE_COMMAND &new_order);
      bool   blCheckTimeAllowed(TRADE_COMMAND &new_order);
      bool   blCheckTradeNumber(TRADE_COMMAND &new_order, bool special_mm_mode = false);
      int    intTotalBuyCount(string strSymbol, int intMagic);
      int    intTotalSellCount(string strSymbol, int intMagic);
      int    intTotalTradeByMagic(int intMagic);
      
   private:
      int    intOrderTypeCheck(int intInputType);
      void   AddTradeToList(int ticket_number, double sl, double tp, TRADE_COMMAND &trade);
      int    intSlippage;
      int    intDelayTime;
      bool   blSymbolCheck(string strCounterCheckSymbol, string strInputSymbol);
      //CUSTOMIZED FUNCTION
      void   BreakEvenAtTp1();
      bool   StealthMode;
      bool   ReverseMode;
      //STEALTH MODE
      void   MonitorSlTp();
      //SPECIAL MM
      void   RecoverTrade(TRADE_LIST &trade);
      void   ReverseTrade(TRADE_LIST &trade);
      void   ReverseJie(TRADE_LIST &trade, int update_type);
      void   RouletteTrade(TRADE_LIST &trade, int update_type);
      bool   GridTrade(TRADE_COMMAND &trade);
      bool   blCheckGridTag(double grid_tag, double &grid_tag_exist_list[]);
      void   GridExit();
      double dblReverseJieLot(TRADE_COMMAND &trade); //auto modify command lot and reverse_jie_source accoridng to jie calculation. Output lot value as reference
      double dblRouletteLot(TRADE_COMMAND &trade);
      bool   blAngryMartinAllowed(TRADE_COMMAND &trade);
      void   HedgeClose();
      bool   MMCheck(TRADE_LIST &trade_list,TRADE_COMMAND &trade_command, MM_MODE mm_mode);
};

clsTradeClass::clsTradeClass()
{
    this.Init();
    READ = new clsConfig();
    READ.ReadIndicator("ATR.csv");
}

double clsTradeClass::dblPredictedATR()
{
    for(int i = 0; i < ArraySize(READ.indicators); i++)
    {
         if(READ.MatchDate(TimeCurrent(),READ.indicators[i].date))
         {
             return(READ.indicators[i].value);
         }
    }
    return(0);
}

clsTradeClass::~clsTradeClass(){
    if(CheckPointer(READ) == POINTER_DYNAMIC) delete READ;
}

void clsTradeClass::Init(){
    this.UpdateHistory();
    this.UpdateTerminal();
    this.intSlippage = slippage;
    this.intDelayTime = CacheMinute;
    this.dblBuySellRatio = BUY_SELL_RATIO;
    this.UpdateMaxTrade(MAX_TRADE); 
    this.StealthMode = false;
    #ifdef STEALTH_MODE
      this.StealthMode = true;
    #endif 
    //if (reverse_mode == true) this.ReverseMode = true;
    
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
     this.UpdateHistory();
     this.UpdateTerminal();
     this.MonitorSlTp();
     if(Use_MM && money_management_mode == GRID_MODE) this.GridExit();
     if(Use_Hedge_Close) this.HedgeClose();
}

double clsTradeClass::dblCompoundLots(string symbol, int sl_point, int max_cons_loss, double percent_risk)
{
    //FORMULA : base_lot x 2^max_cons_loss x sl_point * pips_value_per_lot = percent_risk / 2 * equity
    //we assume at highest lot, we loss 20% of our equity
    clsMoneyManagement short_mm;
    double base_lot = (percent_risk / 2 / 100 * AccountEquity()) / ((sl_point * short_mm.dblPipValuePerLot(symbol)) * MathPow(2,max_cons_loss));
    return (base_lot);
}

int clsTradeClass::intTotalBuyCount(string strSymbol, int intMagic)
{
    int size = ArraySize(this._terminal_trades);
    int count = 0;
    if(size > 0)
    {
       for(int i = 0; i < size; i++)
       {
           if(strSymbol=="" && this._terminal_trades[i]._active == true)
           {
              if(this._terminal_trades[i]._order_type == 0 ||
                 this._terminal_trades[i]._order_type == 2 ||
                 this._terminal_trades[i]._order_type == 4
                )
                {count++;}
           }
           else
           {
                if(this._terminal_trades[i]._order_symbol == strSymbol &&
                   this._terminal_trades[i]._active == true
                  )
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
           if(strSymbol=="" && this._terminal_trades[i]._active == true)
           {
              if(this._terminal_trades[i]._order_type == 1 ||
                 this._terminal_trades[i]._order_type == 3 ||
                 this._terminal_trades[i]._order_type == 5
                )
                {count++;}
           }
           else
           {
                 if(
                     this._terminal_trades[i]._active == true &&
                     strSymbol==this._terminal_trades[i]._order_symbol
                   )
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

bool clsTradeClass::blCheckTradeNumber(TRADE_COMMAND &new_order,bool special_mm_mode = false)
{
    if(special_mm_mode) return(true);
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
                 this._terminal_trades[i]._active == true &&
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

bool clsTradeClass::blCheckRequirement(TRADE_COMMAND &new_order, bool special_mm_mode = false)
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
       this.blCheckTradeNumber(new_order,special_mm_mode) == true &&  //trade number not exceed
       this.blCheckTimeAllowed(new_order) == true     //time allowed
      )
    {
        //Print(new_order._symbol," Checking Order Type ",new_order._order_type, " with price of ",new_order._entry);
        return(true);
    }
    return(false);
}

void clsTradeClass::AddTradeToList(int ticket_number, double sl, double tp, TRADE_COMMAND &trade)
{
    //Alert("Add Trade To List Recover Source is ",trade._recover_source);
    if(OrderSelect(ticket_number,SELECT_BY_TICKET,MODE_TRADES))
    {
          //Alert("Tp in is ",tp);
          int size = ArraySize(this._terminal_trades);
          ArrayResize(this._terminal_trades,ArraySize(this._terminal_trades)+1);
          this._terminal_trades[size]._active              = true;
          this._terminal_trades[size]._order_type          = OrderType();
          this._terminal_trades[size]._ticket_number       = OrderTicket();
          this._terminal_trades[size]._order_symbol        = OrderSymbol();
          this._terminal_trades[size]._order_lot           = OrderLots();
          this._terminal_trades[size]._open_price          = OrderOpenPrice();
          this._terminal_trades[size]._close_price         = OrderClosePrice();
          this._terminal_trades[size]._entry               = OrderOpenPrice();
          this._terminal_trades[size]._stop_loss           = sl;
          this._terminal_trades[size]._take_profit         = tp;
          this._terminal_trades[size]._order_profit        = OrderProfit();
          this._terminal_trades[size]._order_swap          = OrderSwap();
          this._terminal_trades[size]._order_comission     = OrderCommission();
          this._terminal_trades[size]._order_opened_time   = OrderOpenTime();
          this._terminal_trades[size]._order_closed_time   = OrderCloseTime();
          this._terminal_trades[size]._order_expiry        = OrderExpiration();
          this._terminal_trades[size]._magic_number        = OrderMagicNumber();
          this._terminal_trades[size]._order_comment       = OrderComment();
          this._terminal_trades[size]._recover_source      = trade._recover_source;
          this._terminal_trades[size]._recover_count       = trade._recover_count;
          this._terminal_trades[size]._reverse_source      = trade._reverse_source;
          this._terminal_trades[size]._reverse_count       = trade._reverse_count;
          this._terminal_trades[size]._reverse_jie_source  = trade._reverse_jie_source;
          this._terminal_trades[size]._reverse_jie_count   = trade._reverse_jie_count;
          this._terminal_trades[size]._reverse_jie_in_loss = trade._reverse_jie_in_loss;
          this._terminal_trades[size]._roulette_source     = trade._roulette_source;
          this._terminal_trades[size]._roulette_count      = trade._roulette_count;
          this._terminal_trades[size]._roulette_in_win     = trade._roulette_in_win;
          this._terminal_trades[size]._grid_tag            = trade._grid_tag;
          this._terminal_trades[size]._grid_distance       = trade._grid_distance;
          this._terminal_trades[size]._grid_count          = trade._grid_count;
          this._terminal_trades[size]._grid_base_lot       = trade._grid_base_lot;
          this._terminal_trades[size]._grid_multiplier     = trade._grid_multiplier;
          this._terminal_trades[size]._grid_sl_pip         = trade._grid_sl_pip;
          this._terminal_trades[size]._grid_tp_pip         = trade._grid_tp_pip;
          this._terminal_trades[size]._angry_martin_source = trade._angry_martin_source;
          this._terminal_trades[size]._angry_martin_count  = trade._angry_martin_count;
          this._terminal_trades[size]._angry_martin_distance = trade._angry_martin_distance;
          this._terminal_trades[size]._angry_martin_base_lot = trade._angry_martin_base_lot;
    }
    else
    {
        Alert("Failed To Save Trade To List Due to Trades In Terminal Not Found");
    }
}



bool clsTradeClass::EnterTrade(TRADE_COMMAND &new_order, bool special_mm_mode = false)
{
    if (!special_mm_mode) {this.Updater();}
    else{this.UpdateTerminal();}
    
    //SPECIAL MODE OF OPENING TRADE, WE USED CUSTOMIZED TRADE OPENING METHOD
    if(Use_MM && money_management_mode == GRID_MODE)
    {
         if(!this.GridTrade(new_order))
         {
             return(false);
         }
         
    }
    if(Use_MM && money_management_mode == ANGRY_MARTIN)
    {
      if(!this.blAngryMartinAllowed(new_order)){return(false);}
      special_mm_mode = true;
    }
    //Alert("Enter Trade Recover Source is ",new_order._recover_source);
    if(this.blCheckRequirement(new_order,special_mm_mode))
    {    
         //Alert("Requirement Passed");
         double tp_to_save = new_order._tp;
         double sl_to_save = new_order._sl;
         
         //MODIFY LOT IF INDICATED
         if(Use_MM && money_management_mode == REVERSE_JIE)   this.dblReverseJieLot(new_order);
         if(Use_MM && money_management_mode == ROULETTE_MODE) this.dblRouletteLot(new_order);
         
         
         if(this.StealthMode)
         {
             new_order._tp = 0;
             new_order._sl = 0;
         }
         //Alert("Current Tp is ",new_order._tp);
         //Alert("Current Sl is ",new_order._sl);
         int ticket = -1;
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
                     ticket = OrderSend(new_order._symbol,OP_BUYSTOP,new_order._lots,new_order._entry,this.intSlippage,new_order._sl,new_order._tp,new_order._comment,new_order._magic);
                     if(ticket < 0)
                     {
                         Print("Buy Stop Order Placed Failed with Error Code ",GetLastError());
                     }
                     else 
                     {
                        this.AddTradeToList(ticket,sl_to_save,tp_to_save,new_order);
                        return(true);
                     }
                 }
                 else
                 {
                     if(new_order._entry == MarketInfo(new_order._symbol,MODE_ASK))
                     {  
                        ticket = OrderSend(new_order._symbol,OP_BUY,new_order._lots,new_order._entry,this.intSlippage,new_order._sl,new_order._tp,new_order._comment,new_order._magic);
                        if(ticket < 0)
                        {
                             Print("Buy Market Order Placed Failed with Error Code ",GetLastError());
                        }
                        else
                        {
                           this.AddTradeToList(ticket,sl_to_save,tp_to_save,new_order);
                           return(true);
                        }
                     }
                     else
                     {
                           if(new_order._entry < MarketInfo(new_order._symbol,MODE_ASK))
                           {  
                              ticket = OrderSend(new_order._symbol,OP_BUYLIMIT,new_order._lots,new_order._entry,this.intSlippage,new_order._sl,new_order._tp,new_order._comment,new_order._magic);
                              if(ticket < 0)
                              {  
                                  Print("Buy Limit Order Placed Failed with Error Code ",GetLastError());
                              }
                              else
                              {
                                 this.AddTradeToList(ticket,sl_to_save,tp_to_save,new_order);
                                 return(true);
                              }
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
                           ticket = OrderSend(new_order._symbol,OP_SELLLIMIT,new_order._lots,new_order._entry,this.intSlippage,new_order._sl,new_order._tp,new_order._comment,new_order._magic);
                           if(ticket < 0)
                           {
                               Print("Sell Limit Order Placed Failed with Error Code ",GetLastError());
                           }
                           else
                           {
                              this.AddTradeToList(ticket,sl_to_save,tp_to_save,new_order);
                              return(true);
                           }
                       }
                       else
                       {
                           if(new_order._entry == MarketInfo(new_order._symbol,MODE_BID))
                           {
                              ticket = OrderSend(new_order._symbol,OP_SELL,new_order._lots,new_order._entry,this.intSlippage,new_order._sl,new_order._tp,new_order._comment,new_order._magic);
                              if(ticket < 0)
                              {
                                   Print("Sell Market Order Placed Failed with Error Code ",GetLastError());
                              }
                              else
                              {
                                 this.AddTradeToList(ticket,sl_to_save,tp_to_save,new_order);
                                 return(true);
                              }
                           }
                           else
                           {
                                 if(new_order._entry < MarketInfo(new_order._symbol,MODE_BID))
                                 {
                                    ticket = OrderSend(new_order._symbol,OP_SELLSTOP,new_order._lots,new_order._entry,this.intSlippage,new_order._sl,new_order._tp,new_order._comment,new_order._magic);
                                    if(ticket < 0)
                                    {
                                        Print("Sell Stop Order Placed Failed with Error Code ",GetLastError());
                                    }
                                    else
                                    {
                                       this.AddTradeToList(ticket,sl_to_save,tp_to_save,new_order);
                                       return(true);
                                    }
                                 }
                           }
                       }
                    //}
               }
         }
    }
    //Alert("Requirement Failed");
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
            this._historical_trades[size]._active            = False;
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

double clsTradeClass::dblRouletteLot(TRADE_COMMAND &trade)
{
   //function is to match and find any reverse jie trade 
   double max_lot = DBL_MIN;
   int    max_lot_ticket = 0;
   int    max_lot_roulette_source = 0;
   for(int i = 0; i < ArraySize(this._terminal_trades); i++)
   {
       if(
             this._terminal_trades[i]._roulette_source != 0 &&
             this._terminal_trades[i]._roulette_count <= mm_max_trade && 
             this._terminal_trades[i]._roulette_in_win &&
             this._terminal_trades[i]._order_symbol == trade._symbol
          )
        {
            max_lot = MathMax(max_lot,this._terminal_trades[i]._order_lot);
            max_lot_ticket = max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._ticket_number : 0;
            max_lot_roulette_source = max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._roulette_source : 0;
        }
   }
   if(max_lot_ticket != 0)
   {
      double new_lot = max_lot * reverse_multiplier;
      trade._roulette_source = max_lot_roulette_source;
      trade._lots =  new_lot;
      return(new_lot);
   }
   return (trade._lots);
}


void clsTradeClass::RouletteTrade(TRADE_LIST &trade, int update_type)
{
   int ongoing_reverse_trade = 0;
   //UPDATE TYPE : 1 LOSS TRADE, 2 : WIN TRADE
   trade._roulette_source = trade._roulette_source != 0 ? trade._roulette_source :  trade._ticket_number;
   int roulette_source = trade._roulette_source;
   Alert("Checked Trade Source ",trade._roulette_source);
   double min_tp  = DBL_MAX;
   double max_tp  = DBL_MIN;
   double min_sl  = DBL_MAX;
   double max_sl  = DBL_MIN;
   double max_lot = DBL_MIN;
   int    max_lot_ticket = 0;
   
   for(int i = 0; i < ArraySize(this._terminal_trades); i++)
   {
        if(
             this._terminal_trades[i]._roulette_source != 0 &&
             this._terminal_trades[i]._roulette_source == roulette_source && // || this._terminal_trades[i]._ticket_number == reverse_source) &&
             this._terminal_trades[i]._order_symbol == trade._order_symbol
          )
        {
             ongoing_reverse_trade = MathMax(ongoing_reverse_trade,this._terminal_trades[i]._roulette_count);
             min_tp                = MathMin(min_tp,this._terminal_trades[i]._take_profit);
             max_tp                = MathMax(max_tp,this._terminal_trades[i]._take_profit);
             min_sl                = MathMin(min_sl,this._terminal_trades[i]._stop_loss);
             max_sl                = MathMax(max_sl,this._terminal_trades[i]._stop_loss);
             max_lot               = MathMax(max_lot,this._terminal_trades[i]._order_lot);
             max_lot_ticket        = max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._ticket_number : 0;
        }
   }
   //different from others, here we just register the lot and close and deactivate the loss trade
   int new_roulette_count = ongoing_reverse_trade + 1;
   bool new_roulette_in_win  = update_type == 2 ? true : false;
   trade._roulette_count  = new_roulette_count;
   trade._roulette_in_win = new_roulette_in_win;
   
   //close the trade
   if(this.CloseByTicket(trade._ticket_number))
   {
       //UPDATE THE TERMINAL
       this.UpdateTerminal();
       //RE-AMMENDMENT
       for(int j = 0; j < ArraySize(this._terminal_trades); j++)
       {
         if(
               this._terminal_trades[j]._roulette_source == roulette_source &&
               this._terminal_trades[j]._order_symbol == trade._order_symbol
            )
          {
                this._terminal_trades[j]._roulette_count = new_roulette_count;
                this._terminal_trades[j]._roulette_in_win = new_roulette_in_win;
           }
        }
   }
}

void clsTradeClass::HedgeClose()
{
   double buy_sum_lot = 0;
   double sell_sum_lot = 0;
   double buy_sum_profit = -1;
   double sell_sum_profit = -1;
   double buy_min_lot = DBL_MAX; double sell_min_lot = DBL_MAX;
   
   for(int i = 0; i < ArraySize(this._terminal_trades); i++)
   {
        if(this._terminal_trades[i]._active == true)
        {
             if(this._terminal_trades[i]._order_type == 0)
             {
                buy_sum_lot += this._terminal_trades[i]._order_lot;
                buy_sum_profit = buy_sum_profit == -1 ? this._terminal_trades[i]._order_profit : buy_sum_profit + this._terminal_trades[i]._order_profit;
                buy_min_lot = MathMin(this._terminal_trades[i]._order_lot,buy_min_lot);
             }
             if(this._terminal_trades[i]._order_type == 1)
             {
                sell_sum_lot += this._terminal_trades[i]._order_lot;
                sell_sum_profit = sell_sum_profit == -1 ? this._terminal_trades[i]._order_profit : sell_sum_profit + this._terminal_trades[i]._order_profit;
                sell_min_lot = MathMin(this._terminal_trades[i]._order_lot,sell_min_lot);
             }
        }
   }
   double max_buy_lot  = MathPow(buy_min_lot,mm_max_trade);
   double max_sell_lot = MathPow(sell_min_lot,mm_max_trade);
   if(buy_sum_lot >= max_buy_lot * HEDGE_CRITICAL_LOT_RATIO || sell_sum_lot >= max_sell_lot *HEDGE_CRITICAL_LOT_RATIO)
   {
       if(buy_sum_profit + sell_sum_profit >= HEDGE_CLOSE_MIN_PROFIT_PERCENT * 0.01 * AccountEquity())
       {
          //close all
          for(int i = 0; i < ArraySize(this._terminal_trades); i++)
          {
              if(this._terminal_trades[i]._active == true)
              {
                  this.CloseByTicket(this._terminal_trades[i]._ticket_number);
              }
          }
       }
   }
}

bool clsTradeClass::blAngryMartinAllowed(TRADE_COMMAND &trade)
{
   //function is to match and find any angry martin trade 
   double max_lot = DBL_MIN;
   int    max_lot_ticket = 0;
   int    max_lot_angry_source = 0;
   int    max_count = 0;
   double extreme_open_price = 0;
   double extreme_take_profit = 0;
   int    buy_count  = 0;         int sell_count = 0;
   double buy_max_lot  = DBL_MIN; double sell_max_lot = DBL_MIN;
   int    buy_max_lot_ticket = 0; int    sell_max_lot_ticket = 0;
   double buy_extreme_open_price  = 0; double sell_extreme_open_price = 0;
   double buy_extreme_take_profit = 0; double sell_extreme_take_profit = 0;
   double buy_base_lot = 0; double sell_base_lot = 0;
   //check buy sell count first
   
   clsMoneyManagement mini_mm;
   
   for(int i = 0; i < ArraySize(this._terminal_trades); i++)
   {
       if(
             this._terminal_trades[i]._active == true &&
             this._terminal_trades[i]._order_symbol == trade._symbol
          )
        {
             if(this._terminal_trades[i]._order_type == 0)
             {
                  buy_max_lot = MathMax(buy_max_lot,this._terminal_trades[i]._order_lot);
                  buy_max_lot_ticket = buy_max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._ticket_number : 0;
                  buy_extreme_open_price   = buy_max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._open_price  : 0;
                  buy_extreme_take_profit  = buy_max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._take_profit : 0;
                  buy_base_lot             = buy_max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._angry_martin_base_lot : 0;
                  buy_count++;
             }
             if(this._terminal_trades[i]._order_type == 1)
             {
                  sell_max_lot = MathMax(sell_max_lot,this._terminal_trades[i]._order_lot);
                  sell_max_lot_ticket = sell_max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._ticket_number : 0;
                  sell_extreme_open_price   = sell_max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._open_price  : 0;
                  sell_extreme_take_profit  = sell_max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._take_profit : 0;
                  sell_base_lot  = sell_max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._angry_martin_base_lot : 0;
                  sell_count++;
             }
        }
   }
   trade._angry_martin_distance = ANGRY_DISTANCE;
   Alert("Buy Count is ",buy_count);
   Alert("Sell Count is ",sell_count);
   Alert("One pip is ",pips(trade._symbol));
   if(trade._order_type == 0 && buy_count == 0)// && sell_count == 0)
   {
      if(Use_Compound_Lots) 
      {
          //double predict_d1_atr = this.dblPredictedATR();
          //if(predict_d1_atr == 0) return(false);
          double new_lots = NormalizeDouble(this.dblCompoundLots(trade._symbol,60,mm_max_trade,20),2);
          //check margin
          double final_lots = MathPow(new_lots,mm_max_trade);
          double margin_required = mini_mm.dblIndMarginRequired(trade._symbol,final_lots);
          if(new_lots != 0 && margin_required < AccountEquity()*0.8 && margin_required != 0) trade._lots =  new_lots;
      }
      trade._angry_martin_base_lot = trade._lots;
      return(true);
   }
   if(trade._order_type == 1 && sell_count == 0)// && buy_count == 0)
   {
      if(Use_Compound_Lots) 
      {
          //double predict_d1_atr = this.dblPredictedATR();
          //if(predict_d1_atr == 0) return(false);
          double new_lots = NormalizeDouble(this.dblCompoundLots(trade._symbol,60,mm_max_trade,20),2);
          //check margin
          double final_lots = MathPow(new_lots,mm_max_trade);
          double margin_required = mini_mm.dblIndMarginRequired(trade._symbol,final_lots);
          if(new_lots != 0 && margin_required < AccountEquity()*0.8 && margin_required != 0) trade._lots =  new_lots;
      }
      trade._angry_martin_base_lot = trade._lots;
      return(true);
   }
   double predict_d1_atr = this.dblPredictedATR();
   if(predict_d1_atr == 0 || predict_d1_atr < ANGRY_DISTANCE * pips(trade._symbol)) return(false);
   else 
   {
       trade._angry_martin_distance = (int)(predict_d1_atr/pips(trade._symbol)/3);
   }
   if(trade._order_type == 0 && buy_count < mm_max_trade)
   {
       
       if(buy_extreme_open_price - trade._entry >= trade._angry_martin_distance * pips(trade._symbol) &&
          buy_extreme_open_price != 0
       )
       {
            double new_lot = buy_max_lot * reverse_multiplier;
            trade._lots    = new_lot;
            trade._tp      = buy_extreme_take_profit;
            trade._angry_martin_base_lot = buy_base_lot;
            //modify all old tp
            for(int i = 0; i < ArraySize(this._terminal_trades); i++)
            {
                if(
                      this._terminal_trades[i]._active == true &&
                      this._terminal_trades[i]._order_symbol == trade._symbol &&
                      this._terminal_trades[i]._order_type == 0
                   )
                 { 
                      this._terminal_trades[i]._take_profit = buy_extreme_take_profit;
                 }
            }
            return(true);
       }
   }
   if(trade._order_type == 1 && sell_count < mm_max_trade)
   {
       if(trade._entry - sell_extreme_open_price >= trade._angry_martin_distance * pips(trade._symbol) &&
          sell_extreme_open_price != 0
          )
       {
            Print("Sell Extreme Open Price is ",sell_extreme_open_price);
            Print("Sell Trade Entry is ",trade._entry);
            Print("Sell Trade martin point is ",trade._angry_martin_distance);
            Print("Sell Trade martin distance is ",trade._angry_martin_distance* pips(trade._symbol));
            double new_lot = sell_max_lot * reverse_multiplier;
            trade._lots    = new_lot;
            trade._tp      = sell_extreme_take_profit;
            trade._angry_martin_base_lot = sell_base_lot;
            //modify all old tp
            Print("Prepare Modify Sell old tp");
            for(int i = 0; i < ArraySize(this._terminal_trades); i++)
            {
                if(
                      this._terminal_trades[i]._active == true &&
                      this._terminal_trades[i]._order_symbol == trade._symbol &&
                      this._terminal_trades[i]._order_type == 1
                   )
                 { 
                      Print("Modify ",this._terminal_trades[i]._ticket_number," profit");
                      this._terminal_trades[i]._take_profit = sell_extreme_take_profit;
                 }
            }
            return(true);
       }
   }
   /*
   for(int i = 0; i < ArraySize(this._terminal_trades); i++)
   {
       if(
             this._terminal_trades[i]._active == true &&
             this._terminal_trades[i]._angry_martin_source != 0 &&
             this._terminal_trades[i]._angry_martin_count <= mm_max_trade && 
             this._terminal_trades[i]._order_symbol == trade._symbol
          )
        {
            max_lot = MathMax(max_lot,this._terminal_trades[i]._order_lot);
            max_lot_ticket = max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._ticket_number : 0;
            max_lot_angry_source = max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._angry_martin_source : 0;
            extreme_open_price   = max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._open_price  : 0;
            extreme_take_profit  = max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._take_profit : 0;
            max_count            = max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._angry_martin_count : 0;
        }
   }
   
   
   trade._angry_martin_distance = 30;
   if(max_lot_ticket != 0)
   {
      double new_lot = max_lot * reverse_multiplier;
      Alert("Extreme open price is ",extreme_open_price);
      trade._angry_martin_source = max_lot_angry_source;
      trade._lots =  new_lot;
      if(trade._order_type == 0)
      {
          if(extreme_open_price - trade._entry >= trade._angry_martin_distance * pips(trade._symbol) &&
             extreme_open_price != 0
          )
          {
               tradeable = true;
          }
      }
      if(trade._order_type == 1)
      {
          if(trade._entry - extreme_open_price >= trade._angry_martin_distance * pips(trade._symbol) &&
             extreme_open_price != 0
             )
          {
               tradeable = true;
          }
      }
   }
   else
   {  //fresh trade
      if(this.blCheckTradeNumber(trade))
      {
         trade._angry_martin_source = trade._ticket_number;
         extreme_open_price  = trade._entry;
         extreme_take_profit = trade._tp;
         tradeable = true;
      }
   }
   if(tradeable)
   {
      for(int i = 0; i < ArraySize(this._terminal_trades); i++)
      {
          if(
                this._terminal_trades[i]._active == true &&
                this._terminal_trades[i]._angry_martin_source != 0 &&
                this._terminal_trades[i]._angry_martin_source == trade._angry_martin_source &&
                this._terminal_trades[i]._order_symbol == trade._symbol
             )
          {
              //we modify sl, tp,
              this._terminal_trades[i]._stop_loss = 0;
              this._terminal_trades[i]._take_profit = extreme_take_profit;
              this._terminal_trades[i]._angry_martin_count = max_count + 1;
          }
      }
      return(true);
   }
   */
   return(false);
}


double clsTradeClass::dblReverseJieLot(TRADE_COMMAND &trade)
{
   //function is to match and find any reverse jie trade 
   double max_lot = DBL_MIN;
   int    max_lot_ticket = 0;
   int    max_lot_jie_source = 0;
   for(int i = 0; i < ArraySize(this._terminal_trades); i++)
   {
       if(
             this._terminal_trades[i]._reverse_jie_source != 0 &&
             this._terminal_trades[i]._reverse_jie_count <= mm_max_trade && 
             this._terminal_trades[i]._reverse_jie_in_loss &&
             this._terminal_trades[i]._order_symbol == trade._symbol
          )
        {
            max_lot = MathMax(max_lot,this._terminal_trades[i]._order_lot);
            max_lot_ticket = max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._ticket_number : 0;
            max_lot_jie_source = max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._reverse_jie_source : 0;
        }
   }
   if(max_lot_ticket != 0)
   {
      double new_lot = max_lot * reverse_multiplier;
      trade._reverse_jie_source = max_lot_jie_source;
      trade._lots =  new_lot;
      return(new_lot);
   }
   return (trade._lots);
}

bool clsTradeClass::blCheckGridTag(double grid_tag, double &grid_tag_exist_list[])
{
   //return true if tag exist
   bool exist = false;
   for(int i = 0; i < ArraySize(grid_tag_exist_list); i++)
   {
        if(grid_tag == grid_tag_exist_list[i])
        {
             exist = true;
             return(true);
        }
   }
   if(!exist)
   {
        ArrayCopy(grid_tag_exist_list,grid_tag_exist_list,1,0);
        grid_tag_exist_list[0] = grid_tag;
        return(false);
   }
   return(false);
}


bool clsTradeClass::GridTrade(TRADE_COMMAND &trade)
{
   //check pre-requisities criteria
   if(trade._grid_tag        == 0 ||
      trade._grid_count      == 0 ||  //count is single direction trade count, eg count 5 = buy 5, sell 5
      trade._grid_distance   == 0 ||
      trade._grid_base_lot   == 0 ||
      trade._grid_multiplier == 0 ||
      trade._symbol          == "" ||
      trade._magic           == 0
     )
   {
       Print("Wrong Grid Input Given, Kindly Check your grid settings");
       return(false);
   }  
   int    same_grid_count  = 0;
   int    grid_block_count = 0;
   double grid_tag_exist_list[];
   //Check the existing/duplicate trade
   for(int i = 0; i < ArraySize(this._terminal_trades); i++)
   {
       if(this._terminal_trades[i]._active == true)
       {
           if(this._terminal_trades[i]._grid_tag == trade._grid_tag)
           {
               same_grid_count++;
           }
           if(!this.blCheckGridTag(this._terminal_trades[i]._grid_tag,grid_tag_exist_list))
           {
               grid_block_count++;
           }
           
       }
   }
   if(same_grid_count == 0 && grid_block_count < MAX_GRID_SET_ALLOWED)
   {
          TRADE_COMMAND new_sell_trade[];
          TRADE_COMMAND new_buy_trade[];
          //OPEN 5 TRADES UP AND 5 TRADES DOWN
          for(int i = 1 ; i <= trade._grid_count; i++)
          {
               //OPEN SELL LIMIT ON UP SPACE
               int sell_size = ArraySize(new_sell_trade);
               ArrayResize(new_sell_trade,sell_size+1);
               new_sell_trade[sell_size]                  = trade; //doing this will direct inherit the trade features
               new_sell_trade[sell_size]._entry           = sell_size == 0 ? trade._grid_tag + (i * trade._grid_distance * pips(trade._symbol)) : new_sell_trade[sell_size-1]._entry + (trade._grid_distance * pips(trade._symbol));
               new_sell_trade[sell_size]._entry           = NormalizeDouble(new_sell_trade[sell_size]._entry,(int)MarketInfo(trade._symbol,MODE_DIGITS));
               new_sell_trade[sell_size]._sl              = new_sell_trade[sell_size]._entry +  trade._grid_sl_pip * pips(trade._symbol);
               new_sell_trade[sell_size]._tp              = new_sell_trade[sell_size]._entry -  trade._grid_tp_pip * pips(trade._symbol);
               new_sell_trade[sell_size]._lots            = sell_size == 0 ? trade._grid_base_lot : new_sell_trade[sell_size-1]._lots * trade._grid_multiplier;
               new_sell_trade[sell_size]._order_type      = OP_SELLLIMIT;
               
               int sell_ticket = 0;
               if(!this.StealthMode)
               {    
                   sell_ticket = OrderSend(new_sell_trade[sell_size]._symbol,new_sell_trade[sell_size]._order_type,
                                           new_sell_trade[sell_size]._lots,  new_sell_trade[sell_size]._entry,
                                           slippage,new_sell_trade[sell_size]._sl,new_sell_trade[sell_size]._tp,
                                           new_sell_trade[sell_size]._comment,new_sell_trade[sell_size]._magic
                                           );
               }
               else
               {
                   sell_ticket = OrderSend(new_sell_trade[sell_size]._symbol,new_sell_trade[sell_size]._order_type,
                                           new_sell_trade[sell_size]._lots,  new_sell_trade[sell_size]._entry,
                                           slippage,0,0,
                                           new_sell_trade[sell_size]._comment,new_sell_trade[sell_size]._magic
                                           );
               }
               if(sell_ticket < 0) 
               {
                  Alert("Failed To Create Grid Sell Trade with Error Code ",GetLastError());
                  return(false);
               }
               else
               {
                  //we add to storage
                  this.AddTradeToList(sell_ticket,new_sell_trade[sell_size]._sl,new_sell_trade[sell_size]._tp,new_sell_trade[sell_size]);
               }
               
               
               //OPEN BUY LIMIT ON DOWN SPACE
               int buy_size = ArraySize(new_buy_trade);
               ArrayResize(new_buy_trade,buy_size+1);
               new_buy_trade[buy_size]                  = trade; //doing this will direct inherit the trade features
               new_buy_trade[buy_size]._entry           = buy_size == 0 ? trade._grid_tag - (i * trade._grid_distance * pips(trade._symbol)) : new_buy_trade[buy_size-1]._entry - (trade._grid_distance * pips(trade._symbol));
               new_buy_trade[buy_size]._entry           = NormalizeDouble(new_buy_trade[buy_size]._entry,(int)MarketInfo(trade._symbol,MODE_DIGITS));
               new_buy_trade[buy_size]._sl              = new_buy_trade[buy_size]._entry -  trade._grid_sl_pip * pips(trade._symbol);
               new_buy_trade[buy_size]._tp              = new_buy_trade[buy_size]._entry +  trade._grid_tp_pip * pips(trade._symbol);
               new_buy_trade[buy_size]._lots            = buy_size == 0 ? trade._grid_base_lot : new_buy_trade[buy_size-1]._lots * trade._grid_multiplier;
               new_buy_trade[buy_size]._order_type      = OP_BUYLIMIT;
               
               int buy_ticket = 0;
               if(!this.StealthMode)
               {    
                   buy_ticket = OrderSend(new_buy_trade[buy_size]._symbol,new_buy_trade[buy_size]._order_type,
                                           new_buy_trade[buy_size]._lots,  new_buy_trade[buy_size]._entry,
                                           slippage,new_buy_trade[buy_size]._sl,new_buy_trade[buy_size]._tp,
                                           new_buy_trade[buy_size]._comment,new_buy_trade[buy_size]._magic
                                           );
               }
               else
               {
                   buy_ticket = OrderSend(new_buy_trade[buy_size]._symbol,new_buy_trade[buy_size]._order_type,
                                           new_buy_trade[buy_size]._lots,  new_buy_trade[buy_size]._entry,
                                           slippage,0,0,
                                           new_buy_trade[buy_size]._comment,new_buy_trade[buy_size]._magic
                                           );
               }
               if(buy_ticket < 0) 
               {
                  Alert("Failed To Create Grid Buy Trade with Error Code ",GetLastError());
                  return(false);
               }
               else
               {
                  //we add to storage
                  this.AddTradeToList(buy_ticket,new_buy_trade[buy_size]._sl,new_buy_trade[buy_size]._tp,new_buy_trade[buy_size]);
               }
               
          }
   }
   
   return(false);
}

void clsTradeClass::GridExit(void)
{
   if(this.blCheckTradeClose())
   {
       Alert("Hey Trade Exitted");
       //get last trade
       this.UpdateHistory();
       Alert("Hey Last Trade Ticket is ",this._historical_trades[0]._ticket_number);
       
       //GET THE GRID TAG
       double grid_tag = 0;
       for(int i = 0; i < ArraySize(this._terminal_trades); i++)
       {
             if(this._terminal_trades[i]._ticket_number == this._historical_trades[0]._ticket_number)
             {
                  grid_tag = this._terminal_trades[i]._grid_tag;
                  break;
             }
       }
       //MATCH THE LIVE TRADE TO CLOSE
       if(this._historical_trades[0]._close_price == this._historical_trades[0]._take_profit &&
          grid_tag != 0
         )
       {
              int type = this._historical_trades[0]._order_type;
              for(int i = 0; i < ArraySize(this._terminal_trades); i++)
              {
                   if(this._terminal_trades[i]._active == true &&
                      this._terminal_trades[i]._grid_tag == grid_tag &&
                      this.intOrderTypeCheck(this._terminal_trades[i]._order_type) == this.intOrderTypeCheck(type)
                     )
                   {
                        if(this.CloseByTicket(this._terminal_trades[i]._ticket_number))
                        {
                              this._terminal_trades[i]._active = false;
                        }
                   }
              }
       }
       
   }
}




void clsTradeClass::ReverseJie(TRADE_LIST &trade, int update_type)
{
   //UPDATE TYPE : 1 LOSS TRADE, 2 : WIN TRADE
   int ongoing_reverse_trade = 0;
   trade._reverse_jie_source = trade._reverse_jie_source != 0 ? trade._reverse_jie_source :  trade._ticket_number;
   int reverse_jie_source = trade._reverse_jie_source;
   Alert("Checked Trade Source ",trade._reverse_jie_source);
   double min_tp  = DBL_MAX;
   double max_tp  = DBL_MIN;
   double min_sl  = DBL_MAX;
   double max_sl  = DBL_MIN;
   double max_lot = DBL_MIN;
   int    max_lot_ticket = 0;
   
   for(int i = 0; i < ArraySize(this._terminal_trades); i++)
   {
        if(
             this._terminal_trades[i]._reverse_jie_source != 0 &&
             this._terminal_trades[i]._reverse_jie_source == reverse_jie_source && // || this._terminal_trades[i]._ticket_number == reverse_source) &&
             this._terminal_trades[i]._order_symbol == trade._order_symbol
          )
        {
             ongoing_reverse_trade = MathMax(ongoing_reverse_trade,this._terminal_trades[i]._reverse_jie_count);
             min_tp                = MathMin(min_tp,this._terminal_trades[i]._take_profit);
             max_tp                = MathMax(max_tp,this._terminal_trades[i]._take_profit);
             min_sl                = MathMin(min_sl,this._terminal_trades[i]._stop_loss);
             max_sl                = MathMax(max_sl,this._terminal_trades[i]._stop_loss);
             max_lot               = MathMax(max_lot,this._terminal_trades[i]._order_lot);
             max_lot_ticket        = max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._ticket_number : 0;
        }
   }
   //different from others, here we just register the lot and close and deactivate the loss trade
   int new_reverse_jie_count = ongoing_reverse_trade + 1;
   bool new_reverse_jie_in_loss = update_type == 1 ? true : false;
   trade._reverse_jie_count  = new_reverse_jie_count;
   trade._reverse_jie_in_loss = new_reverse_jie_in_loss;
   
   //close the trade
   if(this.CloseByTicket(trade._ticket_number))
   {
       //UPDATE THE TERMINAL
       this.UpdateTerminal();
       //RE-AMMENDMENT
       for(int j = 0; j < ArraySize(this._terminal_trades); j++)
       {
         if(
               this._terminal_trades[j]._reverse_jie_source == reverse_jie_source &&
               this._terminal_trades[j]._order_symbol == trade._order_symbol
            )
          {
                this._terminal_trades[j]._reverse_jie_count = new_reverse_jie_count;
                this._terminal_trades[j]._reverse_jie_in_loss = new_reverse_jie_in_loss;
           }
        }
   }
}

void clsTradeClass::ReverseTrade(TRADE_LIST &trade)
{
   //REVERSE TRADE PRINCIPLE :
   // - When one trade loss, we open another trade in reverse direction with double lot
   Alert("Check Recover Trade Reverse Source of ",trade._reverse_source);
   int ongoing_reverse_trade = 0;
   trade._reverse_source = trade._reverse_source != 0 ? trade._reverse_source :  trade._ticket_number;
   int reverse_source = trade._reverse_source;
   Alert("Checked Trade Source ",trade._reverse_source);
   double min_tp  = DBL_MAX;
   double max_tp  = DBL_MIN;
   double min_sl  = DBL_MAX;
   double max_sl  = DBL_MIN;
   double max_lot = DBL_MIN;
   int    max_lot_ticket = 0;
   for(int i = 0; i < ArraySize(this._terminal_trades); i++)
   {
        if(
             this._terminal_trades[i]._reverse_source != 0 &&
             this._terminal_trades[i]._reverse_source == reverse_source && // || this._terminal_trades[i]._ticket_number == reverse_source) &&
             this._terminal_trades[i]._order_symbol == trade._order_symbol
          )
        {
             ongoing_reverse_trade = MathMax(ongoing_reverse_trade,this._terminal_trades[i]._reverse_count);
             min_tp                = MathMin(min_tp,this._terminal_trades[i]._take_profit);
             max_tp                = MathMax(max_tp,this._terminal_trades[i]._take_profit);
             min_sl                = MathMin(min_sl,this._terminal_trades[i]._stop_loss);
             max_sl                = MathMax(max_sl,this._terminal_trades[i]._stop_loss);
             max_lot               = MathMax(max_lot,this._terminal_trades[i]._order_lot);
             max_lot_ticket        = max_lot == this._terminal_trades[i]._order_lot ? this._terminal_trades[i]._ticket_number : 0;
        }
   }
   double predict_d1_atr = this.dblPredictedATR();
   double atr_point      = predict_d1_atr / pips(trade._order_symbol);
   if(ongoing_reverse_trade <= mm_max_trade &&
      max_lot_ticket != 0 &&
      min_tp  != DBL_MAX && max_tp  != DBL_MIN && min_sl  != DBL_MAX && max_sl  != DBL_MIN 
     )
   {
              
             if(ongoing_reverse_trade >= 1)
             {
                 if(atr_point < reverse_min_vol_point)
                 {
                     return;
                 }
             }
             
             //Alert("Ongoing Reverse Trade is ",ongoing_reverse_trade);
             double latest_trade_type = OrderSelect(max_lot_ticket,SELECT_BY_TICKET,MODE_TRADES) ?  OrderType() : trade._order_type;
             TRADE_COMMAND new_trade;
             new_trade._action = MODE_TOPEN;  //a tag to indicate open new trade
             new_trade._symbol = trade._order_symbol;
             new_trade._lots   = max_lot * reverse_multiplier;
             new_trade._magic  = trade._magic_number;
             new_trade._reverse_source = reverse_source;
             new_trade._reverse_count  = ongoing_reverse_trade + 1;
             
             double sl_point = 0;
             if(trade._order_type == 0)
             {
                  //closed trade is buy, so new trade is sell
                  new_trade._order_type = 1;
                  new_trade._entry  = MarketInfo(trade._order_symbol,MODE_BID);
                  sl_point          = trade._entry - trade._stop_loss;
                  new_trade._sl     = trade._stop_loss + sl_point;
                  new_trade._tp     = new_trade._entry - (Reverse_RR_Ratio * sl_point);//max_tp + sl_point;
             }
             if(trade._order_type == 1)
             {
                  //closed trade is sell, so new trade is buy
                  new_trade._order_type = 0;
                  new_trade._entry  = MarketInfo(trade._order_symbol,MODE_ASK);
                  sl_point          = trade._stop_loss - trade._entry;
                  new_trade._sl     = trade._stop_loss - sl_point;
                  new_trade._tp     = new_trade._entry + (Reverse_RR_Ratio * sl_point);// min_tp - sl_point;
             }
             
             double new_sl = new_trade._sl;
             double new_tp = new_trade._tp;
             if(this.CloseByTicket(trade._ticket_number))
             {
                if(ongoing_reverse_trade < mm_max_trade)
                {
                   if(this.EnterTrade(new_trade,true))
                   {
                       this.UpdateTerminal();
                       //RE-AMMENDMENT
                       for(int j = 0; j < ArraySize(this._terminal_trades); j++)
                       {
                          if(
                               this._terminal_trades[j]._reverse_source == reverse_source &&
                               this._terminal_trades[j]._order_symbol == new_trade._symbol
                            )
                          {
                               this._terminal_trades[j]._reverse_count = new_trade._reverse_count;
                               //this._terminal_trades[j]._stop_loss = new_sl;
                               //this._terminal_trades[j]._take_profit =  new_tp;
                          }
                       }
                       
                   }
                 }
             }
   }
}

bool clsTradeClass::CloseByTicket(int ticket)
{
     if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
     {
          int type = OrderType();
          double lots = OrderLots();
          string symbol = OrderSymbol();
          switch(type)
          {
               case 0 :
                     if(!OrderClose(ticket,lots,MarketInfo(symbol,MODE_BID),slippage))
                     {
                          Alert("Failed to close BUY tcket ID of ",ticket);
                     }
                     else
                     {
                         return(true);
                     }
                     break;
                     
               case 1 :
                     if(!OrderClose(ticket,lots,MarketInfo(symbol,MODE_ASK),slippage))
                     {
                          Alert("Failed to close SELL tcket ID of ",ticket);
                     }
                     else
                     {
                          return(true);
                     }
                     break;
               default :
                     //other LIMIT/STOP order
                     if(!OrderDelete(ticket))
                     {
                         Alert("Failed To Delete Ticket ",ticket);
                     }
                     else
                     {
                          return(true);
                     }
                     break;
          }
     }
     return(true);
}


void clsTradeClass::RecoverTrade(TRADE_LIST &trade)
{
   //RECOVER TRADE PRINCIPLE
   // - When trade in loss position, we allow adding trade into same direction with double lot size
   //Alert("Check Recover Trade Recover Source of ",trade._recover_source);
   int ongoing_recover_trade = 0;
   trade._recover_source = trade._recover_source != 0 ? trade._recover_source :  trade._ticket_number;
   int recover_source = trade._recover_source;
   //Alert("Checked Trade Source ",trade._recover_source);
   double min_tp  = DBL_MAX;
   double max_tp  = DBL_MIN;
   double min_sl  = DBL_MAX;
   double max_sl  = DBL_MIN;
   double max_lot = DBL_MIN;
   for(int i = 0; i < ArraySize(this._terminal_trades); i++)
   {
        if(
             this._terminal_trades[i]._active == true &&
             this._terminal_trades[i]._recover_source == recover_source && // || this._terminal_trades[i]._ticket_number == reverse_source) &&
             this._terminal_trades[i]._order_symbol == trade._order_symbol
          )
        {
             ongoing_recover_trade = MathMax(ongoing_recover_trade,this._terminal_trades[i]._recover_count);
             min_tp                = MathMin(min_tp,this._terminal_trades[i]._take_profit);
             max_tp                = MathMax(max_tp,this._terminal_trades[i]._take_profit);
             min_sl                = MathMin(min_sl,this._terminal_trades[i]._stop_loss);
             max_sl                = MathMax(max_sl,this._terminal_trades[i]._stop_loss);
             max_lot               = MathMax(max_lot,this._terminal_trades[i]._order_lot);
        }
   }
   
   
   
   //Alert("Reverse trade source is ",source_entry);
   
   if(ongoing_recover_trade < mm_max_trade)
   {
        if(min_tp  != DBL_MAX && max_tp  != DBL_MIN && min_sl  != DBL_MAX && max_sl  != DBL_MIN)
        {
           //Alert("Ongoing Recover Trade is ",ongoing_recover_trade);
           TRADE_COMMAND new_trade;
           double source_entry = OrderSelect(recover_source,SELECT_BY_TICKET,MODE_TRADES) ?  OrderOpenPrice() : trade._open_price;
           //we open a new trade
           new_trade._action = MODE_TOPEN;  //a tag to indicate open new trade
           new_trade._order_type = trade._order_type;
           new_trade._symbol = trade._order_symbol;
           new_trade._lots   = max_lot * reverse_multiplier;
           new_trade._magic  = trade._magic_number;
           new_trade._recover_source = recover_source;
           new_trade._recover_count  = ongoing_recover_trade + 1;
           double sl_point = 0;
           if(trade._order_type == 0)
           {
               new_trade._entry  = MarketInfo(trade._order_symbol,MODE_ASK);
               sl_point       = (source_entry - trade._stop_loss)/(ongoing_recover_trade+1);
               new_trade._sl     = trade._stop_loss - sl_point;
               new_trade._tp     = new_trade._entry + (Reverse_RR_Ratio * sl_point);// min_tp - sl_point;
           }
           if(trade._order_type == 1)
           {
               new_trade._entry  = MarketInfo(trade._order_symbol,MODE_BID);
               sl_point   = (trade._stop_loss - source_entry)/(ongoing_recover_trade+1);
               new_trade._sl     = trade._stop_loss + sl_point;
               new_trade._tp     = new_trade._entry - (Reverse_RR_Ratio * sl_point);//max_tp + sl_point;
           }
                   
           double new_sl = new_trade._sl;
           double new_tp = new_trade._tp;
           if(this.EnterTrade(new_trade,true))
           {
               this.UpdateTerminal();
               //RE-AMMENDMENT
               for(int j = 0; j < ArraySize(this._terminal_trades); j++)
               {
                 if(
                      this._terminal_trades[j]._active == true &&
                      this._terminal_trades[j]._recover_source == recover_source &&
                      this._terminal_trades[j]._order_symbol == new_trade._symbol
                   )
                 {
                      this._terminal_trades[j]._recover_count = new_trade._recover_count;
                      this._terminal_trades[j]._stop_loss = new_sl;
                      this._terminal_trades[j]._take_profit =  new_tp;
                 }
               }
           }
           
           //Alert("Create Trade Outcome is ",outcome);
           
           
           //ONLY WE RE-ENTER TRADE
       } 
       
   }
   
   else
   {
       if(mm_forced_close)
       {
          //we close all the trades
          for(int i = 0; i < ArraySize(this._terminal_trades); i++)
          {
             if(
                this._terminal_trades[i]._active == true &&
                this._terminal_trades[i]._recover_source == recover_source && // || this._terminal_trades[i]._ticket_number == reverse_source) &&
                this._terminal_trades[i]._order_symbol == trade._order_symbol
             )
             {
                   if(this.CloseByTicket(this._terminal_trades[i]._ticket_number))
                   {
                         this._terminal_trades[i]._active = false;
                   }
             }
          }
       }
   }
   
}


void clsTradeClass::MonitorSlTp()
{
    TRADE_LIST trade_to_reverse_list[];

    if(this.StealthMode == true)
    {
         //LOOP AGAIN TO CHECK THE ORDER STOP LOSS IF IN STEALTH MODE
         for(int i = 0; i < ArraySize(this._terminal_trades); i++)
         {
              if(this._terminal_trades[i]._active == true)
              {
                    if(Use_MM)
                    {
                        if(money_management_mode == 0)
                        {
                            //Print("Current Ticket is ",this._terminal_trades[i]._ticket_number," with stop loss of ",this._terminal_trades[i]._stop_loss," tp of ",this._terminal_trades[i]._take_profit);
                            //Print("Current Ticket is ",this._terminal_trades[i]._ticket_number," with recover count of ",this._terminal_trades[i]._recover_count," recover source of ",this._terminal_trades[i]._recover_source);
                        }
                        if(money_management_mode == 1)
                        {
                            //Print("Current Ticket is ",this._terminal_trades[i]._ticket_number," with stop loss of ",this._terminal_trades[i]._stop_loss," tp of ",this._terminal_trades[i]._take_profit);
                            //Print("Current Ticket is ",this._terminal_trades[i]._ticket_number," with reverse count of ",this._terminal_trades[i]._reverse_count," reverse source of ",this._terminal_trades[i]._reverse_source);
                        }
                    }
                    //Check Active Trade Stop Loss TP
                    if(this._terminal_trades[i]._order_type == 0) //buy trade
                    {
                         if( this._terminal_trades[i]._take_profit != 0 &&
                             MarketInfo(this._terminal_trades[i]._order_symbol,MODE_BID) >= this._terminal_trades[i]._take_profit
                           )
                         {
                               if(Use_MM && 
                                  (money_management_mode==REVERSE_JIE || money_management_mode==ROULETTE_MODE)
                                 )
                               {   
                                  if(money_management_mode==REVERSE_JIE)   this.ReverseJie(this._terminal_trades[i],2);
                                  if(money_management_mode==ROULETTE_MODE) this.RouletteTrade(this._terminal_trades[i],2);
                               }
                               else
                               {
                                  if(!OrderClose(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._order_lot,
                                                MarketInfo(this._terminal_trades[i]._order_symbol,MODE_BID),this.intSlippage))
                                  {
                                      Alert("Failed to Close BUY Trade of Ticket ID ",this._terminal_trades[i]._ticket_number);
                                  }
                               }
                         
                         }
                         if(
                              this._terminal_trades[i]._stop_loss != 0 &&
                              MarketInfo(this._terminal_trades[i]._order_symbol,MODE_BID) <= this._terminal_trades[i]._stop_loss
                           )
                         {
                               //Alert("Stealth Mode Close Ticket with SL Price of ",this._terminal_trades[i]._stop_loss);
                               if(Use_MM)
                               {
                                   if(money_management_mode==0)this.RecoverTrade(this._terminal_trades[i]);
                                   if(money_management_mode==1)this.ReverseTrade(this._terminal_trades[i]);
                                   if(money_management_mode==2)this.ReverseJie(this._terminal_trades[i],1);
                                   if(money_management_mode==3)this.RouletteTrade(this._terminal_trades[i],1);
                               }
                               else
                               {
                                  if(!OrderClose(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._order_lot,
                                             MarketInfo(this._terminal_trades[i]._order_symbol,MODE_BID),this.intSlippage))
                                    {
                                         Alert("Failed to Close BUY Trade of Ticket ID ",this._terminal_trades[i]._ticket_number);
                                    }
                               }
                         }
                    }
                    if(this._terminal_trades[i]._order_type == 1) //sell trade
                    {
                         if(  
                              this._terminal_trades[i]._take_profit != 0 &&
                              MarketInfo(this._terminal_trades[i]._order_symbol,MODE_ASK) <= this._terminal_trades[i]._take_profit
                           )
                         {
                               if(Use_MM && 
                                  (money_management_mode==REVERSE_JIE || money_management_mode==ROULETTE_MODE)
                                 )
                               {   
                                  if(money_management_mode==REVERSE_JIE)   this.ReverseJie(this._terminal_trades[i],2);
                                  if(money_management_mode==ROULETTE_MODE) this.RouletteTrade(this._terminal_trades[i],2);
                               }
                               else
                               {
                                  if(!OrderClose(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._order_lot,
                                             MarketInfo(this._terminal_trades[i]._order_symbol,MODE_ASK),this.intSlippage))
                                    {
                                         Alert("Failed to Close SELL Trade of Ticket ID ",this._terminal_trades[i]._ticket_number);
                                    }
                               }
                         }
                         if(
                              this._terminal_trades[i]._stop_loss != 0 &&
                              MarketInfo(this._terminal_trades[i]._order_symbol,MODE_ASK) >= this._terminal_trades[i]._stop_loss
                           )
                         {
                               if(Use_MM)
                               {
                                   if(money_management_mode==0)this.RecoverTrade(this._terminal_trades[i]);
                                   if(money_management_mode==1)this.ReverseTrade(this._terminal_trades[i]);
                                   if(money_management_mode==2)this.ReverseJie(this._terminal_trades[i],1);
                                   if(money_management_mode==3)this.RouletteTrade(this._terminal_trades[i],1);
                               }
                               else
                               {
                                  if(!OrderClose(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._order_lot,
                                             MarketInfo(this._terminal_trades[i]._order_symbol,MODE_ASK),this.intSlippage))
                                    {
                                         Alert("Failed to Close SELL Trade of Ticket ID ",this._terminal_trades[i]._ticket_number);
                                    }
                               }
                         }
                    }
              }
         }
    }
    
    if(ArraySize(trade_to_reverse_list) > 0)
    {
         for(int i = 0; i < ArraySize(trade_to_reverse_list); i++)
         {
               Alert("Preparing to reverse trade ",trade_to_reverse_list[i]._ticket_number);
               ReverseTrade(trade_to_reverse_list[i]);
         }
    }
    
}


void clsTradeClass::UpdateTerminal()
{
      //LOOP STORED TRADE WITH TERMINAL TRADE
      for(int i = 0; i < ArraySize(this._terminal_trades); i++)
      {
         if(this._terminal_trades[i]._active == true)
         {
           if(OrderSelect(this._terminal_trades[i]._ticket_number,SELECT_BY_TICKET,MODE_TRADES))
           {
              if(OrderCloseTime()==0)
              {
                 //trade still active, we update its status
                 this._terminal_trades[i]._active = true;
                 this._terminal_trades[i]._order_type        = OrderType();
                 this._terminal_trades[i]._ticket_number     = OrderTicket();
                 this._terminal_trades[i]._order_symbol      = OrderSymbol();
                 this._terminal_trades[i]._order_lot         = OrderLots();
                 this._terminal_trades[i]._open_price        = OrderOpenPrice();
                 this._terminal_trades[i]._close_price       = OrderClosePrice();
                 this._terminal_trades[i]._entry             = OrderOpenPrice();
                 this._terminal_trades[i]._order_swap        = OrderSwap();
                 this._terminal_trades[i]._order_comission   = OrderCommission();
                 this._terminal_trades[i]._order_opened_time = OrderOpenTime();
                 this._terminal_trades[i]._order_closed_time = OrderCloseTime();
                 this._terminal_trades[i]._order_expiry      = OrderExpiration();
                 this._terminal_trades[i]._magic_number      = OrderMagicNumber();
                 this._terminal_trades[i]._order_comment     = OrderComment();
                 this._terminal_trades[i]._order_profit      = OrderProfit();
                 
                 if(this.StealthMode == false)
                 {
                     this._terminal_trades[i]._stop_loss         = OrderStopLoss();
                     this._terminal_trades[i]._take_profit       = OrderTakeProfit();
                     
                 }
              }
              else
              {
                    //Trade being closed externally, so automatically deactivate them
                    Alert("Deactviating Trade ",this._terminal_trades[i]._ticket_number);
                    this._terminal_trades[i]._active = false;
              }
              
           }
         }  
      }
      
      //CHECK ADDITIONAL TRADE OPENED BY EXTERNAL
      for(int i = 0; i < OrdersTotal(); i++)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         {
               bool trade_found = false;
               for(int j = 0; j < ArraySize(this._terminal_trades); j++)
               {
                   if(this._terminal_trades[j]._ticket_number == OrderTicket())
                   {
                        trade_found = true;
                   }
               }
               if(!trade_found)
               {
                   //we registered into our stored trade list
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
      
     
      
}

bool clsTradeClass::blCheckTradeClose()
{
   static int total_hist_trade = 0;
   if(OrdersHistoryTotal() != total_hist_trade)
   {
       if(total_hist_trade != 0)
       {
           total_hist_trade = OrdersHistoryTotal();
           return(true);
       }
       else
       {
           total_hist_trade = OrdersHistoryTotal();
       }
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
       if(
            this._terminal_trades[i]._active == true &&
            this.blSymbolCheck(this._terminal_trades[i]._order_symbol,trade._symbol)
         )
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
                                this._terminal_trades[i]._stop_loss = this._terminal_trades[i]._open_price;
                                if(!this.StealthMode)
                                {
                                   if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._stop_loss,this._terminal_trades[i]._take_profit,
                                               this._terminal_trades[i]._order_expiry))
                                   {
                                         Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                   }
                                }
                            }
                         break;
                      
                      case 2 :  // by factor
                         if(latest_price - this._terminal_trades[i]._open_price > trade._breakeven_input * (this._terminal_trades[i]._open_price - this._terminal_trades[i]._stop_loss) &&
                            this._terminal_trades[i]._stop_loss < this._terminal_trades[i]._entry
                           )
                         {
                                this._terminal_trades[i]._stop_loss = this._terminal_trades[i]._open_price;
                                if(!this.StealthMode)
                                {
                                   if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._stop_loss,this._terminal_trades[i]._take_profit,
                                               this._terminal_trades[i]._order_expiry))
                                   {
                                         Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                   }
                                }
                         }
                         break; 
                      
                      case 3 : //BY TP 3
                         if(latest_price >= StringToDouble(this._terminal_trades[i]._order_comment) &&
                            this._terminal_trades[i]._stop_loss < this._terminal_trades[i]._entry
                           )
                         {
                                this._terminal_trades[i]._stop_loss = this._terminal_trades[i]._open_price;
                                if(!this.StealthMode)
                                {
                                   if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._stop_loss,this._terminal_trades[i]._take_profit,
                                               this._terminal_trades[i]._order_expiry))
                                   {
                                         Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                   }
                                }
                         }
                         break; 
                         
                      case 4 : //BY PERCENTAGE
                      //here must be a break even option(true/false) in %, if set to 30% then the EA will adjust the SL to break even when price is 30% up from the open price and 70% away frm the TP
                         if(latest_price - this._terminal_trades[i]._open_price > trade._breakeven_input * 0.01 * (this._terminal_trades[i]._take_profit - this._terminal_trades[i]._open_price) &&
                            this._terminal_trades[i]._stop_loss < this._terminal_trades[i]._entry
                           )
                         {
                                this._terminal_trades[i]._stop_loss = this._terminal_trades[i]._open_price;
                                if(!this.StealthMode)
                                {
                                   if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._stop_loss,this._terminal_trades[i]._take_profit,
                                               this._terminal_trades[i]._order_expiry))
                                   {
                                         Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                   }
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
                                this._terminal_trades[i]._stop_loss = this._terminal_trades[i]._open_price;
                                if(!this.StealthMode)
                                {
                                   if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._stop_loss,this._terminal_trades[i]._take_profit,
                                               this._terminal_trades[i]._order_expiry))
                                   {
                                         Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                   }
                                }
                         }
                         break;
                      
                      case 2 :  // by factor
                         if(this._terminal_trades[i]._open_price - latest_price > trade._breakeven_input * (this._terminal_trades[i]._stop_loss - this._terminal_trades[i]._open_price ) &&
                            this._terminal_trades[i]._stop_loss > this._terminal_trades[i]._entry
                           )
                         {
                                this._terminal_trades[i]._stop_loss = this._terminal_trades[i]._open_price;
                                if(!this.StealthMode)
                                {
                                   if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._stop_loss,this._terminal_trades[i]._take_profit,
                                               this._terminal_trades[i]._order_expiry))
                                   {
                                         Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                   }
                                }
                         }
                         break; 
                      
                      case 3:  // by TP1
                         if(latest_price <= StringToDouble(this._terminal_trades[i]._order_comment) &&
                            this._terminal_trades[i]._stop_loss > this._terminal_trades[i]._entry
                           )
                         {
                                this._terminal_trades[i]._stop_loss = this._terminal_trades[i]._open_price;
                                if(!this.StealthMode)
                                {
                                   if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._stop_loss,this._terminal_trades[i]._take_profit,
                                               this._terminal_trades[i]._order_expiry))
                                   {
                                         Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                   }
                                }
                         }
                         break; 
                         
                     case 4 :  // by percentage here must be a break even option(true/false) in %, if set to 30% then the EA will adjust the SL to break even when price is 30% up from the open price and 70% away frm the TP
                         if(this._terminal_trades[i]._open_price - latest_price > trade._breakeven_input * 0.01 * (this._terminal_trades[i]._open_price - this._terminal_trades[i]._take_profit ) &&
                            this._terminal_trades[i]._stop_loss > this._terminal_trades[i]._entry
                           )
                         {
                                this._terminal_trades[i]._stop_loss = this._terminal_trades[i]._open_price;
                                if(!this.StealthMode)
                                {
                                   if(!OrderModify(this._terminal_trades[i]._ticket_number,this._terminal_trades[i]._open_price,this._terminal_trades[i]._stop_loss,this._terminal_trades[i]._take_profit,
                                               this._terminal_trades[i]._order_expiry))
                                   {
                                         Print("Failed to Modify Breakeven Trade for ",this._terminal_trades[i]._ticket_number);
                                   }
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
          if(
               this._terminal_trades[i]._active == true &&
               this.blSymbolCheck(this._terminal_trades[i]._order_symbol,strInputSymbol)
            )
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
                             this._terminal_trades[i]._active = false;
                             break;
                         
                         case 1:
                             if(!OrderClose(
                                          this._terminal_trades[i]._ticket_number,
                                          this._terminal_trades[i]._order_lot,
                                          MarketInfo(this._terminal_trades[i]._order_symbol,MODE_ASK),
                                          slippage
                                        ))
                                {Print("Failed to Close Sell Trade With Error Code ",GetLastError());}
                             this._terminal_trades[i]._active = false;
                             break;
                    }
               }
          }
      }
}

bool clsTradeClass::MMCheck(TRADE_LIST &trade_list,TRADE_COMMAND &trade_command, MM_MODE mm_mode)
{
     //the principle is easy, we simply chck the by usingthe MM_MODE
     if(mm_mode == 0)
     {
         //we are dealing with recover trade
         if(trade_list._recover_source == trade_command._recover_source)
         {
             return(true); 
         }
     }
     if(mm_mode == 1)
     {
         //we are dealing with reverse trade
         if(trade_list._reverse_source == trade_command._reverse_source)
         {
             return(true); 
         }
     }
     return(false);
}


bool clsTradeClass::CloseTrade(TRADE_COMMAND &trade, bool special_mm=false)   //by magic number
{
     //Critical Error Check
     if(trade._action != MODE_TCLSE ||
        trade._symbol == ""         ||
        trade._order_type == -1     ||
        trade._magic  == 0
       )
     {
         Print("Trade Close Input Error, Kindly Check");
         return (false);
     }
     for(int i = 0; i < ArraySize(this._terminal_trades); i++)
     {
         
         if(this._terminal_trades[i]._active == true &&
            this._terminal_trades[i]._order_symbol == trade._symbol &&
            this._terminal_trades[i]._magic_number == trade._magic
            )
         {
              if(this.intOrderTypeCheck(trade._order_type) ==
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
                           else
                           {
                                this._terminal_trades[i]._active =false;
                                return(true);
                           }      
                           break;
                       case 1: //SELL ORDER
                           if(!OrderClose(this._terminal_trades[i]._ticket_number,
                                      this._terminal_trades[i]._order_lot,
                                      MarketInfo(this._terminal_trades[i]._order_symbol,MODE_ASK),
                                      slippage))
                                      {Print(" Close Sell Ticket ",this._terminal_trades[i]._ticket_number,
                                             " with error code of ",GetLastError());}   
                           else
                           {
                                this._terminal_trades[i]._active =false;
                                return(true);
                           } 
                           break;
                       case 2: //BUY LIMIT ORDER
                           if(!OrderDelete(this._terminal_trades[i]._ticket_number))
                           {
                                Print("Failed Delete Buy Pending Order with Error Code ",GetLastError());
                           }
                           else
                           {
                                this._terminal_trades[i]._active =false;
                                return(true);
                           } 
                           break;
                       case 3: //SELL LIMIT ORDER
                           if(!OrderDelete(this._terminal_trades[i]._ticket_number))
                           {
                                Print("Failed Delete Sell Pending Order with Error Code ",GetLastError());
                           }
                           else
                           {
                                this._terminal_trades[i]._active =false;
                                return(true);
                           } 
                           break;
                       case 4: //BUY STOP ORDER
                           if(!OrderDelete(this._terminal_trades[i]._ticket_number))
                           {
                                Print("Failed Delete Buy Stop Order with Error Code ",GetLastError());
                           }
                           else
                           {
                                this._terminal_trades[i]._active =false;
                                return(true);
                           } 
                           break;
                       case 5:
                           if(!OrderDelete(this._terminal_trades[i]._ticket_number))
                           {
                                Print("Failed Delete Sell Stop Order with Error Code ",GetLastError());
                           }
                           else
                           {
                                this._terminal_trades[i]._active =false;
                                return(true);
                           } 
                           break;
                           
                  }
              }
         }
     }
     return(false);
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
         if(
              this._terminal_trades[i]._active == true &&
              this._terminal_trades[i]._order_symbol == trade._symbol //&&
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
                                   {  
                                        this._terminal_trades[i]._stop_loss = new_sl;
                                        if(!this.StealthMode)
                                        {
                                           if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                                       this._terminal_trades[i]._open_price,
                                                       this._terminal_trades[i]._stop_loss,
                                                       this._terminal_trades[i]._take_profit,
                                                       this._terminal_trades[i]._order_expiry
                                                       ))
                                           {
                                                Print("Modify Trailing Buy Ticket ",this._terminal_trades[i]._ticket_number,
                                                      " with error code of ",GetLastError());
                                           }
                                        }
                                   }
                                    
                                 break;
                              case 2://user predefined sl
                                 new_sl = trade._trailing_input;
                                 if(new_sl > this._terminal_trades[i]._stop_loss ||
                                    this._terminal_trades[i]._stop_loss == 0
                                   )
                                   {
                                        this._terminal_trades[i]._stop_loss = new_sl;
                                        if(!this.StealthMode)
                                        {
                                           if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                                       this._terminal_trades[i]._open_price,
                                                       this._terminal_trades[i]._stop_loss,
                                                       this._terminal_trades[i]._take_profit,
                                                       this._terminal_trades[i]._order_expiry
                                                       ))
                                           {
                                                Print("Modify Trailing Buy Ticket ",this._terminal_trades[i]._ticket_number,
                                                      " with error code of ",GetLastError());
                                           }
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
                                        this._terminal_trades[i]._stop_loss = new_sl;
                                        if(!this.StealthMode)
                                        {
                                           if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                                       this._terminal_trades[i]._open_price,
                                                       this._terminal_trades[i]._stop_loss,
                                                       this._terminal_trades[i]._take_profit,
                                                       this._terminal_trades[i]._order_expiry
                                                       ))
                                           {
                                                Print("Modify Trailing Buy Ticket ",this._terminal_trades[i]._ticket_number,
                                                      " with error code of ",GetLastError());
                                           }
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
                                        this._terminal_trades[i]._stop_loss = new_sl;
                                        if(!this.StealthMode)
                                        {
                                           if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                                       this._terminal_trades[i]._open_price,
                                                       this._terminal_trades[i]._stop_loss,
                                                       this._terminal_trades[i]._take_profit,
                                                       this._terminal_trades[i]._order_expiry
                                                       ))
                                           {
                                                Print("Modify Trailing Sell Ticket ",this._terminal_trades[i]._ticket_number,
                                                      " with error code of ",GetLastError());
                                           }
                                        }
                                   }
                                    
                                 break;
                              case 2://user predefined sl
                                 new_sl = trade._trailing_input;
                                 if(new_sl < this._terminal_trades[i]._stop_loss ||
                                    this._terminal_trades[i]._stop_loss == 0
                                   )
                                   {
                                        this._terminal_trades[i]._stop_loss = new_sl;
                                        if(!this.StealthMode)
                                        {
                                           if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                                       this._terminal_trades[i]._open_price,
                                                       this._terminal_trades[i]._stop_loss,
                                                       this._terminal_trades[i]._take_profit,
                                                       this._terminal_trades[i]._order_expiry
                                                       ))
                                           {
                                                Print("Modify Trailing Sell Ticket ",this._terminal_trades[i]._ticket_number,
                                                      " with error code of ",GetLastError());
                                           }
                                        }
                                   }
                                 break;
                                 
                              case 3://user predefined percentage trailing
                                 new_sl = NormalizeDouble(MarketInfo(this._terminal_trades[i]._order_symbol,MODE_ASK)  * MathAbs(trade._trailing_input * 0.01 + 1),(int)MarketInfo(this._terminal_trades[i]._order_symbol,MODE_DIGITS));
                                 
                                 if(new_sl < this._terminal_trades[i]._stop_loss ||
                                    this._terminal_trades[i]._stop_loss == 0
                                   )
                                   {
                                        //Print("Sell new Sl is ",new_sl);
                                        this._terminal_trades[i]._stop_loss = new_sl;
                                        if(!this.StealthMode)
                                        {
                                           if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                                       this._terminal_trades[i]._open_price,
                                                       this._terminal_trades[i]._stop_loss,
                                                       this._terminal_trades[i]._take_profit,
                                                       this._terminal_trades[i]._order_expiry
                                                       ))
                                           {
                                                Print("Modify Trailing Sell Ticket ",this._terminal_trades[i]._ticket_number,
                                                      " with error code of ",GetLastError());
                                           }
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
          if(
               this._terminal_trades[i]._active == true &&
               this._terminal_trades[i]._magic_number == trade._magic
            )
          {
                if(trade._sl != 0 && trade._sl != this._terminal_trades[i]._stop_loss)
                {
                      this._terminal_trades[i]._stop_loss = trade._sl;
                      if(!this.StealthMode)
                      {
                         if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                     this._terminal_trades[i]._open_price,
                                     this._terminal_trades[i]._stop_loss,
                                     this._terminal_trades[i]._take_profit,
                                     this._terminal_trades[i]._order_expiry
                                    ))
                         {
                              Print(" Failed to modify Sl for Ticket ",this._terminal_trades[i]._ticket_number);
                         }
                     }
                }
                
                if(trade._tp != 0 && trade._tp != this._terminal_trades[i]._take_profit)
                {
                      this._terminal_trades[i]._take_profit = trade._tp;
                      if(!this.StealthMode)
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
     
}

int  clsTradeClass::intTotalTradeByMagic(int intMagic)
{
     int count = 0;
     for(int i = 0; i < ArraySize(this._terminal_trades); i++)
     {
       if(
            this._terminal_trades[i]._active == true &&
            this._terminal_trades[i]._magic_number == intMagic
         )
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
       if(
           this._terminal_trades[i]._active == true &&
           this._terminal_trades[i]._magic_number == trade._magic
          )
       {   
           if(no_of_trade == ArraySize(tp_list))
           {
            if((double)tp_list[j] != 0 && (double)tp_list[j] != this._terminal_trades[i]._take_profit)
            {
                  this._terminal_trades[i]._take_profit = (double)tp_list[j];
                  if(!this.StealthMode)
                  {
                     if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                  this._terminal_trades[i]._open_price,
                                  this._terminal_trades[i]._stop_loss,
                                  this._terminal_trades[i]._take_profit,
                                  this._terminal_trades[i]._order_expiry
                                 ))
                      {
                           Print(" Failed to modify Multiple TP for Ticket ",this._terminal_trades[i]._ticket_number);
                      }
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
                        this._terminal_trades[i]._take_profit = (double)tp_list[j];
                        if(!this.StealthMode)
                        {
                           if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                  this._terminal_trades[i]._open_price,
                                  this._terminal_trades[i]._stop_loss,
                                  this._terminal_trades[i]._take_profit,
                                  this._terminal_trades[i]._order_expiry
                                 ))
                            {
                                 Print(" Failed to modify Multiple TP for Ticket ",this._terminal_trades[i]._ticket_number);
                            }
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
                           this._terminal_trades[i]._take_profit = (double)tp;
                           if(!this.StealthMode)
                           {
                              if(!OrderModify(this._terminal_trades[i]._ticket_number,
                                     this._terminal_trades[i]._open_price,
                                     this._terminal_trades[i]._stop_loss,
                                     this._terminal_trades[i]._take_profit,
                                     this._terminal_trades[i]._order_expiry
                                    ))
                               {
                                    Print(" Failed to modify Multiple TP for Ticket ",this._terminal_trades[i]._ticket_number);
                               }
                           }
                      }
                  }
               }
           }
           
           //j = j >= ArraySize(tp_list) ? j : j++;
       }
     }
}